import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

import '../models/transaction.dart';
import '../services/csv_parser.dart';

/// Lokale app-state (geen backend). Alles blijft op het toestel.
class AppState extends ChangeNotifier {
  static const sampleAsset = 'assets/voorbeelddata_oktober_2026.csv';

  final CsvParser _parser = const CsvParser();

  List<Transaction> transactions = [];
  bool isSample = false;
  String? sourceName;
  int skippedIncome = 0;
  int skippedInvalid = 0;

  /// Index van de kaart die nu bovenaan ligt.
  int currentIndex = 0;
  final List<int> _history = [];

  bool get hasData => transactions.isNotEmpty;
  bool get isDone => hasData && currentIndex >= transactions.length;
  bool get canUndo => _history.isNotEmpty;
  int get reviewedCount => currentIndex;
  Transaction? get current =>
      currentIndex < transactions.length ? transactions[currentIndex] : null;

  Future<void> loadSample() async {
    final raw = await rootBundle.loadString(sampleAsset);
    _apply(_parser.parse(raw), sample: true, name: 'Voorbeelddata');
  }

  /// Gooit een [CsvFormatException] als het bestand niet te lezen is.
  void loadCsv(String raw, {required String name}) {
    _apply(_parser.parse(raw), sample: false, name: name);
  }

  void _apply(CsvImportResult r, {required bool sample, required String name}) {
    transactions = r.expenses;
    skippedIncome = r.skippedIncome;
    skippedInvalid = r.skippedInvalid;
    isSample = sample;
    sourceName = name;
    currentIndex = 0;
    _history.clear();
    notifyListeners();
  }

  void swipe(Verdict verdict) {
    final t = current;
    if (t == null) return;
    t.verdict = verdict;
    _history.add(currentIndex);
    currentIndex++;
    notifyListeners();
  }

  void undo() {
    if (_history.isEmpty) return;
    final i = _history.removeLast();
    transactions[i].verdict = null;
    currentIndex = i;
    notifyListeners();
  }

  void restartReview() {
    for (final t in transactions) {
      t.verdict = null;
    }
    currentIndex = 0;
    _history.clear();
    notifyListeners();
  }

  void clear() {
    transactions = [];
    isSample = false;
    sourceName = null;
    currentIndex = 0;
    _history.clear();
    notifyListeners();
  }
}

/// Maakt [AppState] beschikbaar in de widget-boom.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
