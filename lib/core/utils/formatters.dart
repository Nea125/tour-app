import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );
  static final DateFormat _date = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTime = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _shortDate = DateFormat('MMM d');

  static String currency(num value) => _currency.format(value);
  static String date(DateTime value) => _date.format(value);
  static String dateTime(DateTime value) => _dateTime.format(value);
  static String shortDate(DateTime value) => _shortDate.format(value);
}
