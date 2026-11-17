import 'package:intl/intl.dart';

final _euro = NumberFormat.currency(locale: 'nl_BE', symbol: '€', decimalDigits: 2);
final _euroRound = NumberFormat.currency(locale: 'nl_BE', symbol: '€', decimalDigits: 0);
final _pct = NumberFormat.percentPattern('nl_BE');
final _num = NumberFormat.decimalPatternDigits(locale: 'nl_BE', decimalDigits: 2);

String euro(double v) => _euro.format(v);
String euroRound(double v) => _euroRound.format(v);
String percent(double v) => _pct.format(v);
String number2(double v) => _num.format(v);
String shortDate(DateTime d) => DateFormat('EEE d MMM', 'nl_BE').format(d);
String longDate(DateTime d) => DateFormat('EEEE d MMMM', 'nl_BE').format(d);
String dayMonth(DateTime d) => DateFormat('d MMM', 'nl_BE').format(d);
String monthLabel(DateTime d) => DateFormat('MMMM yyyy', 'nl_BE').format(d);

/// Initialen voor een avatar: "Uber Eats" -> "UE", "bpost" -> "B".
String initials(String name) {
  final words = name
      .replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ+ ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first[0].toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}
