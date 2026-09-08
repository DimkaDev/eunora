import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported time format display modes.
enum TimeFormatMode {
  /// 12-hour format with uppercase AM/PM (e.g., "10:17 PM", "08:30 AM")
  twelveHour,

  /// 24-hour format (e.g., "22:17", "08:30")
  twentyFourHour,

  /// Uses system/locale format (via MediaQuery or context if available)
  system,
}

extension TimeFormatModeExtension on TimeFormatMode {
  String get label {
    switch (this) {
      case TimeFormatMode.twelveHour:
        return '12-hour (AM/PM)';
      case TimeFormatMode.twentyFourHour:
        return '24-hour';
      case TimeFormatMode.system:
        return 'System Default';
    }
  }

  String get sample {
    final now = TimeOfDay(hour: 22, minute: 17);
    return AppTimeFormatter.formatTimeOfDay(now, mode: this);
  }
}

/// Global configuration for time formatting throughout the app.
class TimeFormatConfig {
  final TimeFormatMode mode;

  const TimeFormatConfig({this.mode = TimeFormatMode.twelveHour});

  TimeFormatConfig copyWith({TimeFormatMode? mode}) {
    return TimeFormatConfig(mode: mode ?? this.mode);
  }
}

/// Riverpod provider for TimeFormatConfig
final timeFormatConfigProvider = StateProvider<TimeFormatConfig>((ref) {
  return const TimeFormatConfig(mode: TimeFormatMode.twelveHour);
});

/// Centralized Time Formatter for Eunora.
/// Parses and formats time strings consistently across Home, Daily Logging,
/// Calendar, HRT Tracker, and Edit Sheets.
class AppTimeFormatter {
  static TimeFormatMode defaultMode = TimeFormatMode.twelveHour;
  static const String prefKey = 'pref_time_format_mode';

  /// Initializes defaultMode from SharedPreferences
  static Future<void> initFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefKey);
      if (saved != null) {
        for (final mode in TimeFormatMode.values) {
          if (mode.name == saved) {
            defaultMode = mode;
            break;
          }
        }
      }
    } catch (_) {}
  }

  /// Sets and persists time format mode
  static Future<void> setMode(TimeFormatMode mode) async {
    defaultMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, mode.name);
    } catch (_) {}
  }

  /// Parses any time representation (String in 12h/24h or with prefix, TimeOfDay, DateTime) into TimeOfDay.
  static TimeOfDay parseTimeOfDay(dynamic input) {
    if (input == null) return TimeOfDay.now();
    if (input is TimeOfDay) return input;
    if (input is DateTime) return TimeOfDay(hour: input.hour, minute: input.minute);

    final clean = input.toString().trim();
    if (clean.isEmpty) return TimeOfDay.now();

    // 1. Check for 12-hour AM/PM pattern (e.g. "10:17 PM", "8:30 am", "Taken 10:17 PM")
    final amPmMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)', caseSensitive: false).firstMatch(clean);
    if (amPmMatch != null) {
      int hour = int.parse(amPmMatch.group(1)!);
      final minute = int.parse(amPmMatch.group(2)!);
      final period = amPmMatch.group(3)!.toUpperCase();
      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    }

    // 2. Check for 24-hour pattern (e.g. "22:17", "08:30", "Taken 22:17")
    final match24 = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(clean);
    if (match24 != null) {
      final hour = int.parse(match24.group(1)!);
      final minute = int.parse(match24.group(2)!);
      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    return TimeOfDay.now();
  }

  /// Formats a TimeOfDay to a standardized string based on the given mode or default configuration.
  static String formatTimeOfDay(
    TimeOfDay time, {
    TimeFormatMode? mode,
    BuildContext? context,
  }) {
    final effectiveMode = mode ?? defaultMode;

    switch (effectiveMode) {
      case TimeFormatMode.twentyFourHour:
        final h = time.hour.toString().padLeft(2, '0');
        final m = time.minute.toString().padLeft(2, '0');
        return '$h:$m';

      case TimeFormatMode.system:
        if (context != null) {
          final is24 = MediaQuery.alwaysUse24HourFormatOf(context);
          if (is24) {
            final h = time.hour.toString().padLeft(2, '0');
            final m = time.minute.toString().padLeft(2, '0');
            return '$h:$m';
          }
        }
        final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
        final m = time.minute.toString().padLeft(2, '0');
        final period = time.period == DayPeriod.am ? 'AM' : 'PM';
        return '${h.toString().padLeft(2, '0')}:$m $period';

      case TimeFormatMode.twelveHour:
      default:
        final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
        final m = time.minute.toString().padLeft(2, '0');
        final period = time.period == DayPeriod.am ? 'AM' : 'PM';
        return '${h.toString().padLeft(2, '0')}:$m $period';
    }
  }

  /// Normalizes and formats a raw time string (e.g. "22:17" -> "10:17 PM" or vice versa based on mode).
  static String formatTimeString(
    String rawTime, {
    TimeFormatMode? mode,
    BuildContext? context,
  }) {
    if (rawTime.trim().isEmpty) return '';
    final time = parseTimeOfDay(rawTime);
    return formatTimeOfDay(time, mode: mode, context: context);
  }

  /// Extracts the time portion from a status string (e.g. "Taken 10:17 PM" -> "10:17 PM", "Taken 22:17" -> "10:17 PM").
  static String extractTimeFromStatus(
    String status, {
    TimeFormatMode? mode,
    BuildContext? context,
    String defaultFallback = '08:00 AM',
  }) {
    final clean = status.trim();
    if (clean.isEmpty || clean.toLowerCase() == 'not taken') {
      return defaultFallback;
    }

    // If it has a timestamp, parse and reformat
    final time = parseTimeOfDay(clean);
    return formatTimeOfDay(time, mode: mode, context: context);
  }

  /// Formats a DateTime instance into date + standardized time string.
  static String formatDateTime(
    DateTime dt, {
    TimeFormatMode? mode,
    BuildContext? context,
  }) {
    final tod = TimeOfDay(hour: dt.hour, minute: dt.minute);
    return formatTimeOfDay(tod, mode: mode, context: context);
  }
}
