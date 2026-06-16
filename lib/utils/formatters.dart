import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final _shortDate = DateFormat('MMM d, yyyy');
final _monthYear = DateFormat('MMMM yyyy');
final _shortMonthDay = DateFormat('MMM d');

String formatAmount(double amount) => _currency.format(amount);

String formatDate(DateTime date) => _shortDate.format(date);

String formatMonthYear(DateTime date) => _monthYear.format(date);

String formatShortDate(DateTime date) => _shortMonthDay.format(date);

/// Groups a list of items by the calendar date of a DateTime field.
Map<DateTime, List<T>> groupByDate<T>(
  List<T> items,
  DateTime Function(T) getDate,
) {
  final map = <DateTime, List<T>>{};
  for (final item in items) {
    final d = getDate(item);
    final key = DateTime(d.year, d.month, d.day);
    (map[key] ??= []).add(item);
  }
  return map;
}
