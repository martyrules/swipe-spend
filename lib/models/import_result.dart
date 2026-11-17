import 'transaction.dart';

/// Controle van een afschrift: komt onze som overeen met het "Nieuw Saldo"?
class StatementCheck {
  StatementCheck({
    required this.periodFrom,
    required this.periodTo,
    required this.statementNewBalance,
    required this.computedNewBalance,
    required this.previousBalance,
  });

  final DateTime? periodFrom;
  final DateTime? periodTo;
  final double? statementNewBalance;
  final double computedNewBalance;
  final double previousBalance;

  bool get matches =>
      statementNewBalance != null &&
      (statementNewBalance! - computedNewBalance).abs() < 0.005;
}

/// Resultaat van een import (CSV of pdf).
class ImportResult {
  ImportResult({
    required this.expenses,
    required this.skippedIncome,
    required this.skippedInvalid,
    required this.sourceLabel,
    this.check,
  });

  final List<Transaction> expenses;
  final int skippedIncome;
  final int skippedInvalid;
  final String sourceLabel;
  final StatementCheck? check;

  double get total => expenses.fold(0, (s, t) => s + t.amount);
}

class ImportFormatException implements Exception {
  ImportFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}
