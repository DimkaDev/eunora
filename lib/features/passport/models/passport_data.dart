import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:eunora/features/insights/models/insight_result.dart';

part 'passport_data.freezed.dart';
part 'passport_data.g.dart';

@freezed
class CurrentHrtSummary with _$CurrentHrtSummary {
  const factory CurrentHrtSummary({
    required String drugName,
    required double doseValue,
    required String doseUnit,
    required String form,
    required DateTime startDate,
  }) = _CurrentHrtSummary;

  factory CurrentHrtSummary.fromJson(Map<String, dynamic> json) =>
      _$CurrentHrtSummaryFromJson(json);
}

@freezed
class SymptomStatRow with _$SymptomStatRow {
  const factory SymptomStatRow({
    required String category,
    required int daysLogged,
    required double avgSeverity,
    required DateTime? peakDay,
    required String trend, // 'Improving' | 'Stable' | 'Worsening'
  }) = _SymptomStatRow;

  factory SymptomStatRow.fromJson(Map<String, dynamic> json) =>
      _$SymptomStatRowFromJson(json);
}

@freezed
class ChartDataPoint with _$ChartDataPoint {
  const factory ChartDataPoint({
    required DateTime date,
    required double value,
  }) = _ChartDataPoint;

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) =>
      _$ChartDataPointFromJson(json);
}

@freezed
class WeeklyMoodPoint with _$WeeklyMoodPoint {
  const factory WeeklyMoodPoint({
    required DateTime weekStart,
    required double anxiety,
    required double irritability,
    required double brainFog,
  }) = _WeeklyMoodPoint;

  factory WeeklyMoodPoint.fromJson(Map<String, dynamic> json) =>
      _$WeeklyMoodPointFromJson(json);
}

@freezed
class ChartData with _$ChartData {
  const factory ChartData({
    required List<ChartDataPoint> points,
    @Default([]) List<WeeklyMoodPoint> weeklyMoods,
  }) = _ChartData;

  factory ChartData.fromJson(Map<String, dynamic> json) =>
      _$ChartDataFromJson(json);
}

@freezed
class HrtPhase with _$HrtPhase {
  const factory HrtPhase({
    required String periodLabel,
    required String drugName,
    required double dose,
    required String unit,
    required int durationDays,
    required String observedEffect,
    required bool isDoseChangeMarker,
    String? changeDirection, // 'increased' | 'decreased'
    String? changeReason,
    DateTime? changeDate,
  }) = _HrtPhase;

  factory HrtPhase.fromJson(Map<String, dynamic> json) =>
      _$HrtPhaseFromJson(json);
}

@freezed
class LogTableRow with _$LogTableRow {
  const factory LogTableRow({
    required DateTime date,
    required String time,
    required String symptomsLogged,
    required String hrtTaken,
    required String triggers,
  }) = _LogTableRow;

  factory LogTableRow.fromJson(Map<String, dynamic> json) =>
      _$LogTableRowFromJson(json);
}

@freezed
class PassportData with _$PassportData {
  const factory PassportData({
    required String displayName,
    DateTime? dateOfBirth,
    required String stage,
    required DateTime firstLogDate,
    required DateTime reportStart,
    required DateTime reportEnd,
    required int totalEntries,
    required List<CurrentHrtSummary> currentHrt,
    required List<SymptomStatRow> symptomStats,
    required ChartData hotFlashFrequency,
    required ChartData sleepQualityRollingAvg,
    required ChartData moodStackedWeekly,
    required List<InsightResult> topPatterns,
    required List<HrtPhase> hrtHistory,
    required List<LogTableRow> fullLog,
    required DateTime generatedAt,
  }) = _PassportData;

  factory PassportData.fromJson(Map<String, dynamic> json) =>
      _$PassportDataFromJson(json);
}
