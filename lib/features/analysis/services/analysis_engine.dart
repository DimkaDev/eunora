import 'dart:math' as math;

import '../../home/domain/entities/daily_log.dart';
import '../domain/models/analysis_period.dart';
import '../domain/models/chart_series.dart';
import '../domain/models/day_analysis_picture.dart';
import '../domain/models/period_comparison.dart';
import '../domain/models/symptom_metric.dart';
import '../domain/models/window_analysis_result.dart';
import '../../symptom_log/data/symptom_library.dart';
import 'symptom_categorizer.dart';
import 'trigger_normalizer.dart';

/// Single shared analysis engine producing deterministic analytics across all surfaces.
class AnalysisEngine {
  final TriggerNormalizer triggerNormalizer;
  final SymptomCategorizer symptomCategorizer;

  const AnalysisEngine({
    this.triggerNormalizer = const TriggerNormalizer(),
    this.symptomCategorizer = const SymptomCategorizer(),
  });

  /// Normalizes a DateTime to calendar date (00:00:00).
  static DateTime normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Add days using calendar arithmetic to prevent DST shifting.
  static DateTime addDays(DateTime dt, int days) {
    return DateTime(dt.year, dt.month, dt.day + days);
  }

  /// Returns the SD-3 severity label for a score: below 2 = Mild, 2 to <4 = Moderate, 4+ = Severe.
  static String severityLabelForScore(double score) {
    if (score < 2.0) return 'Mild';
    if (score < 4.0) return 'Moderate';
    return 'Severe';
  }

  /// Calculates inclusive calendar days between [start] and [end] in a DST-safe manner.
  static int calendarDaysBetween(DateTime start, DateTime end) {
    final s = normalizeDate(start);
    final e = normalizeDate(end);
    if (e.isBefore(s)) return 0;
    // Midday UTC difference is immune to local daylight saving time transitions
    final sUtc = DateTime.utc(s.year, s.month, s.day, 12);
    final eUtc = DateTime.utc(e.year, e.month, e.day, 12);
    return eUtc.difference(sUtc).inDays + 1;
  }

  /// Analyzes a single day given an optional [DailyLog] and context dates.
  DayAnalysisPicture analyzeDay(
    DailyLog? log,
    DateTime date, {
    required DateTime today,
  }) {
    final normalizedDate = normalizeDate(date);
    final normalizedToday = normalizeDate(today);

    // Unlogged or pending
    if (log == null || !log.isCompleted) {
      final status = (normalizedDate == normalizedToday)
          ? DayStatus.pending
          : DayStatus.notLogged;

      return DayAnalysisPicture(
        date: normalizedDate,
        status: status,
        symptomScores: const {},
        symptomsWithoutSeverity: const {},
        isSymptomFree: false,
        dayLevel: null,
        triggers: const {},
        sleepHours: null,
        hrtIntakes: const [],
      );
    }

    // Completed log
    final triggers = triggerNormalizer.normalizeTriggers(log);
    final Map<String, double> symptomScores = {};
    final Set<String> symptomsWithoutSeverity = {};

    for (final loggedSymptom in log.symptoms) {
      final key = loggedSymptom.symptom.id.isNotEmpty
          ? loggedSymptom.symptom.id
          : loggedSymptom.symptom.name;

      final score = _normalizeSymptomScore(loggedSymptom);
      if (score != null) {
        symptomScores[key] = score;
      } else {
        symptomsWithoutSeverity.add(key);
      }
    }

    // Symptom-free check
    final bool hasNoSymptoms = log.symptoms.isEmpty;
    final bool allZero = symptomScores.isNotEmpty &&
        symptomScores.values.every((score) => score == 0.0) &&
        symptomsWithoutSeverity.isEmpty;
    final bool isSymptomFree = hasNoSymptoms || allZero;

    double? dayLevel;
    if (isSymptomFree) {
      dayLevel = 0.0;
    } else if (symptomScores.isNotEmpty) {
      // Mean score of present symptoms with score
      final sum = symptomScores.values.reduce((a, b) => a + b);
      dayLevel = sum / symptomScores.length;
    } else {
      // Symptoms present but none have a severity score
      dayLevel = null;
    }

    return DayAnalysisPicture(
      date: normalizedDate,
      status: DayStatus.logged,
      symptomScores: symptomScores,
      symptomsWithoutSeverity: symptomsWithoutSeverity,
      isSymptomFree: isSymptomFree,
      dayLevel: dayLevel,
      triggers: triggers,
      sleepHours: log.sleepDuration,
      hrtIntakes: log.hrtIntakes,
    );
  }

