import '../models/import_result.dart';
import '../models/transaction.dart';
import 'merchant_mapper.dart';
import 'parse_utils.dart';

/// Parser voor de tekst van een Argenta kredietkaart-afschrift (pdf).
///
/// Werkt op geëxtraheerde tekst (pdf.js in de browser, of `pdftotext -layout`):
/// - "Transacties van dd/mm/jjjj tot dd/mm/jjjj" levert het jaar;
/// - transactieregels: `dd/mm  dd/mm  OMSCHRIJVING  [bedrag-MUNT]  bedrag-|+`;
/// - "1 EUR=1,0997067 USD" hoort bij de vorige (vreemde munt) regel;
/// - "KOSTEN OP GELDOPNEMING" zonder datum hoort bij de vorige geldopname;
/// - "Vorig saldo", "DOMICILIERING", "Nieuw Saldo" en herhaalde headers
///   worden overgeslagen (saldi dienen enkel als controle).
class ArgentaPdfParser {
  const ArgentaPdfParser({this.mapper = const MerchantMapper()});

  final MerchantMapper mapper;

  static const sourceLabel = 'Argenta kredietkaart';

  static final _period = RegExp(
      r'Transacties van (\d{2}/\d{2}/\d{4}) tot (\d{2}/\d{2}/\d{4})',
      caseSensitive: false);
  static final _tx = RegExp(
      r'^(\d{2})/(\d{2})\s+(\d{2})/(\d{2})\s+(.+?)\s+(?:(\d[\d.]*,\d{2})([-+])\s*([A-Z]{3})\s+)?(\d[\d.]*,\d{2})([-+])$');
  static final _undatedFee =
      RegExp(r'^(KOSTEN\b.*?)\s+(\d[\d.]*,\d{2})([-+])$', caseSensitive: false);
  static final _fx =
      RegExp(r'^1\s*EUR\s*=\s*(\d[\d.,]*)\s*([A-Z]{3})$', caseSensitive: false);
  static final _prev = RegExp(r'^Vorig saldo.*?\s(\d[\d.]*,\d{2})([-+])$',
      caseSensitive: false);
  static final _new =
      RegExp(r'^Nieuw Saldo\s+(\d[\d.]*,\d{2})([-+])$', caseSensitive: false);

  /// Ziet de tekst eruit als een Argenta kredietkaart-afschrift?
  static bool looksLikeArgenta(String text) =>
      text.contains('ARGENTA') && _period.hasMatch(text);

  ImportResult parse(String text) {
    final periodMatch = _period.firstMatch(text);
    if (periodMatch == null) {
      throw ImportFormatException(
          'Dit lijkt geen Argenta kredietkaart-afschrift (geen "Transacties van ... tot ..." gevonden).');
    }
    final from = parseFlexibleDate(periodMatch.group(1)!)!;
    final to = parseFlexibleDate(periodMatch.group(2)!)!;

    DateTime resolve(int d, int m) {
      var date = DateTime(to.year, m, d);
      if (date.isAfter(to.add(const Duration(days: 40)))) {
        date = DateTime(to.year - 1, m, d);
      }
      return date;
    }

    double signed(String amount, String sign) {
      final v = parseEuroAmount(amount)!;
      return sign == '-' ? v : -v; // '-' = schuld erbij, '+' = eraf
    }

    final expenses = <Transaction>[];
    var credits = 0;
    var invalid = 0;
    double? previous;
    double? statementNew;
    var running = 0.0;
    _Pending? last;

    void flush() {
      if (last == null) return;
      expenses.add(last!.build(expenses.length, mapper));
      last = null;
    }

    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final prev = _prev.firstMatch(line);
      if (prev != null) {
        previous = signed(prev.group(1)!, prev.group(2)!);
        continue;
      }
      final nw = _new.firstMatch(line);
      if (nw != null) {
        statementNew = signed(nw.group(1)!, nw.group(2)!);
        continue;
      }
      final fx = _fx.firstMatch(line);
      if (fx != null) {
        last?.fxRate = parseEuroAmount(fx.group(1)!);
        continue;
      }
      final tx = _tx.firstMatch(line);
      if (tx != null) {
        flush();
        final desc = tx.group(5)!.trim();
        final value = signed(tx.group(9)!, tx.group(10)!);
        running += value;
        if (RegExp(r'DOMICILIERING', caseSensitive: false).hasMatch(desc)) {
          continue; // betaling van het vorige saldo
        }
        if (value < 0) {
          credits++; // terugbetaling/creditering
          continue;
        }
        final date = resolve(int.parse(tx.group(1)!), int.parse(tx.group(2)!));
        last = _Pending(
          date: date,
          settlement:
              resolve(int.parse(tx.group(3)!), int.parse(tx.group(4)!)),
          descriptor: desc,
          amount: value,
          foreignAmount:
              tx.group(6) == null ? null : parseEuroAmount(tx.group(6)!),
          foreignCurrency: tx.group(8),
        );
        continue;
      }
      final fee = _undatedFee.firstMatch(line);
      if (fee != null) {
        final value = signed(fee.group(2)!, fee.group(3)!);
        running += value;
        // Kosten zonder datum horen bij de vorige transactie (geldopname).
        final date = last?.date ??
            (expenses.isNotEmpty ? expenses.last.date : from);
        final settle = last?.settlement ??
            (expenses.isNotEmpty ? expenses.last.settlementDate : null);
        flush();
        if (value < 0) {
          credits++;
          continue;
        }
        expenses.add(_Pending(
          date: date,
          settlement: settle,
          descriptor: fee.group(1)!.trim(),
          amount: value,
        ).build(expenses.length, mapper));
        continue;
      }
      if (RegExp(r'^\d{2}/\d{2}\s+\d{2}/\d{2}\s').hasMatch(line)) {
        invalid++; // datumregel die we niet konden lezen
      }
    }
    flush();

    if (expenses.isEmpty) {
      throw ImportFormatException('Geen uitgaven gevonden in dit afschrift.');
    }
    stableSortByDate(expenses);
    return ImportResult(
      expenses: expenses,
      skippedIncome: credits,
      skippedInvalid: invalid,
      sourceLabel: sourceLabel,
      check: StatementCheck(
        periodFrom: from,
        periodTo: to,
        statementNewBalance: statementNew,
        previousBalance: previous ?? 0,
        computedNewBalance:
            double.parse(((previous ?? 0) + running).toStringAsFixed(2)),
      ),
    );
  }
}

class _Pending {
  _Pending({
    required this.date,
    required this.settlement,
    required this.descriptor,
    required this.amount,
    this.foreignAmount,
    this.foreignCurrency,
  });

  final DateTime date;
  final DateTime? settlement;
  final String descriptor;
  final double amount;
  final double? foreignAmount;
  final String? foreignCurrency;
  double? fxRate;

  Transaction build(int index, MerchantMapper mapper) {
    final info = mapper.map(descriptor: descriptor);
    return Transaction(
      id: 'ar$index',
      date: date,
      settlementDate: settlement,
      merchant: info.name,
      rawDescriptor: descriptor,
      amount: amount,
      category: info.category,
      foreignAmount: foreignAmount,
      foreignCurrency: foreignCurrency,
      fxRate: fxRate,
      source: ArgentaPdfParser.sourceLabel,
    );
  }
}
