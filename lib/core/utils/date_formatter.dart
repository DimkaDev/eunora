import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported date format display modes.
enum AppDateFormatMode {
  dayMonthYear, // DD/MM/YYYY (e.g., 24/09/2026)
  monthDayYear, // MM/DD/YYYY (e.g., 09/24/2026)
  yearMonthDay, // YYYY-MM-DD (e.g., 2026-09-24)
  dayMonthNameYear, // DD MMM YYYY (e.g., 24 Sep 2026)
  monthNameDayYear, // MMM DD, YYYY (e.g., Sep 24, 2026)
}

extension AppDateFormatModeExtension on AppDateFormatMode {
  String get label {
    switch (this) {
      case AppDateFormatMode.dayMonthYear:
        return 'DD/MM/YYYY';
      case AppDateFormatMode.monthDayYear:
        return 'MM/DD/YYYY';
      case AppDateFormatMode.yearMonthDay:
        return 'YYYY-MM-DD';
      case AppDateFormatMode.dayMonthNameYear:
        return 'DD MMM YYYY';
      case AppDateFormatMode.monthNameDayYear:
        return 'MMM DD, YYYY';
    }
  }

  String get pattern {
    switch (this) {
      case AppDateFormatMode.dayMonthYear:
        return 'dd/MM/yyyy';
      case AppDateFormatMode.monthDayYear:
        return 'MM/dd/yyyy';
      case AppDateFormatMode.yearMonthDay:
        return 'yyyy-MM-dd';
      case AppDateFormatMode.dayMonthNameYear:
        return 'dd MMM yyyy';
      case AppDateFormatMode.monthNameDayYear:
        return 'MMM dd, yyyy';
    }
  }

  String get sample {
    final now = DateTime.now();
    return DateFormat(pattern).format(now);
  }
}

/// Global configuration for date formatting throughout the app.
class DateFormatConfig {
  final AppDateFormatMode mode;

  const DateFormatConfig({this.mode = AppDateFormatMode.dayMonthYear});

  DateFormatConfig copyWith({AppDateFormatMode? mode}) {
    return DateFormatConfig(mode: mode ?? this.mode);
  }
}

/// Riverpod provider for DateFormatConfig
final dateFormatConfigProvider = StateProvider<DateFormatConfig>((ref) {
  return const DateFormatConfig(mode: AppDateFormatMode.dayMonthYear);
});

/// Centralized Date Formatter for Eunora.
class AppDateFormatter {
  static AppDateFormatMode defaultMode = AppDateFormatMode.dayMonthYear;
  static const String prefKey = 'pref_date_format_mode';

  /// Initializes defaultMode from SharedPreferences
  static Future<void> initFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefKey);
      if (saved != null) {
        for (final mode in AppDateFormatMode.values) {
          if (mode.name == saved) {
            defaultMode = mode;
            break;
          }
        }
      }
    } catch (_) {}
  }

  /// Sets and persists date format mode
  static Future<void> setMode(AppDateFormatMode mode) async {
    defaultMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, mode.name);
    } catch (_) {}
  }

  /// Formats a DateTime instance to a standardized string based on the given mode or default.
  static String formatDate(DateTime date, {AppDateFormatMode? mode}) {
    final effectiveMode = mode ?? defaultMode;
    return DateFormat(effectiveMode.pattern).format(date);
  }

  /// Formats a short date representation (e.g., 24/09 or 09/24)
  static String formatShortDate(DateTime date, {AppDateFormatMode? mode}) {
    final effectiveMode = mode ?? defaultMode;
    switch (effectiveMode) {
      case AppDateFormatMode.dayMonthYear:
        return DateFormat('dd/MM').format(date);
      case AppDateFormatMode.monthDayYear:
        return DateFormat('MM/dd').format(date);
      case AppDateFormatMode.yearMonthDay:
        return DateFormat('MM-dd').format(date);
      case AppDateFormatMode.dayMonthNameYear:
        return DateFormat('d MMM').format(date);
      case AppDateFormatMode.monthNameDayYear:
        return DateFormat('MMM d').format(date);
    }
  }

  /// Formats month and year (e.g., September 2026 or Sep 2026)
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
}
