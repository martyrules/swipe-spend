import 'category.dart';
import 'reason.dart';

/// Oordeel na een swipe.
enum Verdict {
  /// Swipe rechts: "zou ik opnieuw doen".
  keep,

  /// Swipe links: "niet meer" (spijt).
  regret,
}

/// Eén uitgave uit een bank-export.
class Transaction {
  Transaction({
    required this.id,
    required this.date,
    required this.merchant,
    required this.rawDescriptor,
    required this.amount,
    required this.category,
    this.counterparty = '',
    this.settlementDate,
    this.foreignAmount,
    this.foreignCurrency,
    this.fxRate,
    this.source = '',
    this.verdict,
    this.note = '',
    Set<Reason>? reasons,
  }) : reasons = reasons ?? <Reason>{};

  final String id;

  /// Datum van de transactie.
  final DateTime date;

  /// Opgekuiste, leesbare naam ("Laadpaal", "Amazon", ...).
  final String merchant;

  /// De ruwe omschrijving zoals de bank ze toont.
  final String rawDescriptor;

  final String counterparty;

  /// Bedrag van de uitgave als positief getal (in euro).
  final double amount;
  final SpendCategory category;

  /// Verrekendatum (kredietkaart).
  final DateTime? settlementDate;

  /// Originele vreemde munt, bv. 280,00 USD.
  final double? foreignAmount;
  final String? foreignCurrency;

  /// Wisselkoers: 1 EUR = [fxRate] [foreignCurrency].
  final double? fxRate;

  /// Bron, bv. "Argenta kredietkaart".
  final String source;

  Verdict? verdict;

  /// "Wat was het?"-notitie van de gebruiker.
  String note;
  Set<Reason> reasons;

  bool get hasNote => note.trim().isNotEmpty || reasons.isNotEmpty;

  Map<String, Object?> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'merchant': merchant,
        'raw': rawDescriptor,
        'cp': counterparty,
        'amount': amount,
        'cat': category.name,
        'settle': settlementDate?.toIso8601String(),
        'fxAmt': foreignAmount,
        'fxCur': foreignCurrency,
        'fxRate': fxRate,
        'src': source,
        'verdict': verdict?.name,
        'note': note,
        'reasons': reasons.map((r) => r.name).toList(),
      };

  factory Transaction.fromJson(Map<String, Object?> j) => Transaction(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        merchant: j['merchant'] as String,
        rawDescriptor: j['raw'] as String? ?? '',
        counterparty: j['cp'] as String? ?? '',
        amount: (j['amount'] as num).toDouble(),
        category: SpendCategory.byName(j['cat'] as String?),
        settlementDate: j['settle'] == null
            ? null
            : DateTime.parse(j['settle'] as String),
        foreignAmount: (j['fxAmt'] as num?)?.toDouble(),
        foreignCurrency: j['fxCur'] as String?,
        fxRate: (j['fxRate'] as num?)?.toDouble(),
        source: j['src'] as String? ?? '',
        verdict: switch (j['verdict']) {
          'keep' => Verdict.keep,
          'regret' => Verdict.regret,
          _ => null,
        },
        note: j['note'] as String? ?? '',
        reasons: {
          for (final r in (j['reasons'] as List? ?? const []))
            ?Reason.byName(r as String),
        },
      );
}