  /// Normalizes symptom score to 0–5 scale per SD-3.
  /// Mild = 1, Moderate = 3, Severe = 5.
  /// Numeric intensity (0–10) normalized onto 0–5 scale: intensity / 2.0.
  /// Returns null if symptom is present without severity.
  double? _normalizeSymptomScore(dynamic loggedSymptom) {
    // If severity string exists
    final severity = loggedSymptom.severity?.toString().trim().toLowerCase();
    if (severity != null && severity.isNotEmpty) {
      switch (severity) {
        case 'mild':
          return 1.0;
        case 'moderate':
          return 3.0;
        case 'severe':
          return 5.0;
      }
    }

    // If numeric intensity (0-10) exists
    final intensity = loggedSymptom.intensity as int?;
    if (intensity != null) {
      return (intensity / 2.0).clamp(0.0, 5.0);
    }

    return null;
  }

  /// Primary entry point: computes complete [WindowAnalysisResult] for a given period.
  WindowAnalysisResult analyzeWindow({
    required List<DailyLog> logs,
    required AnalysisPeriod period,
    DateTime? today,
    DateTime? accountCreatedDate,
  }) {
    final referenceToday = normalizeDate(today ?? DateTime.now());

    // Filter completed logs and map by normalized date (keeping newest if duplicate)
    final Map<DateTime, DailyLog> logsByDate = {};
    for (final log in logs) {
      if (!log.isCompleted) continue;
      final d = normalizeDate(log.date);
      if (!logsByDate.containsKey(d) || log.createdAt.isAfter(logsByDate[d]!.createdAt)) {
        logsByDate[d] = log;
      }
    }

    // Determine window boundaries
    final defaultWindowStart = addDays(referenceToday, -(period.days - 1));
    final defaultWindowEnd = referenceToday;

    DateTime? earliestLogDate;
    if (logsByDate.isNotEmpty) {
      earliestLogDate = logsByDate.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    }

    final bool isHistoryClamped = earliestLogDate != null &&
        earliestLogDate.isAfter(defaultWindowStart);

    final DateTime windowStart = isHistoryClamped ? earliestLogDate! : defaultWindowStart;
    final DateTime windowEnd = defaultWindowEnd;
    final int calendarDaysInWindow = calendarDaysBetween(windowStart, windowEnd);
    final int? daysOfData = isHistoryClamped
        ? calendarDaysInWindow
        : (earliestLogDate != null ? period.days : null);

    // Build daily pictures for current window
    final List<DayAnalysisPicture> dailyPictures = [];
    DateTime cursor = windowStart;
    while (!cursor.isAfter(windowEnd)) {
      final log = logsByDate[cursor];
      dailyPictures.add(analyzeDay(log, cursor, today: referenceToday));
      cursor = addDays(cursor, 1);
    }

    final loggedDays = dailyPictures.where((p) => p.isLogged).toList();
    final loggedDaysCount = loggedDays.length;
    final symptomFreeDaysCount = loggedDays.where((p) => p.isSymptomFree).length;

    // SD-2 Coverage: loggedDays ÷ calendarDays
    final double coverage = calendarDaysInWindow > 0
        ? (loggedDaysCount / calendarDaysInWindow)
        : 0.0;

    // SD-2 Consistency: trailing 7 days consistency clamped to account age or earliest data
    final DateTime trailingStart = addDays(referenceToday, -6);
    DateTime effectiveTrailingStart = trailingStart;
    if (accountCreatedDate != null) {
      final normAccountCreated = normalizeDate(accountCreatedDate);
      if (normAccountCreated.isAfter(effectiveTrailingStart)) {
        effectiveTrailingStart = normAccountCreated;
      }
    } else if (earliestLogDate != null && earliestLogDate.isAfter(effectiveTrailingStart)) {
      effectiveTrailingStart = earliestLogDate;
    }

    final int trailingDaysCount = calendarDaysBetween(effectiveTrailingStart, referenceToday);
    int trailingLoggedCount = 0;
    DateTime trailingCursor = effectiveTrailingStart;
    while (!trailingCursor.isAfter(referenceToday)) {
      if (logsByDate.containsKey(trailingCursor)) {
        trailingLoggedCount++;
      }
      trailingCursor = addDays(trailingCursor, 1);
    }
    final double consistency = trailingDaysCount > 0
        ? (trailingLoggedCount / trailingDaysCount)
        : 0.0;

    // SD-3 Average severity: mean over present symptom records in window (absent = not counted)
    double? averageSeverity;
    String? severityLabel;
    String? severityDisplay;

    int totalPresentWithSeverityCount = 0;
    double totalSeverityScoreSum = 0.0;

    for (final day in loggedDays) {
      for (final score in day.symptomScores.values) {
        if (score > 0.0) {
          totalSeverityScoreSum += score;
          totalPresentWithSeverityCount++;
        }
      }
    }

    if (totalPresentWithSeverityCount > 0) {
      averageSeverity = totalSeverityScoreSum / totalPresentWithSeverityCount;
      if (averageSeverity < 2.0) {
        severityLabel = 'Mild';
      } else if (averageSeverity < 4.0) {
        severityLabel = 'Moderate';
      } else {
        severityLabel = 'Severe';
      }
      severityDisplay = '$severityLabel · ${averageSeverity.toStringAsFixed(1)} / 5';
    }

    // Previous window calculation (if eligible)
    List<DayAnalysisPicture>? previousWindowPictures;
    double? prevAverageSeverity;
    final Map<String, double> prevSymptomBurdens = {};
    int prevLoggedCount = 0;

    if (!isHistoryClamped && period != AnalysisPeriod.day1) {
      final prevEnd = addDays(windowStart, -1);
      final prevStart = addDays(prevEnd, -(period.days - 1));

      previousWindowPictures = [];
      DateTime prevCursor = prevStart;
      while (!prevCursor.isAfter(prevEnd)) {
        final log = logsByDate[prevCursor];
        previousWindowPictures.add(analyzeDay(log, prevCursor, today: referenceToday));
        prevCursor = addDays(prevCursor, 1);
      }

      final prevLoggedDays = previousWindowPictures.where((p) => p.isLogged).toList();
      prevLoggedCount = prevLoggedDays.length;

      int prevPresentWithSeverityCount = 0;
      double prevSeverityScoreSum = 0.0;
      final Map<String, double> prevSymptomDailyScoreSums = {};

      for (final day in prevLoggedDays) {
        for (final entry in day.symptomScores.entries) {
          prevSymptomDailyScoreSums[entry.key] =
              (prevSymptomDailyScoreSums[entry.key] ?? 0.0) + entry.value;
          if (entry.value > 0.0) {
            prevSeverityScoreSum += entry.value;
            prevPresentWithSeverityCount++;
          }
        }
      }

      if (prevPresentWithSeverityCount > 0) {
        prevAverageSeverity = prevSeverityScoreSum / prevPresentWithSeverityCount;
      }

      if (prevLoggedCount > 0) {
        for (final entry in prevSymptomDailyScoreSums.entries) {
          prevSymptomBurdens[entry.key] = entry.value / prevLoggedCount;
        }
      }
    }

    // Comparison minimums evaluation
    final MetricComparison? severityComparison = _evaluateComparison(
      period: period,
      isHistoryClamped: isHistoryClamped,
      currentLoggedCount: loggedDaysCount,
      prevLoggedCount: prevLoggedCount,
      currentValue: averageSeverity,
      previousValue: prevAverageSeverity,
    );

    // Collect all symptom IDs present in logged days of current window
    final Set<String> allWindowSymptomIds = {};
    for (final day in loggedDays) {
      allWindowSymptomIds.addAll(day.symptomScores.keys);
      allWindowSymptomIds.addAll(day.symptomsWithoutSeverity);
    }

    // Build per-symptom metrics
    final List<SymptomAnalysisMetric> symptomMetrics = [];
    final Map<String, SymptomAnalysisMetric> symptomsMap = {};

    for (final symptomId in allWindowSymptomIds) {
      int daysPresent = 0;
      double sumDailyScores = 0.0;
      int presentWithSeverityCount = 0;
      double presentSeverityScoreSum = 0.0;

      for (final day in loggedDays) {
        final score = day.symptomScores[symptomId];
        final withoutSeverity = day.symptomsWithoutSeverity.contains(symptomId);

        if ((score != null && score > 0.0) || withoutSeverity) {
          daysPresent++;
        }

        if (score != null) {
          sumDailyScores += score;
          if (score > 0.0) {
            presentSeverityScoreSum += score;
            presentWithSeverityCount++;
          }
        }
      }

      final dayRate = loggedDaysCount > 0 ? (daysPresent / loggedDaysCount) : 0.0;
      final burden = loggedDaysCount > 0 ? (sumDailyScores / loggedDaysCount) : 0.0;

      double? symptomAvgSeverity;
      String? symptomSevLabel;
      if (presentWithSeverityCount > 0) {
        symptomAvgSeverity = presentSeverityScoreSum / presentWithSeverityCount;
        if (symptomAvgSeverity < 2.0) {
          symptomSevLabel = 'Mild';
        } else if (symptomAvgSeverity < 4.0) {
          symptomSevLabel = 'Moderate';
        } else {
          symptomSevLabel = 'Severe';
        }
      }

      // Symptom burden comparison to previous window
      final prevBurden = prevSymptomBurdens[symptomId] ?? 0.0;
      final symptomComparison = _evaluateComparison(
        period: period,
        isHistoryClamped: isHistoryClamped,
        currentLoggedCount: loggedDaysCount,
        prevLoggedCount: prevLoggedCount,
        currentValue: burden,
        previousValue: prevBurden,
      );

      final category = symptomCategorizer.getCategory(symptomId).displayName;
      final displayName = symptomCategorizer.getLabel(symptomId);

      final metric = SymptomAnalysisMetric(
        symptomId: symptomId,
        displayName: displayName,
        category: category,
        daysPresent: daysPresent,
        dayRate: dayRate,
        burden: burden,
        averageSeverity: symptomAvgSeverity,
        severityLabel: symptomSevLabel,
        comparison: symptomComparison,
      );

      symptomMetrics.add(metric);
    }

    // Rank symptoms:
    // 1) dayRate descending
    // 2) burden descending
    // 3) alphabetical by symptomId
    symptomMetrics.sort((a, b) {
      final rateComp = b.dayRate.compareTo(a.dayRate);
      if (rateComp != 0) return rateComp;

      final burdenComp = b.burden.compareTo(a.burden);
      if (burdenComp != 0) return burdenComp;

      return a.symptomId.toLowerCase().compareTo(b.symptomId.toLowerCase());
    });

    final List<SymptomAnalysisMetric> rankedSymptoms = [];
    for (int i = 0; i < symptomMetrics.length; i++) {
      final ranked = symptomMetrics[i].copyWith(ranking: i + 1);
      rankedSymptoms.add(ranked);
      symptomsMap[ranked.symptomId] = ranked;
    }

    // Chart series construction
    final chartSeries = _buildChartSeries(
      period: period,
      windowStart: windowStart,
      windowEnd: windowEnd,
      dailyPictures: dailyPictures,
    );

    // Sleep trust gate (SD-6)
    final sleepAnalysis = _evaluateSleepTrust(loggedDays);

    // Calendar-week partial comparison
    final calendarWeekComparison = compareCalendarWeeks(
      logs: logs,
      today: referenceToday,
    );

    return WindowAnalysisResult(
      period: period,
      windowStart: windowStart,
      windowEnd: windowEnd,
      calendarDaysInWindow: calendarDaysInWindow,
      loggedDaysCount: loggedDaysCount,
      symptomFreeDaysCount: symptomFreeDaysCount,
      coverage: coverage,
      consistency: consistency,
      isHistoryClamped: isHistoryClamped,
      daysOfData: daysOfData,
      averageSeverity: averageSeverity,
      severityLabel: severityLabel,
      severityDisplay: severityDisplay,
      severityComparison: severityComparison,
      calendarWeekComparison: calendarWeekComparison,
      symptomRankings: rankedSymptoms,
      symptomsMap: symptomsMap,
      chartSeries: chartSeries,
      isSleepTrusted: sleepAnalysis.isTrusted,
      averageSleepHours: sleepAnalysis.averageHours,
      identicalSleepPercent: sleepAnalysis.identicalPercent,
      dailyPictures: dailyPictures,
      previousWindowPictures: previousWindowPictures,
    );
  }

