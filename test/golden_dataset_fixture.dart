/// Shared Golden Dataset G fixture for Tasks T1–T10.
///
/// 18 consecutive logged days, 2 Sep – 19 Sep 2026.
/// Today = Saturday 2026-09-19, Belgium time zone.
///
/// Rules:
/// - Default counters (caffeineCups ≥ 1, alcoholGlasses ≥ 1) on every day
///   even when the trigger was NOT selected — counters must never create events.
/// - Two logs carry a legacy exercise value stored under both an old and a new key.
/// - Severity mapping: Mild = 1, Moderate = 3, Severe = 5.

import 'dart:math';

import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Reference "today" for all tests unless a scenario overrides it.
final DateTime kToday = DateTime(2026, 9, 19);

/// First day of Golden Dataset G.
final DateTime kFirstLogDate = DateTime(2026, 9, 2);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DailyLog createLog({
  required DateTime date,
  bool isCompleted = true,
  List<LoggedSymptom> symptoms = const [],
  List<String> triggers = const [],
  int caffeineCups = 1,
  int alcoholGlasses = 1,
  String stressLevel = 'Moderate',
  double sleepDuration = 7.0,
  List<HrtIntakeLog> hrtIntakes = const [],
  DateTime? createdAt,
  Map<String, int> customTriggerCounters = const {},
  Map<String, String> customTriggerTexts = const {},
}) {
  return DailyLog(
    id: date.toIso8601String().substring(0, 10),
    userId: 'test_user',
    date: date,
    isCompleted: isCompleted,
    symptoms: symptoms,
    triggers: triggers,
    caffeineCups: caffeineCups,
    alcoholGlasses: alcoholGlasses,
    stressLevel: stressLevel,
    sleepDuration: sleepDuration,
    hrtIntakes: hrtIntakes,
    createdAt: createdAt ?? date,
    customTriggerCounters: customTriggerCounters,
    customTriggerTexts: customTriggerTexts,
  );
}

LoggedSymptom createSymptom({
  required String id,
  required String name,
  String? severity,
  int? intensity,
  int? durationMinutes,
}) {
  return LoggedSymptom(
    symptom: Symptom(id: id, name: name, iconName: 'medical_services'),
    severity: severity,
    intensity: intensity,
    durationMinutes: durationMinutes,
  );
}

// ---------------------------------------------------------------------------
// Symptom shorthands
// ---------------------------------------------------------------------------

LoggedSymptom hotFlash(String severity, {int? durationMinutes}) => createSymptom(
      id: 'hot_flash',
      name: 'Hot Flashes',
      severity: severity,
      durationMinutes: durationMinutes,
    );

LoggedSymptom fatigue(String severity) => createSymptom(
      id: 'fatigue',
      name: 'Fatigue',
      severity: severity,
    );

LoggedSymptom nightSweats(String severity, {int? durationMinutes}) =>
    createSymptom(
      id: 'night_sweats',
      name: 'Night Sweats',
      severity: severity,
      durationMinutes: durationMinutes,
    );

LoggedSymptom nightWakings(String severity) => createSymptom(
      id: 'night_wakings',
      name: 'Night Wakings',
      severity: severity,
    );

LoggedSymptom difficultyFallingAsleep(String severity) => createSymptom(
      id: 'difficulty_falling_asleep',
      name: 'Difficulty Falling Asleep',
      severity: severity,
    );

// ---------------------------------------------------------------------------
// Golden Dataset G — 18 consecutive logged days
// ---------------------------------------------------------------------------

