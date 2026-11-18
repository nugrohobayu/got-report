import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _display = DateFormat('d MMM yyyy, HH:mm');

  static String display(DateTime dateTime) => _display.format(dateTime);
}