  /// Evaluates period comparison minimums and builds [MetricComparison].
  MetricComparison? _evaluateComparison({
    required AnalysisPeriod period,
    required bool isHistoryClamped,
    required int currentLoggedCount,
    required int prevLoggedCount,
    required double? currentValue,
    required double? previousValue,
  }) {
    if (period == AnalysisPeriod.day1) {
      return MetricComparison.notEnoughData(
        NotEnoughDataReason.singleDayPeriod,
        currentValue: currentValue,
      );
    }

    if (isHistoryClamped) {
      return MetricComparison.notEnoughData(
        NotEnoughDataReason.historyShorterThanWindow,
        currentValue: currentValue,
      );
    }

    final minRequired = period.minLoggedDaysRequired;
    final bool currentMeets = currentLoggedCount >= minRequired;
    final bool prevMeets = prevLoggedCount >= minRequired;

    if (!currentMeets && !prevMeets) {
      return MetricComparison.notEnoughData(
        NotEnoughDataReason.notEnoughDataBoth,
        currentValue: currentValue,
      );
    }
    if (!currentMeets) {
      return MetricComparison.notEnoughData(
        NotEnoughDataReason.notEnoughDataCurrent,
        currentValue: currentValue,
      );
    }
    if (!prevMeets) {
      return MetricComparison.notEnoughData(
        NotEnoughDataReason.notEnoughDataPrevious,
        currentValue: currentValue,
      );
    }

    // Both meet minimum required days
    final curr = currentValue ?? 0.0;
    final prev = previousValue ?? 0.0;
    return MetricComparison.evaluate(
      current: curr,
      previous: prev,
      lowerIsBetter: true,
    );
  }

