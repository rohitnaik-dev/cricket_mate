import 'package:intl/intl.dart';

/// Formatting helpers for dates, times, and cricket session ranges.
abstract final class DateFormatter {
  static final DateFormat _dayOfWeekMonth = DateFormat('EEE, MMM d');
  static final DateFormat _timeOnly = DateFormat('h:mm a');
  static final DateFormat _shortTime = DateFormat('ha');

  /// Formats a [DateTime] into a friendly day string, e.g. "Sat, Oct 12".
  static String formatDayHeader(DateTime dateTime) {
    return _dayOfWeekMonth.format(dateTime);
  }

  /// Formats a [DateTime] into standard time, e.g. "3:00 PM".
  static String formatTime(DateTime dateTime) {
    return _timeOnly.format(dateTime);
  }

  /// Formats a start and end [DateTime] into a session window string, e.g. "3:00 PM - 5:00 PM".
  static String formatSessionRange(DateTime start, DateTime end) {
    return '${_timeOnly.format(start)} - ${_timeOnly.format(end)}';
  }

  /// Formats a short hour, e.g. "3PM".
  static String formatShortHour(DateTime dateTime) {
    return _shortTime.format(dateTime);
  }

  /// Parses an ISO 8601 string safely into a [DateTime].
  static DateTime? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Formats a [DateTime] into ISO 8601 date string for API queries.
  static String toIsoDateOnly(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}
