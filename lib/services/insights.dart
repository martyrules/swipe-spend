import '../models/category.dart';
import '../models/transaction.dart';

class CategoryStat {
  CategoryStat(this.category);
  final SpendCategory category;
  double spent = 0;
  double regret = 0;
  int regretCount = 0;
  double get regretShare => spent == 0 ? 0 : regret / spent;
}

/// Berekent het spijt-overzicht uit de beoordeelde uitgaven.
class SpendInsights {
  SpendInsights(this.transactions);

  final List<Transaction> transactions;

  Iterable<Transaction> get _reviewed =>
      transactions.where((t) => t.verdict != null);

  double get totalSpent =>
      transactions.fold(0, (sum, t) => sum + t.amount);

  double get reviewedSpent => _reviewed.fold(0, (sum, t) => sum + t.amount);

  List<Transaction> get regrets {
    final list = transactions.where((t) => t.verdict == Verdict.regret).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  double get totalRegret => regrets.fold(0, (sum, t) => sum + t.amount);

  double get regretShare => totalSpent == 0 ? 0 : totalRegret / totalSpent;

  /// Aantal dagen dat de data beslaat, om naar een maandbedrag te schalen.
  int get spanDays {
    if (transactions.isEmpty) return 30;
    final dates = transactions.map((t) => t.date).toList()..sort();
    final days = dates.last.difference(dates.first).inDays + 1;
    return days < 28 ? 30 : days;
  }

  /// Wat je per maand bespaart als je de spijt-uitgaven schrapt.
  /// Eén maand data = de spijt zelf; langere periodes worden herschaald.
  double get monthlySavings =>
      spanDays <= 31 ? totalRegret : totalRegret * 30.4 / spanDays;

  double get yearlySavings => monthlySavings * 12;

  List<CategoryStat> get byCategory {
    final map = {for (final c in SpendCategory.values) c: CategoryStat(c)};
    for (final t in transactions) {
      final s = map[t.category]!;
      s.spent += t.amount;
      if (t.verdict == Verdict.regret) {
        s.regret += t.amount;
        s.regretCount++;
      }
    }
    final list = map.values.where((s) => s.spent > 0).toList()
      ..sort((a, b) => b.regret.compareTo(a.regret) != 0
          ? b.regret.compareTo(a.regret)
          : b.spent.compareTo(a.spent));
    return list;
  }

  /// Handelaar waar je het vaakst spijt had (bv. 3x Uber Eats).
  (String, int, double)? get topRegretMerchant {
    final counts = <String, (int, double)>{};
    for (final t in regrets) {
      final cur = counts[t.merchant] ?? (0, 0.0);
      counts[t.merchant] = (cur.$1 + 1, cur.$2 + t.amount);
    }
    if (counts.isEmpty) return null;
    final best = counts.entries.reduce((a, b) =>
        b.value.$1 > a.value.$1 ||
                (b.value.$1 == a.value.$1 && b.value.$2 > a.value.$2)
            ? b
            : a);
    return (best.key, best.value.$1, best.value.$2);
  }
}
