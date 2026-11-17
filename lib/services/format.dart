import 'package:intl/intl.dart';

final _euro = NumberFormat.currency(locale: 'nl_BE', symbol: '€', decimalDigits: 2);
final _euroRound = NumberFormat.currency(locale: 'nl_BE', symbol: '€', decimalDigits: 0);
final _pct = NumberFormat.percentPattern('nl_BE');

String euro(double v) => _euro.format(v);
String euroRound(double v) => _euroRound.format(v);
String percent(double v) => _pct.format(v);
String shortDate(DateTime d) => DateFormat('EEE d MMM', 'nl_BE').format(d);
String monthLabel(DateTime d) => DateFormat('MMMM yyyy', 'nl_BE').format(d);
