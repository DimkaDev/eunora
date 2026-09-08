import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';

enum DailyScheduledState {
  /// Today is a scheduled day for this medication, and no dose has been logged today.
  readyToLog,

  /// Today is a scheduled day for this medication, and a dose has already been logged today.
  logged,

  /// Today is not one of this medication's selected weekdays or date is outside active range.
  notScheduledToday,

  /// On-demand medication without a fixed schedule.
  asNeeded,
}

enum HrtDateContext {
  /// Context A — Today (Live/Canonical): Viewing/logging current day.
  /// Uses the live, currently active regimen list.
  contextAToday,

  /// Context B — Retroactive, Within Known History: Viewing/logging a past date using
  /// the regimen version authoritative on that date (per start_date/end_date).
  /// Pure adherence-logging action — does not alter canonical medication timeline.
  contextBRetroactiveWithinHistory,

  /// Context C — Retroactive, With Data Correction: Entering a dose, frequency, or medication
  /// on a past date that differs from canonical timeline or adding a one-off historical log.
  /// Never silently rewrites the canonical regimen history.
  contextCRetroactiveCorrection,
}

class HrtScheduleService {
  /// Resolves which of the three date contexts applies for [selectedDate].
  static HrtDateContext resolveDateContext({
    required DateTime selectedDate,
    bool isCorrection = false,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (target.isAtSameMomentAs(today) || target.isAfter(today)) {
      return HrtDateContext.contextAToday;
    }

    if (isCorrection) {
      return HrtDateContext.contextCRetroactiveCorrection;
    }

    return HrtDateContext.contextBRetroactiveWithinHistory;
  }

  /// Checks whether [newMed] exactly duplicates an already-active medication in [existingMeds].
  ///
  /// Criteria for exact active duplicate:
  /// - The existing medication is currently active (`endedAt == null` or active period overlaps).
  /// - Exact match on drug name (case-insensitive, trimmed).
  /// - Exact match on form / type (`newMed.type == existing.type`).
  /// - Exact match on dose value (`(newMed.dose - existing.dose).abs() < 0.001`).
  /// - Exact match on dose unit (case-insensitive, trimmed).
  /// - Exact match on frequency (case-insensitive, trimmed).
  /// - If [newMed] has an `id` matching [existing.id], it is an edit of the same entity and not considered a duplicate.
  ///
  /// Returns the conflicting [Medication] if an exact duplicate exists, or `null` otherwise.
  static Medication? findExactActiveDuplicate(
    Medication newMed,
    List<Medication> existingMeds, {
    DateTime? targetDate,
  }) {
    final now = DateTime.now();
    final checkDate = targetDate ?? DateTime(now.year, now.month, now.day);

    for (final existing in existingMeds) {
      if (newMed.id != null && existing.id == newMed.id) {
        continue; // Editing the same existing medication
      }

      // Check if existing medication is currently active on checkDate
      if (existing.endedAt != null) {
        final end = DateTime(existing.endedAt!.year, existing.endedAt!.month, existing.endedAt!.day);
        if (checkDate.isAfter(end)) {
          continue; // Prior medication has been soft-stopped in the past (resuming after break is allowed)
        }
      }

      if (existing.startedAt != null) {
        final start = DateTime(existing.startedAt!.year, existing.startedAt!.month, existing.startedAt!.day);
        if (newMed.endedAt != null) {
          final newEnd = DateTime(newMed.endedAt!.year, newMed.endedAt!.month, newMed.endedAt!.day);
          if (newEnd.isBefore(start)) {
            continue; // Non-overlapping active periods
          }
        }
      }

      final nameMatch = existing.name.trim().toLowerCase() == newMed.name.trim().toLowerCase();
      final typeMatch = existing.type == newMed.type;
      final doseMatch = (existing.dose - newMed.dose).abs() < 0.001;
      final unitMatch = existing.unit.trim().toLowerCase() == newMed.unit.trim().toLowerCase();
      final freqMatch = existing.frequency.trim().toLowerCase() == newMed.frequency.trim().toLowerCase();

      if (nameMatch && typeMatch && doseMatch && unitMatch && freqMatch) {
        return existing;
      }
    }

    return null;
  }

  /// Returns true if this medication has an "As Needed" frequency (no fixed schedule).
  static bool isAsNeeded(Medication med) {
    return med.frequency.toLowerCase().contains('needed');
  }

  /// Parses weekday names (e.g., "Mon, Thu", "Monday") into 1-based ISO weekday integers (1..7).
  static List<int> parseWeekdaysString(String str) {
    if (str.isEmpty) return [1, 2, 3, 4, 5, 6, 7];
    final lower = str.toLowerCase();
    if (lower.contains('daily')) return [1, 2, 3, 4, 5, 6, 7];

    final Map<String, int> nameToWeekday = {
      'mon': 1,
      'tue': 2,
      'wed': 3,
      'thu': 4,
      'fri': 5,
      'sat': 6,
      'sun': 7,
    };

    final List<int> result = [];
    nameToWeekday.forEach((key, val) {
      if (lower.contains(key)) {
        result.add(val);
      }
    });

    return result.isNotEmpty ? result : [1, 2, 3, 4, 5, 6, 7];
  }

  /// Returns the active selected weekdays for [med] on [date], taking historical schedule changes into account.
  static List<int> getActiveWeekdaysForDate(
    Medication med,
    DateTime date, {
    Iterable<HrtDoseChange>? doseChanges,
  }) {
    if (doseChanges == null || doseChanges.isEmpty) {
      return med.selectedWeekdays.isNotEmpty
          ? med.selectedWeekdays
          : Medication.defaultWeekdaysForFrequency(med.frequency);
    }

    final targetDate = DateTime(date.year, date.month, date.day);

    final scheduleChanges = doseChanges
        .where((c) =>
            c.medicationId == med.id ||
            c.medicationName.trim().toLowerCase() == med.name.trim().toLowerCase())
        .where((c) => c.changeType == RegimenChangeType.scheduleDayChange)
        .toList()
      ..sort((a, b) => a.changeDate.compareTo(b.changeDate));

    if (scheduleChanges.isEmpty) {
      return med.selectedWeekdays.isNotEmpty
          ? med.selectedWeekdays
          : Medication.defaultWeekdaysForFrequency(med.frequency);
    }

    for (final change in scheduleChanges) {
      final changeDateOnly = DateTime(change.changeDate.year, change.changeDate.month, change.changeDate.day);
      if (targetDate.isBefore(changeDateOnly)) {
        return parseWeekdaysString(change.previousValue);
      }
    }

    return med.selectedWeekdays.isNotEmpty
        ? med.selectedWeekdays
        : Medication.defaultWeekdaysForFrequency(med.frequency);
  }

  /// Returns true if [date] falls on one of [med]'s selected weekdays and is within its active date range.
  static bool isScheduledOnDate(
    Medication med,
    DateTime date, {
    Iterable<HrtDoseChange>? doseChanges,
  }) {
    if (isAsNeeded(med)) return false;

    final targetDate = DateTime(date.year, date.month, date.day);

    if (med.startedAt != null) {
      final startDate = DateTime(med.startedAt!.year, med.startedAt!.month, med.startedAt!.day);
      if (targetDate.isBefore(startDate)) return false;
    }

    if (med.endedAt != null) {
      final endDate = DateTime(med.endedAt!.year, med.endedAt!.month, med.endedAt!.day);
      if (targetDate.isAfter(endDate)) return false;
    }

    final weekdays = getActiveWeekdaysForDate(med, date, doseChanges: doseChanges);
    return weekdays.contains(date.weekday);
  }

  /// Resolves the exact daily scheduled state for [med] on [date].
  static DailyScheduledState getDailyState({
    required Medication med,
    required DateTime date,
    HrtIntakeLog? loggedIntake,
    Iterable<HrtDoseChange>? doseChanges,
  }) {
    if (isAsNeeded(med)) {
      return DailyScheduledState.asNeeded;
    }

    if (loggedIntake != null && loggedIntake.isTaken) {
      return DailyScheduledState.logged;
    }

    if (!isScheduledOnDate(med, date, doseChanges: doseChanges)) {
      return DailyScheduledState.notScheduledToday;
    }

    return DailyScheduledState.readyToLog;
  }

  /// Calculates total missed occurrences for [med] between [startDate] and [endDate].
  /// Missed occurrences are counted per scheduled occurrence (not per calendar day).
  /// As Needed medications return 0.
  static int calculateMissedOccurrences({
    required Medication med,
    required List<DailyLog> logs,
    required DateTime startDate,
    required DateTime endDate,
    Iterable<HrtDoseChange>? doseChanges,
  }) {
    if (isAsNeeded(med)) return 0;

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final effectiveEnd = end.isAfter(todayDate) ? todayDate : end;

    final Map<String, DailyLog> logsByDateKey = {};
    for (final log in logs) {
      final key = "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
      logsByDateKey[key] = log;
    }

    int missedCount = 0;
    DateTime current = start;

    while (!current.isAfter(effectiveEnd)) {
      if (isScheduledOnDate(med, current, doseChanges: doseChanges)) {
        final key = "${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}";
        final log = logsByDateKey[key];

        bool wasTaken = false;
        if (log != null) {
          final intake = log.hrtIntakes.firstWhere(
            (h) => h.medicationId == med.id || h.name.toLowerCase() == med.name.toLowerCase(),
            orElse: () => HrtIntakeLog(medicationId: med.id, name: med.name, dose: med.dose, unit: med.unit, time: '', isTaken: false),
          );
          wasTaken = intake.isTaken;
        }

        if (!wasTaken) {
          missedCount++;
        }
      }
      current = current.add(const Duration(days: 1));
    }

    return missedCount;
  }

  /// Returns true if [med] has at least one recorded intake where [isTaken] is true across [logs].
  static bool hasLoggedHistory(Medication med, Iterable<DailyLog> logs) {
    final targetId = med.id;
    final targetNameLower = med.name.trim().toLowerCase();

    for (final log in logs) {
      if (targetNameLower.contains('estradiol') && log.estradiolChecked) {
        return true;
      }
      if (targetNameLower.contains('progesterone') && log.progesteroneChecked) {
        return true;
      }
      for (final intake in log.hrtIntakes) {
        final matches = (intake.medicationId.isNotEmpty && intake.medicationId == targetId) ||
            (intake.name.trim().toLowerCase() == targetNameLower);
        if (matches && intake.isTaken) {
          return true;
        }
      }
    }
    return false;
  }

  /// Calculates consecutive missed scheduled occurrences for [med] looking backward from [evaluationDate] (defaults to today).
  ///
  /// Increments ONLY on scheduled occurrences (selected weekdays active on that date).
  /// As Needed medications return 0.
  /// Stops counting as soon as a scheduled occurrence is found with isTaken == true.
  static int calculateConsecutiveMissedOccurrences({
    required Medication med,
    required List<DailyLog> logs,
    DateTime? evaluationDate,
    Iterable<HrtDoseChange>? doseChanges,
  }) {
    if (isAsNeeded(med)) return 0;

    final eval = evaluationDate ?? DateTime.now();
    final todayDate = DateTime(eval.year, eval.month, eval.day);

    final Map<String, DailyLog> logsByDateKey = {};
    for (final log in logs) {
      final key =
          "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
      logsByDateKey[key] = log;
    }

    int consecutiveMissed = 0;
    for (int daysAgo = 0; daysAgo < 365; daysAgo++) {
      final current = todayDate.subtract(Duration(days: daysAgo));

      if (med.startedAt != null) {
        final startOnly = DateTime(
            med.startedAt!.year, med.startedAt!.month, med.startedAt!.day);
        if (current.isBefore(startOnly)) break;
      }

      if (isScheduledOnDate(med, current, doseChanges: doseChanges)) {
        final key =
            "${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}";
        final log = logsByDateKey[key];

        bool wasTaken = false;
        if (log != null) {
          final intake = log.hrtIntakes.firstWhere(
            (h) =>
                (h.medicationId.isNotEmpty && h.medicationId == med.id) ||
                (h.name.trim().toLowerCase() == med.name.trim().toLowerCase()),
            orElse: () => HrtIntakeLog(
              medicationId: med.id,
              name: med.name,
              dose: med.dose,
              unit: med.unit,
              time: '',
              isTaken: false,
            ),
          );
          wasTaken = intake.isTaken;
        }

        if (wasTaken) {
          break;
        } else {
          consecutiveMissed++;
        }
      }
    }

    return consecutiveMissed;
  }
}
