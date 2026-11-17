import '../models/transaction.dart';
import 'categorizer.dart';

/// Resultaat van een CSV-import.
class CsvImportResult {
  CsvImportResult({
    required this.expenses,
    required this.skippedIncome,
    required this.skippedInvalid,
  });

  final List<Transaction> expenses;
  final int skippedIncome;
  final int skippedInvalid;
}

class CsvFormatException implements Exception {
  CsvFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Leest bank-CSV's in Belgische stijl: `;` of `,` als scheidingsteken,
/// dd/mm/jjjj-datums en komma-decimalen ("-1.234,56").
///
/// Verwachte kolommen: date;description;counterparty;amount. Gangbare
/// Nederlandse/Franse kolomnamen (datum, omschrijving, tegenpartij, bedrag, ...)
/// worden ook herkend. Zonder herkenbare header wordt die volgorde aangenomen.
class CsvParser {
  const CsvParser({this.categorizer = const Categorizer()});

  final Categorizer categorizer;

  static const _dateAliases = [
    'date', 'datum', 'boekingsdatum', 'uitvoeringsdatum', 'transactiedatum',
    'date comptable',
  ];
  static const _descAliases = [
    'description', 'omschrijving', 'mededeling', 'communicatie', 'libellé',
    'libelle', 'details',
  ];
  static const _cpAliases = [
    'counterparty', 'tegenpartij', 'naam tegenpartij', 'naam van de tegenpartij',
    'begunstigde', 'contrepartie', 'merchant', 'handelaar',
  ];
  static const _amountAliases = ['amount', 'bedrag', 'montant'];

  CsvImportResult parse(String raw) {
    final text = raw.replaceFirst('\uFEFF', '');
    final lines = text
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) throw CsvFormatException('Het bestand is leeg.');

    final delimiter = detectDelimiter(lines.first);
    final header = splitLine(lines.first, delimiter)
        .map((h) => h.trim().toLowerCase())
        .toList();

    int find(List<String> aliases) => header.indexWhere(aliases.contains);
    var iDate = find(_dateAliases);
    var iDesc = find(_descAliases);
    var iCp = find(_cpAliases);
    var iAmount = find(_amountAliases);

    var start = 1;
    if (iDate < 0 || iAmount < 0) {
      // Geen herkenbare header: neem date;description;counterparty;amount aan.
      final looksLikeData = parseDate(header.first) != null;
      start = looksLikeData ? 0 : 1;
      iDate = 0;
      iDesc = 1;
      iCp = 2;
      iAmount = 3;
    }

    final expenses = <Transaction>[];
    var income = 0;
    var invalid = 0;
    for (var n = start; n < lines.length; n++) {
      final cols = splitLine(lines[n], delimiter);
      String col(int i) => (i >= 0 && i < cols.length) ? cols[i].trim() : '';

      final date = parseDate(col(iDate));
      final amount = parseAmount(col(iAmount));
      if (date == null || amount == null) {
        invalid++;
        continue;
      }
      if (amount >= 0) {
        income++;
        continue;
      }
      final desc = col(iDesc);
      final cp = col(iCp);
      expenses.add(Transaction(
        id: 'tx$n',
        date: date,
        description: desc,
        counterparty: cp,
        amount: -amount,
        category: categorizer.categorize(desc, cp),
      ));
    }
    if (expenses.isEmpty) {
      throw CsvFormatException(
          'Geen uitgaven gevonden. Check of je kolommen date;description;counterparty;amount zijn.');
    }
    // Stabiel sorteren: op datum, bij gelijke datum de volgorde uit het bestand.
    final order = {for (var i = 0; i < expenses.length; i++) expenses[i]: i};
    expenses.sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : order[a]!.compareTo(order[b]!);
    });
    return CsvImportResult(
      expenses: expenses,
      skippedIncome: income,
      skippedInvalid: invalid,
    );
  }

  static String detectDelimiter(String headerLine) {
    final semis = ';'.allMatches(headerLine).length;
    final commas = ','.allMatches(headerLine).length;
    final tabs = '\t'.allMatches(headerLine).length;
    if (tabs > semis && tabs > commas) return '\t';
    return semis >= commas && semis > 0 ? ';' : ',';
  }

  /// Splitst één regel, met ondersteuning voor "aanhalingstekens" en "" escapes.
  static List<String> splitLine(String line, String delimiter) {
    final out = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (c == delimiter && !inQuotes) {
        out.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    out.add(buf.toString());
    return out;
  }

  /// "-1.234,56" / "-12,50" / "-12.50" / "€ -12,50" -> double.
  static double? parseAmount(String input) {
    var s = input.replaceAll(RegExp(r'[€\s\u00A0]|EUR', caseSensitive: false), '');
    if (s.isEmpty) return null;
    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');
    if (lastComma >= 0 && lastDot >= 0) {
      if (lastComma > lastDot) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (lastComma >= 0) {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  /// dd/mm/jjjj, dd-mm-jjjj, dd.mm.jjjj of jjjj-mm-dd.
  static DateTime? parseDate(String input) {
    final s = input.trim();
    final dmy = RegExp(r'^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})$').firstMatch(s);
    if (dmy != null) {
      var y = int.parse(dmy.group(3)!);
      if (y < 100) y += 2000;
      return _safeDate(y, int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
    }
    final ymd = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(s);
    if (ymd != null) {
      return _safeDate(int.parse(ymd.group(1)!), int.parse(ymd.group(2)!),
          int.parse(ymd.group(3)!));
    }
    return null;
  }

  static DateTime? _safeDate(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }
}
