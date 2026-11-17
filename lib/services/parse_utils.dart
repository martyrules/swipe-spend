import '../models/transaction.dart';

/// "-1.234,56" / "-12,50" / "-12.50" / "€ -12,50" -> double.
double? parseEuroAmount(String input) {
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
DateTime? parseFlexibleDate(String input) {
  final s = input.trim();
  final dmy = RegExp(r'^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})$').firstMatch(s);
  if (dmy != null) {
    var y = int.parse(dmy.group(3)!);
    if (y < 100) y += 2000;
    return safeDate(y, int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
  }
  final ymd = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(s);
  if (ymd != null) {
    return safeDate(int.parse(ymd.group(1)!), int.parse(ymd.group(2)!),
        int.parse(ymd.group(3)!));
  }
  return null;
}

DateTime? safeDate(int y, int m, int d) {
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

/// Stabiel sorteren op datum (bij gelijke datum: volgorde van het bestand).
void stableSortByDate(List<Transaction> list) {
  final order = {for (var i = 0; i < list.length; i++) list[i]: i};
  list.sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : order[a]!.compareTo(order[b]!);
  });
}
