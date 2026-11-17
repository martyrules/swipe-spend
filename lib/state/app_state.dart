import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

import '../models/import_result.dart';
import '../models/reason.dart';
import '../models/transaction.dart';
import '../services/argenta_pdf_parser.dart';
import '../services/csv_parser.dart';
import '../services/storage.dart';

/// Lokale app-state (geen backend). Alles blijft op het toestel en wordt
/// in localStorage/shared_preferences bewaard.
class AppState extends ChangeNotifier {
  AppState(this._store);

  static const sampleAsset = 'assets/voorbeelddata_oktober_2026.csv';

  final LocalStore _store;
  final CsvParser _csv = const CsvParser();
  final ArgentaPdfParser _argenta = const ArgentaPdfParser();

  List<Transaction> transactions = [];
  bool isSample = false;
  String? sourceName;
  int skippedIncome = 0;
  int skippedInvalid = 0;
  StatementCheck? check;

  /// Index van de kaart die nu bovenaan ligt.
  int currentIndex = 0;
  final List<int> _history = [];

  bool get onboardingDone => _store.onboardingDone;
  bool get hasData => transactions.isNotEmpty;
  bool get isDone => hasData && currentIndex >= transactions.length;
  bool get canUndo => _history.isNotEmpty;
  int get reviewedCount => currentIndex;
  Transaction? get current =>
      currentIndex < transactions.length ? transactions[currentIndex] : null;

  /// Herstel een eerdere sessie uit lokale opslag.
  void restore() {
    final s = _store.loadSession();
    if (s == null) return;
    try {
      transactions = [
        for (final j in (s['tx'] as List))
          Transaction.fromJson((j as Map).cast<String, Object?>()),
      ];
      isSample = s['sample'] as bool? ?? false;
      sourceName = s['source'] as String?;
      skippedIncome = s['income'] as int? ?? 0;
      currentIndex = (s['index'] as int? ?? 0).clamp(0, transactions.length);
      _history
        ..clear()
        ..addAll((s['history'] as List? ?? const []).cast<int>());
    } catch (_) {
      transactions = [];
    }
  }

  void _persist() {
    if (!hasData) {
      _store.clearSession();
      return;
    }
    _store.saveSession({
      'tx': [for (final t in transactions) t.toJson()],
      'sample': isSample,
      'source': sourceName,
      'income': skippedIncome,
      'index': currentIndex,
      'history': _history,
    });
  }

  @override
  void notifyListeners() {
    _persist();
    super.notifyListeners();
  }

  Future<void> completeOnboarding() => _store.setOnboardingDone(true);

  Future<void> resetOnboarding() async {
    await _store.setOnboardingDone(false);
    notifyListeners();
  }

  Future<void> loadSample() async {
    final raw = await rootBundle.loadString(sampleAsset);
    _apply(_csv.parse(raw, sourceLabel: 'Voorbeelddata'),
        sample: true, name: 'Voorbeelddata');
  }

  /// Gooit een [ImportFormatException] als het bestand niet te lezen is.
  void loadCsv(String raw, {required String name}) {
    _apply(_csv.parse(raw, sourceLabel: 'CSV'), sample: false, name: name);
  }

  /// Tekst uit een Argenta kredietkaart-pdf (al lokaal geëxtraheerd).
  ImportResult loadArgentaText(String text, {required String name}) {
    final r = _argenta.parse(text);
    final sample = text.contains('VOORBEELDDATA');
    _apply(r, sample: sample, name: sample ? 'Voorbeelddata (Argenta-pdf)' : name);
    return r;
  }

  void _apply(ImportResult r, {required bool sample, required String name}) {
    transactions = r.expenses;
    skippedIncome = r.skippedIncome;
    skippedInvalid = r.skippedInvalid;
    check = r.check;
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

  void setNote(Transaction t, String note, Set<Reason> reasons) {
    t.note = note.trim();
    t.reasons = {...reasons};
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

  Future<void> clearAll() async {
    transactions = [];
    isSample = false;
    sourceName = null;
    check = null;
    currentIndex = 0;
    _history.clear();
    await _store.clearSession();
    super.notifyListeners();
  }
}

/// Maakt [AppState] beschikbaar in de widget-boom.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget
              as AppScope)
          .notifier!;
}
