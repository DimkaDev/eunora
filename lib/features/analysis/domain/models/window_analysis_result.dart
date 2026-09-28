import 'package:eunora/features/analysis/domain/models/analysis_period.dart';
import 'package:eunora/features/analysis/domain/models/day_analysis_picture.dart';
import 'package:eunora/features/analysis/domain/models/period_comparison.dart';
import 'package:eunora/features/analysis/domain/models/symptom_metric.dart';
import 'package:eunora/features/analysis/domain/models/chart_series.dart';

class WindowAnalysisResult {
  final AnalysisPeriod period;
  final DateTime windowStart;
  final DateTime windowEnd;
  final int calendarDaysInWindow;
  final int loggedDaysCount;
  final int symptomFreeDaysCount;
  final double coverage; // loggedDays ÷ calendarDays in window
  final double consistency; // loggedDays in trailing 7 days ÷ days in trailing 7 days (clamped to account age)
  final bool isHistoryClamped; // true if history < period window
  final int? daysOfData; // count of calendar days since first log when history < window

  final double? averageSeverity; // mean over present symptom records in window (SD-3)
  final String? severityLabel; // Mild, Moderate, Severe
  final String? severityDisplay; // e.g. "Moderate · 3.1 / 5"
  final MetricComparison? severityComparison; // comparison to previous window
  final MetricComparison? calendarWeekComparison; // Mon-K vs Mon-K of previous week

  final List<SymptomAnalysisMetric> symptomRankings; // ties broken alphabetically by identifier
  final Map<String, SymptomAnalysisMetric> symptomsMap;

  final AnalysisChartSeries chartSeries;

  final bool isSleepTrusted; // SD-6: false if >= 70% of logged days share identical sleep value
  final double? averageSleepHours;
  final double identicalSleepPercent;

  final List<DayAnalysisPicture> dailyPictures;
  final List<DayAnalysisPicture>? previousWindowPictures;

  const WindowAnalysisResult({
    required this.period,
    required this.windowStart,
    required this.windowEnd,
    required this.calendarDaysInWindow,
    required this.loggedDaysCount,
    required this.symptomFreeDaysCount,
    required this.coverage,
    required this.consistency,
    required this.isHistoryClamped,
    this.daysOfData,
    this.averageSeverity,
    this.severityLabel,
    this.severityDisplay,
    this.severityComparison,
    this.calendarWeekComparison,
    required this.symptomRankings,
    required this.symptomsMap,
    required this.chartSeries,
    required this.isSleepTrusted,
    this.averageSleepHours,
    required this.identicalSleepPercent,
    required this.dailyPictures,
    this.previousWindowPictures,
  });

  Map<String, dynamic> toMap() => {
        'period': period.name,
        'windowStart': windowStart.toIso8601String(),
        'windowEnd': windowEnd.toIso8601String(),
        'calendarDaysInWindow': calendarDaysInWindow,
        'loggedDaysCount': loggedDaysCount,
        'symptomFreeDaysCount': symptomFreeDaysCount,
        'coverage': coverage,
        'consistency': consistency,
        'isHistoryClamped': isHistoryClamped,
        'daysOfData': daysOfData,
        'averageSeverity': averageSeverity,
        'severityLabel': severityLabel,
        'severityDisplay': severityDisplay,
        'severityComparison': severityComparison?.toMap(),
        'symptomRankings': symptomRankings.map((s) => s.toMap()).toList(),
        'chartSeries': chartSeries.toMap(),
        'isSleepTrusted': isSleepTrusted,
        'averageSleepHours': averageSleepHours,
        'identicalSleepPercent': identicalSleepPercent,
        'dailyPictures': dailyPictures.map((d) => d.toMap()).toList(),
      };
}
