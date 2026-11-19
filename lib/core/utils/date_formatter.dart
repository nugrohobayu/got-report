import 'package:intl/intl.dart';

/// Date formats in Bahasa Indonesia. Requires
/// `initializeDateFormatting('id_ID')` at startup (see main.dart).
class DateFormatter {
  DateFormatter._();

  static const _locale = 'id_ID';

  static final DateFormat _display = DateFormat('d MMM yyyy, HH:mm');

  static String display(DateTime dateTime) => _display.format(dateTime);

  /// `14:30`
  static String time(DateTime d) => DateFormat('HH:mm', _locale).format(d);

  /// `18 Nov`
  static String shortDate(DateTime d) => DateFormat('d MMM', _locale).format(d);

  /// `Rab, 18 Nov · 14:30`
  static String dayTime(DateTime d) =>
      DateFormat("EEE, d MMM '·' HH:mm", _locale).format(d);

  /// `Rabu, 18 November 2026`
  static String fullDate(DateTime d) =>
      DateFormat('EEEE, d MMMM yyyy', _locale).format(d);

  /// `November 2026`
  static String monthYear(DateTime d) =>
      DateFormat('MMMM yyyy', _locale).format(d);
}