/// Returns the 18-day Golden Dataset G.
/// Every day has default counters (caffeineCups=1, alcoholGlasses=1)
/// even when the trigger is not selected.
List<DailyLog> goldenDatasetLogs() {
  return [
    // 2026-09-02: fatigue:Moderate, night_sweats:Moderate(10m) | — | 7.5
    createLog(
      date: DateTime(2026, 9, 2),
      symptoms: [
        fatigue('Moderate'),
        nightSweats('Moderate', durationMinutes: 10),
      ],
      sleepDuration: 7.5,
    ),

    // 2026-09-03: hot_flash:Severe(5m), fatigue:Severe, night_wakings:Severe, night_sweats:Severe(15m) | coffee=2 | 7.5
    createLog(
      date: DateTime(2026, 9, 3),
      symptoms: [
        hotFlash('Severe', durationMinutes: 5),
        fatigue('Severe'),
        nightWakings('Severe'),
        nightSweats('Severe', durationMinutes: 15),
      ],
      triggers: ['Coffee / caffeine · 2 cups'],
      caffeineCups: 2,
      sleepDuration: 7.5,
    ),

    // 2026-09-04: hot_flash:Mild(5m) | — | 7.5
    createLog(
      date: DateTime(2026, 9, 4),
      symptoms: [
        hotFlash('Mild', durationMinutes: 5),
      ],
      sleepDuration: 7.5,
    ),

    // 2026-09-05: fatigue:Mild | coffee=2 | 7.5
    createLog(
      date: DateTime(2026, 9, 5),
      symptoms: [
        fatigue('Mild'),
      ],
      triggers: ['Coffee / caffeine · 2 cups'],
      caffeineCups: 2,
      sleepDuration: 7.5,
    ),

    // 2026-09-06: fatigue:Moderate, night_sweats:Severe(5m), difficulty_falling_asleep:Moderate | coffee=3, alcohol=1 | 7.5
    createLog(
      date: DateTime(2026, 9, 6),
      symptoms: [
        fatigue('Moderate'),
        nightSweats('Severe', durationMinutes: 5),
        difficultyFallingAsleep('Moderate'),
      ],
      triggers: ['Coffee / caffeine · 3 cups', 'Alcohol · 1 drinks'],
      caffeineCups: 3,
      alcoholGlasses: 1,
      sleepDuration: 7.5,
    ),

    // 2026-09-07: night_wakings:Moderate, fatigue:Severe, hot_flash:Mild | stress=Moderate, alcohol=2 | 7.5
    createLog(
      date: DateTime(2026, 9, 7),
      symptoms: [
        nightWakings('Moderate'),
        fatigue('Severe'),
        hotFlash('Mild'),
      ],
      triggers: ['Stress · Moderate', 'Alcohol · 2 drinks'],
      alcoholGlasses: 2,
      stressLevel: 'Moderate',
      sleepDuration: 7.5,
    ),

    // 2026-09-08: fatigue:Mild, difficulty_falling_asleep:Moderate | exercise=10 min | 7.5
    // Legacy exercise: stored under BOTH old and new key
    createLog(
      date: DateTime(2026, 9, 8),
      symptoms: [
        fatigue('Mild'),
        difficultyFallingAsleep('Moderate'),
      ],
      triggers: ['Exercise · 10 min', 'workout · 10 min'],
      sleepDuration: 7.5,
    ),

    // 2026-09-09: night_wakings:Mild, night_sweats:Severe(10m), difficulty_falling_asleep:Moderate | weather=High, exercise=5 min | 7.5
    // Legacy exercise: stored under BOTH old and new key
    createLog(
      date: DateTime(2026, 9, 9),
      symptoms: [
        nightWakings('Mild'),
        nightSweats('Severe', durationMinutes: 10),
        difficultyFallingAsleep('Moderate'),
      ],
      triggers: ['warm_environment · High', 'Exercise · 5 min', 'workout · 5 min'],
      sleepDuration: 7.5,
    ),

    // 2026-09-10: fatigue:Mild, night_sweats:Moderate(5m) | coffee=3, alcohol=1 | 7.5
    createLog(
      date: DateTime(2026, 9, 10),
      symptoms: [
        fatigue('Mild'),
        nightSweats('Moderate', durationMinutes: 5),
      ],
      triggers: ['Coffee / caffeine · 3 cups', 'Alcohol · 1 drinks'],
      caffeineCups: 3,
      alcoholGlasses: 1,
      sleepDuration: 7.5,
    ),

    // 2026-09-11: night_wakings:Severe, fatigue:Moderate | alcohol=2, coffee=2 | 7.5
    createLog(
      date: DateTime(2026, 9, 11),
      symptoms: [
        nightWakings('Severe'),
        fatigue('Moderate'),
      ],
      triggers: ['Alcohol · 2 drinks', 'Coffee / caffeine · 2 cups'],
      alcoholGlasses: 2,
      caffeineCups: 2,
      sleepDuration: 7.5,
    ),

    // 2026-09-12: hot_flash:Moderate(10m), fatigue:Moderate, night_sweats:Severe(10m) | alcohol=3, stress=High | 7.5
    createLog(
      date: DateTime(2026, 9, 12),
      symptoms: [
        hotFlash('Moderate', durationMinutes: 10),
        fatigue('Moderate'),
        nightSweats('Severe', durationMinutes: 10),
      ],
      triggers: ['Alcohol · 3 drinks', 'Stress · High'],
      alcoholGlasses: 3,
      stressLevel: 'High',
      sleepDuration: 7.5,
    ),

    // 2026-09-13: fatigue:Severe, night_sweats:Moderate(10m), hot_flash:Moderate(10m) | alcohol=2, coffee=2 | 7.5
    createLog(
      date: DateTime(2026, 9, 13),
      symptoms: [
        fatigue('Severe'),
        nightSweats('Moderate', durationMinutes: 10),
        hotFlash('Moderate', durationMinutes: 10),
      ],
      triggers: ['Alcohol · 2 drinks', 'Coffee / caffeine · 2 cups'],
      alcoholGlasses: 2,
      caffeineCups: 2,
      sleepDuration: 7.5,
    ),

    // 2026-09-14: hot_flash:Moderate(5m), fatigue:Moderate, night_wakings:Mild | exercise=5, stress=High | 7.5
    createLog(
      date: DateTime(2026, 9, 14),
      symptoms: [
        hotFlash('Moderate', durationMinutes: 5),
        fatigue('Moderate'),
        nightWakings('Mild'),
      ],
      triggers: ['Exercise · 5 min', 'Stress · High'],
      stressLevel: 'High',
      sleepDuration: 7.5,
    ),

    // 2026-09-15: fatigue:Moderate, night_sweats:Severe(10m), night_wakings:Moderate, hot_flash:Mild(15m) | alcohol=2 glasses, exercise=5, stress=High, coffee=2 | 7.0
    createLog(
      date: DateTime(2026, 9, 15),
      symptoms: [
        fatigue('Moderate'),
        nightSweats('Severe', durationMinutes: 10),
        nightWakings('Moderate'),
        hotFlash('Mild', durationMinutes: 15),
      ],
      triggers: [
        'Alcohol · 2 glasses',
        'Exercise · 5 min',
        'Stress · High',
        'Coffee / caffeine · 2 cups',
      ],
      alcoholGlasses: 2,
      caffeineCups: 2,
      stressLevel: 'High',
      sleepDuration: 7.0,
    ),

    // 2026-09-16: hot_flash:Moderate(5m), fatigue:Moderate, night_sweats:Mild(15m) | stress=Moderate, alcohol=3 glasses, coffee=2 | 7.0
    createLog(
      date: DateTime(2026, 9, 16),
      symptoms: [
        hotFlash('Moderate', durationMinutes: 5),
        fatigue('Moderate'),
        nightSweats('Mild', durationMinutes: 15),
      ],
      triggers: [
        'Stress · Moderate',
        'Alcohol · 3 glasses',
        'Coffee / caffeine · 2 cups',
      ],
      alcoholGlasses: 3,
      caffeineCups: 2,
      stressLevel: 'Moderate',
      sleepDuration: 7.0,
    ),

    // 2026-09-17: hot_flash:Moderate(5m), fatigue:Moderate, night_sweats:Severe(5m) | coffee=1, alcohol=3 drinks | 8.5
    createLog(
      date: DateTime(2026, 9, 17),
      symptoms: [
        hotFlash('Moderate', durationMinutes: 5),
        fatigue('Moderate'),
        nightSweats('Severe', durationMinutes: 5),
      ],
      triggers: [
        'Coffee / caffeine · 1 cups',
        'Alcohol · 3 drinks',
      ],
      caffeineCups: 1,
      alcoholGlasses: 3,
      sleepDuration: 8.5,
    ),

    // 2026-09-18: hot_flash:Moderate(5m), fatigue:Moderate, night_sweats:Severe(10m) | coffee=2, alcohol=1, stress=High | 7.5
    createLog(
      date: DateTime(2026, 9, 18),
      symptoms: [
        hotFlash('Moderate', durationMinutes: 5),
        fatigue('Moderate'),
        nightSweats('Severe', durationMinutes: 10),
      ],
      triggers: [
        'Coffee / caffeine · 2 cups',
        'Alcohol · 1 drinks',
        'Stress · High',
      ],
      caffeineCups: 2,
      alcoholGlasses: 1,
      stressLevel: 'High',
      sleepDuration: 7.5,
    ),

    // 2026-09-19: hot_flash:Mild(10m), fatigue:Severe, night_wakings:Moderate | stress=Moderate, alcohol=2, coffee=3 | 7.5
    createLog(
      date: DateTime(2026, 9, 19),
      symptoms: [
        hotFlash('Mild', durationMinutes: 10),
        fatigue('Severe'),
        nightWakings('Moderate'),
      ],
      triggers: [
        'Stress · Moderate',
        'Alcohol · 2 drinks',
        'Coffee / caffeine · 3 cups',
      ],
      alcoholGlasses: 2,
      caffeineCups: 3,
      stressLevel: 'Moderate',
      sleepDuration: 7.5,
    ),
  ];
}

