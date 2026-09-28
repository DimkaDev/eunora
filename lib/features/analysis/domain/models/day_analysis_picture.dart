import 'package:eunora/features/home/domain/entities/daily_log.dart';

enum DayStatus {
  logged,
  notLogged,
  pending,
}

class NormalizedTrigger {
  final String id;
  final String displayName;
  final double? quantity;
  final String? unit;
  final String? level;
  final int? durationMinutes;

  const NormalizedTrigger({
    required this.id,
    required this.displayName,
    this.quantity,
    this.unit,
    this.level,
    this.durationMinutes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'quantity': quantity,
        'unit': unit,
        'level': level,
        'durationMinutes': durationMinutes,
      };
}

class DayAnalysisPicture {
  final DateTime date;
  final DayStatus status;

  /// Map of symptom identifier to normalized daily score on 0–5 scale (0 if absent, 1 Mild, 3 Moderate, 5 Severe).
  final Map<String, double> symptomScores;

  /// Symptoms present on this day that had no severity score assigned.
  /// Per SD-3 / requirements: counted in frequency, but excluded from severity averages.
  final Set<String> symptomsWithoutSeverity;

  /// True when the day is completed and has 0 present symptoms (or all present symptoms score 0).
  final bool isSymptomFree;

  /// The day's overall symptom level (mean score of present symptoms; 0.0 on symptom-free days; null if unlogged/pending).
  final double? dayLevel;

  /// Triggers present on this day (only present if explicitly selected by user per SD-5).
  final Map<String, NormalizedTrigger> triggers;

  /// Sleep duration in hours as recorded for the day.
  final double? sleepHours;

  /// HRT intakes recorded for the day.
  final List<HrtIntakeLog> hrtIntakes;

  const DayAnalysisPicture({
    required this.date,
    required this.status,
    required this.symptomScores,
    this.symptomsWithoutSeverity = const {},
    required this.isSymptomFree,
    required this.dayLevel,
    required this.triggers,
    required this.sleepHours,
    required this.hrtIntakes,
  });

  bool get isLogged => status == DayStatus.logged;
  bool get isPending => status == DayStatus.pending;
  bool get isNotLogged => status == DayStatus.notLogged;

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'status': status.name,
        'symptomScores': symptomScores,
        'symptomsWithoutSeverity': symptomsWithoutSeverity.toList(),
        'isSymptomFree': isSymptomFree,
        'dayLevel': dayLevel,
        'triggers': triggers.map((k, v) => MapEntry(k, v.toMap())),
        'sleepHours': sleepHours,
        'hrtIntakes': hrtIntakes.map((h) => h.toMap()).toList(),
      };
}