  /// Calendar-week comparison (Mon–K vs Mon–K of previous week).
  MetricComparison compareCalendarWeeks({
    required List<DailyLog> logs,
    DateTime? today,
  }) {
    final refToday = normalizeDate(today ?? DateTime.now());
    final int weekday = refToday.weekday; // 1 = Monday, 7 = Sunday

    final currentMonday = addDays(refToday, -(weekday - 1));
    final prevMonday = addDays(currentMonday, -7);
    final prevSameWeekday = addDays(prevMonday, weekday - 1);

    final Map<DateTime, DailyLog> logsByDate = {};
    for (final log in logs) {
      if (!log.isCompleted) continue;
      final d = normalizeDate(log.date);
      if (!logsByDate.containsKey(d) || log.createdAt.isAfter(logsByDate[d]!.createdAt)) {
        logsByDate[d] = log;
      }
    }

    // Gather current partial week logged day levels
    final List<double> currentLevels = [];
    DateTime curr = currentMonday;
    while (!curr.isAfter(refToday)) {
      final log = logsByDate[curr];
      if (log != null) {
        final pic = analyzeDay(log, curr, today: refToday);
        if (pic.dayLevel != null) currentLevels.add(pic.dayLevel!);
      }
      curr = addDays(curr, 1);
    }

    // Gather previous partial week logged day levels
    final List<double> prevLevels = [];
    DateTime prev = prevMonday;
    while (!prev.isAfter(prevSameWeekday)) {
      final log = logsByDate[prev];
      if (log != null) {
        final pic = analyzeDay(log, prev, today: refToday);
        if (pic.dayLevel != null) prevLevels.add(pic.dayLevel!);
      }
      prev = addDays(prev, 1);
    }

    if (currentLevels.isEmpty && prevLevels.isEmpty) {
      return MetricComparison.notEnoughData(NotEnoughDataReason.notEnoughDataBoth);
    }
    if (currentLevels.isEmpty) {
      return MetricComparison.notEnoughData(NotEnoughDataReason.notEnoughDataCurrent);
    }
    if (prevLevels.isEmpty) {
      return MetricComparison.notEnoughData(NotEnoughDataReason.notEnoughDataPrevious);
    }

    final currentMean = currentLevels.reduce((a, b) => a + b) / currentLevels.length;
    final prevMean = prevLevels.reduce((a, b) => a + b) / prevLevels.length;

    return MetricComparison.evaluate(
      current: currentMean,
      previous: prevMean,
      lowerIsBetter: true,
    );
  }