// ---------------------------------------------------------------------------
// HRT setup for G
// ---------------------------------------------------------------------------

/// Dose change on 2026-09-13 at 18:45: Estradiol 2 → 4 pumps.
/// The medication this change points to NO LONGER EXISTS in the medication list (orphan).
List<HrtDoseChange> goldenHrtDoseChanges() {
  return [
    HrtDoseChange(
      id: 'dc_orphan_1',
      userId: 'test_user',
      medicationId: 'med_deleted', // This medication no longer exists → orphan
      medicationName: 'Estradiol gel (deleted)',
      oldDose: 2,
      newDose: 4,
      unit: 'pumps',
      changeDate: DateTime(2026, 9, 13, 18, 45),
      changeType: RegimenChangeType.doseChange,
    ),
  ];
}

/// Medications started on 2026-09-13 (except FemSeven which started 07 Sep).
///
/// - Estradiol (gel, 1 pump, daily) — started 13 Sep
/// - Oestrogel (gel, 2 pumps, twice weekly on Mon & Thu) — started 13 Sep
/// - Evorel (patch, 100 mcg, weekly on Sun) — started 13 Sep
/// - Estradot (patch, 50 mcg, as needed) — started 13 Sep
/// - FemSeven (patch, 50 mcg, daily) — started 7 Sep, stopped 9 Sep
List<Medication> goldenMedications() {
  return [
    Medication(
      id: 'med_estradiol',
      name: 'Estradiol',
      type: MedicationType.gel,
      dose: 1,
      unit: 'pump',
      frequency: 'Daily',
      startedAt: DateTime(2026, 9, 13),
    ),
    Medication(
      id: 'med_oestrogel',
      name: 'Oestrogel',
      type: MedicationType.gel,
      dose: 2,
      unit: 'pumps',
      frequency: 'Twice weekly',
      selectedWeekdays: [1, 4], // Monday, Thursday
      startedAt: DateTime(2026, 9, 13),
    ),
    Medication(
      id: 'med_evorel',
      name: 'Evorel',
      type: MedicationType.patch,
      dose: 100,
      unit: 'mcg',
      frequency: 'Weekly',
      selectedWeekdays: [7], // Sunday
      startedAt: DateTime(2026, 9, 13),
    ),
    Medication(
      id: 'med_estradot',
      name: 'Estradot',
      type: MedicationType.patch,
      dose: 50,
      unit: 'mcg',
      frequency: 'As needed',
      startedAt: DateTime(2026, 9, 13),
    ),
    Medication(
      id: 'med_femseven',
      name: 'FemSeven',
      type: MedicationType.patch,
      dose: 50,
      unit: 'mcg',
      frequency: 'Daily',
      startedAt: DateTime(2026, 9, 7),
      endedAt: DateTime(2026, 9, 9),
    ),
  ];
}

// ---------------------------------------------------------------------------
// Robustness utilities
// ---------------------------------------------------------------------------

/// Deep-copies a list of logs for mutation tests.
List<DailyLog> copyLogs(List<DailyLog> logs) {
  return logs.map((l) => l.copyWith()).toList();
}

/// Shuffles log order for determinism tests (returns a new shuffled list).
List<DailyLog> shuffleLogs(List<DailyLog> logs, [int seed = 42]) {
  final copy = List<DailyLog>.from(logs);
  copy.shuffle(Random(seed));
  return copy;
}
