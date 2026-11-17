import 'category.dart';

/// Oordeel na een swipe.
enum Verdict {
  /// Swipe rechts: "zou ik opnieuw doen".
  keep,

  /// Swipe links: "niet meer" (spijt).
  regret,
}

/// Eén uitgave uit de bank-export.
class Transaction {
  Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.counterparty,
    required this.amount,
    required this.category,
    this.verdict,
  });

  final String id;
  final DateTime date;
  final String description;
  final String counterparty;

  /// Bedrag van de uitgave als positief getal (in euro).
  final double amount;
  final SpendCategory category;
  Verdict? verdict;

  /// Naam om op de kaart te tonen: tegenpartij, of anders de omschrijving.
  String get merchant =>
      counterparty.trim().isNotEmpty ? counterparty.trim() : description.trim();
}