  /// Builds chart series preserving null gaps for unlogged days / weeks.
  AnalysisChartSeries _buildChartSeries({
    required AnalysisPeriod period,
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<DayAnalysisPicture> dailyPictures,
  }) {
    if (period == AnalysisPeriod.days90) {
      // Monday-based weekly series
      final DateTime firstMonday = addDays(windowStart, -(windowStart.weekday - 1));
      final List<AnalysisChartPoint> points = [];

      DateTime currentMon = firstMonday;
      while (!currentMon.isAfter(windowEnd)) {
        final currentSun = addDays(currentMon, 6);

        final weekDays = dailyPictures.where((p) =>
            !p.date.isBefore(currentMon) &&
            !p.date.isAfter(currentSun) &&
            p.isLogged &&
            p.dayLevel != null).toList();

        if (weekDays.isEmpty) {
          points.add(AnalysisChartPoint(date: currentMon, value: null));
        } else {
          final mean = weekDays.map((p) => p.dayLevel!).reduce((a, b) => a + b) / weekDays.length;
          points.add(AnalysisChartPoint(date: currentMon, value: mean));
        }

        currentMon = addDays(currentMon, 7);
      }

      return AnalysisChartSeries(
        period: period,
        points: points,
        isWeekly: true,
        label: 'Weekly Symptom Level',
      );
    }

    // 1, 7, 30 days: daily points preserving null gaps
    final List<AnalysisChartPoint> points = dailyPictures.map((pic) {
      return AnalysisChartPoint(
        date: pic.date,
        value: pic.isLogged ? pic.dayLevel : null,
      );
    }).toList();

    return AnalysisChartSeries(
      period: period,
      points: points,
      isWeekly: false,
      label: 'Daily Symptom Level',
    );
  }

