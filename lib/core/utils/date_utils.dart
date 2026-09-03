import 'package:intl/intl.dart';

abstract final class AppDateUtils {
  /// Returns the current local business date formatted as `yyyy-MM-dd`.
  /// Uses device local time (`DateTime.now()`). NEVER uses UTC.
  static String getCurrentLocalDate() {
    final now = DateTime.now();
    return formatBusinessDate(now);
  }

  /// Formats a [DateTime] into standard business date `yyyy-MM-dd`.
  static String formatBusinessDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  /// Alias for [formatBusinessDate] ensuring `yyyy-MM-dd` consistency across the app.
  static String formatDate(DateTime date) => formatBusinessDate(date);

  /// Formats a [DateTime] for user display (e.g., `03 Sep 2026`).
  static String formatDisplayDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  /// Formats a [DateTime] for user display time (e.g., `09:30 AM`).
  static String formatDisplayTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('hh:mm a').format(dt);
  }

  /// Checks if a `yyyy-MM-dd` string matches today's local date.
  static bool isToday(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    return dateStr == getCurrentLocalDate();
  }

  /// Parses a `yyyy-MM-dd` string safely into a local [DateTime].
  static DateTime? parseBusinessDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return DateTime.tryParse(dateStr);
  }
}