  /// Evaluates sleep trust gate per SD-6.
  _SleepTrustAnalysis _evaluateSleepTrust(List<DayAnalysisPicture> loggedDays) {
    final loggedWithSleep = loggedDays.where((d) => d.sleepHours != null).toList();

    if (loggedWithSleep.isEmpty) {
      return const _SleepTrustAnalysis(
        isTrusted: true,
        averageHours: null,
        identicalPercent: 0.0,
      );
    }

    final Map<double, int> sleepCounts = {};
    double totalHours = 0.0;

    for (final day in loggedWithSleep) {
      final hours = day.sleepHours!;
      totalHours += hours;
      sleepCounts[hours] = (sleepCounts[hours] ?? 0) + 1;
    }

    final maxIdenticalCount = sleepCounts.values.reduce(math.max);
    final identicalPercent = maxIdenticalCount / loggedWithSleep.length;
    // SD-6: Suppressed when >= 70% share the identical value
    final isTrusted = identicalPercent < 0.70;
    final averageHours = totalHours / loggedWithSleep.length;

    return _SleepTrustAnalysis(
      isTrusted: isTrusted,
      averageHours: averageHours,
      identicalPercent: identicalPercent,
    );
  }
}

class _SleepTrustAnalysis {
  final bool isTrusted;
  final double? averageHours;
  final double identicalPercent;

  const _SleepTrustAnalysis({
    required this.isTrusted,
    required this.averageHours,
    required this.identicalPercent,
  });
}
