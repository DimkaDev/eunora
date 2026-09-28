import 'dart:math' as math;

import '../../home/domain/entities/daily_log.dart';
import '../domain/models/analysis_period.dart';
import '../domain/models/pattern_result.dart';
import 'analysis_engine.dart';
import 'symptom_categorizer.dart';
import 'trigger_normalizer.dart';

/// Engine that identifies real, personal trigger and protective habit patterns
/// adhering to SD-1 through SD-10 with Pearson correlation and polarity guards.
class PatternEngine {
  final TriggerNormalizer triggerNormalizer;
  final SymptomCategorizer symptomCategorizer;

  const PatternEngine({
    this.triggerNormalizer = const TriggerNormalizer(),
    this.symptomCategorizer = const SymptomCategorizer(),
  });

  /// Triggers expected to worsen symptoms (only positive associations displayed).
  static const Set<String> defaultWorseningTriggers = {
    'alcohol',
    'coffee',
    'stress',
    'spicy_food',
    'sugar_processed_food',
    'hot_drinks_food',
    'skipped_meals',
    'smoking',
    'tight_clothing',
    'warm_environment',
    'poor_sleep',
    'hot_weather',
  };

  /// Habits expected to help symptoms (only negative associations displayed).
  static const Set<String> defaultProtectiveHabits = {
    'exercise',
    'exercise_30plus',
  };

  /// Analyzes logs to produce [PatternEngineResult].
  PatternEngineResult analyze({
    required List<DailyLog> logs,
    required AnalysisPeriod period,
    DateTime? today,
    Set<String> worseningTriggers = defaultWorseningTriggers,
    Set<String> protectiveHabits = defaultProtectiveHabits,
  }) {
    final referenceToday = AnalysisEngine.normalizeDate(today ?? DateTime.now());

    // Window length: longer of period and 30 days
    final int requestedDays = period.days;
    final int effectiveDays = math.max(requestedDays, 30); // 30 for 1, 7, 30; 90 for 90

    // Filter completed logs and map by normalized date (keeping newest if duplicate)
    final Map<DateTime, DailyLog> logsByDate = {};
    for (final log in logs) {
      if (!log.isCompleted) continue;
      final d = AnalysisEngine.normalizeDate(log.date);
      if (!logsByDate.containsKey(d) || log.createdAt.isAfter(logsByDate[d]!.createdAt)) {
        logsByDate[d] = log;
      }
    }

    final defaultWindowStart = AnalysisEngine.addDays(referenceToday, -(effectiveDays - 1));

    DateTime? earliestLogDate;
    if (logsByDate.isNotEmpty) {
      earliestLogDate = logsByDate.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    }

    final bool isHistoryClamped =
        earliestLogDate != null && earliestLogDate.isAfter(defaultWindowStart);
    final DateTime windowStart = isHistoryClamped ? earliestLogDate! : defaultWindowStart;
    final DateTime windowEnd = referenceToday;
    final int calendarDaysInWindow = AnalysisEngine.calendarDaysBetween(windowStart, windowEnd);

    String? windowNotice;
    if (isHistoryClamped) {
      windowNotice = 'Based on $calendarDaysInWindow days of data';
    } else if (period == AnalysisPeriod.day1 || period == AnalysisPeriod.days7) {
      windowNotice = 'Based on last 30 days';
    }

    // Filter logged days in window
    final List<DailyLog> windowLogs = [];
    DateTime cursor = windowStart;
    while (!cursor.isAfter(windowEnd)) {
      final log = logsByDate[cursor];
      if (log != null) {
        windowLogs.add(log);
      }
      cursor = AnalysisEngine.addDays(cursor, 1);
    }

    final int loggedDaysCount = windowLogs.length;

    // Collect all unique triggers present in window
    final Map<String, String> triggerDisplayNames = {};
    final Map<String, int> triggerEventCounts = {};
    int exercise30PlusCount = 0;

    for (final log in windowLogs) {
      final extracted = triggerNormalizer.extractTriggers(log);
      for (final entry in extracted.entries) {
        final id = entry.key;
        triggerDisplayNames[id] = entry.value.displayName;
        triggerEventCounts[id] = (triggerEventCounts[id] ?? 0) + 1;

        if (id == 'exercise' &&
            entry.value.durationMinutes != null &&
            entry.value.durationMinutes! >= 30) {
          exercise30PlusCount++;
        }
      }
    }

    if (exercise30PlusCount >= 7) {
      triggerDisplayNames['exercise_30plus'] = 'Exercise (30+ min)';
      triggerEventCounts['exercise_30plus'] = exercise30PlusCount;
    }

    // Gate 1: If logged days in window < 14, cannot display patterns
    if (loggedDaysCount < 14) {
      final buildingItems = _buildBuildingItems(
        triggerEventCounts: triggerEventCounts,
        triggerDisplayNames: triggerDisplayNames,
        displayableTriggerIds: const {},
      );

      return PatternEngineResult(
        requestedPeriod: period,
        effectiveDaysInWindow: calendarDaysInWindow,
        windowNotice: windowNotice,
        patterns: const [],
        buildingItems: buildingItems,
        emptyStateType: SD10EmptyType.notEnoughData,
        emptyStateMessage:
            'Not enough data yet — we need at least 14 logged days to identify patterns.',
      );
    }

    // Identify all symptom outcomes present in window
    final Set<String> symptomIds = {};
    for (final log in windowLogs) {
      for (final s in log.symptoms) {
        final id = s.symptom.id.isNotEmpty ? s.symptom.id : s.symptom.name;
        symptomIds.add(id);
      }
    }

    // Evaluate triggers against outcomes
    final List<PatternInsight> allCandidateInsights = [];
    final Set<String> triggersWithZeroComparisonDays = {};

    for (final triggerEntry in triggerDisplayNames.entries) {
      final triggerId = triggerEntry.key;
      final triggerDisplayName = triggerEntry.value;

      final bool isProtective = protectiveHabits.contains(triggerId);
      final bool isWorsening = worseningTriggers.contains(triggerId);
      if (!isProtective && !isWorsening) {
        // Must be either worsening or protective per polarity guard
        continue;
      }

      // Check if trigger has no comparison days across all logged days
      final rawEvents = triggerEventCounts[triggerId] ?? 0;
      if (rawEvents == loggedDaysCount && loggedDaysCount >= 14) {
        triggersWithZeroComparisonDays.add(triggerDisplayName);
      }

      // Candidate outcomes: each symptom + overall dayLevel
      final List<_OutcomeCandidate> outcomeCandidates = [
        ...symptomIds.map((sId) => _OutcomeCandidate(
              id: sId,
              displayName: symptomCategorizer.getLabel(sId),
              isOverallDayLevel: false,
            )),
        const _OutcomeCandidate(
          id: 'day_level',
          displayName: 'Overall day level',
          isOverallDayLevel: true,
        ),
      ];

      for (final outcome in outcomeCandidates) {
        final candidate = _evaluateTriggerOutcomePair(
          triggerId: triggerId,
          triggerDisplayName: triggerDisplayName,
          outcome: outcome,
          windowLogs: windowLogs,
          logsByDate: logsByDate,
          isProtective: isProtective,
        );

        if (candidate != null) {
          allCandidateInsights.add(candidate);
        }
      }
    }

    // Select one best headline outcome per trigger
    final Map<String, List<PatternInsight>> insightsByTrigger = {};
    for (final insight in allCandidateInsights) {
      insightsByTrigger.putIfAbsent(insight.triggerId, () => []).add(insight);
    }

    final List<PatternInsight> bestPerTriggerPatterns = [];
    final Set<String> displayableTriggerIds = {};

    for (final entry in insightsByTrigger.entries) {
      final list = entry.value;
      // Sort outcomes for this trigger:
      // 1) Specific symptom over overall day level
      // 2) Larger absolute effect
      // 3) Alphabetical by outcome display name
      list.sort((a, b) {
        if (a.isOverallDayLevel != b.isOverallDayLevel) {
          return a.isOverallDayLevel ? 1 : -1; // Specific symptom first
        }
        final effectComp = b.effect.abs().compareTo(a.effect.abs());
        if (effectComp != 0) return effectComp;

        return a.outcomeDisplayName.toLowerCase().compareTo(b.outcomeDisplayName.toLowerCase());
      });

      final best = list.first;
      final secondary = list.skip(1).toList();
      bestPerTriggerPatterns.add(best.copyWith(secondaryOutcomes: secondary));
      displayableTriggerIds.add(best.triggerId);
    }

    // Rank patterns:
    // 1) Strength descending
    // 2) Larger absolute effect
    // 3) Alphabetically by trigger display name
    bestPerTriggerPatterns.sort((a, b) {
      final strengthComp = b.strength.compareTo(a.strength);
      if (strengthComp != 0) return strengthComp;

      final effectComp = b.effect.abs().compareTo(a.effect.abs());
      if (effectComp != 0) return effectComp;

      return a.triggerDisplayName.toLowerCase().compareTo(b.triggerDisplayName.toLowerCase());
    });

    // Cap at 5 displayable patterns
    final displayablePatterns = bestPerTriggerPatterns.take(5).toList();

    // Building items: triggers with 1 <= events < 7
    final buildingItems = _buildBuildingItems(
      triggerEventCounts: triggerEventCounts,
      triggerDisplayNames: triggerDisplayNames,
      displayableTriggerIds: displayableTriggerIds,
    );

    // Determine SD-10 empty state if no patterns
    SD10EmptyType emptyType = SD10EmptyType.none;
    String? emptyMessage;

    if (displayablePatterns.isEmpty) {
      if (triggersWithZeroComparisonDays.isNotEmpty) {
        emptyType = SD10EmptyType.notEnoughVariety;
        final name = triggersWithZeroComparisonDays.first;
        emptyMessage = 'We need a few days without $name to compare.';
      } else if (buildingItems.isNotEmpty) {
        emptyType = SD10EmptyType.notEnoughData;
        emptyMessage = 'Not enough data yet — keep logging to reveal patterns.';
      } else {
        emptyType = SD10EmptyType.nothingNotable;
        emptyMessage = 'No clear patterns yet — we keep checking as you log.';
      }
    }

    return PatternEngineResult(
      requestedPeriod: period,
      effectiveDaysInWindow: calendarDaysInWindow,
      windowNotice: windowNotice,
      patterns: displayablePatterns,
      buildingItems: buildingItems,
      emptyStateType: emptyType,
      emptyStateMessage: emptyMessage,
    );
  }

  /// Builds up to 3 building items nearest to 7 events first.
  List<BuildingPatternItem> _buildBuildingItems({
    required Map<String, int> triggerEventCounts,
    required Map<String, String> triggerDisplayNames,
    required Set<String> displayableTriggerIds,
  }) {
    final List<BuildingPatternItem> items = [];

    for (final entry in triggerEventCounts.entries) {
      final id = entry.key;
      final count = entry.value;
      if (count >= 1 && count < 7 && !displayableTriggerIds.contains(id)) {
        final displayName = triggerDisplayNames[id] ?? id;
        items.add(BuildingPatternItem(
          triggerId: id,
          triggerDisplayName: displayName,
          eventsCount: count,
          targetCount: 7,
          displayText: '$displayName · $count of 7 events',
        ));
      }
    }

    // Rank nearest to threshold first (count descending), then alphabetically
    items.sort((a, b) {
      final countComp = b.eventsCount.compareTo(a.eventsCount);
      if (countComp != 0) return countComp;
      return a.triggerDisplayName.toLowerCase().compareTo(b.triggerDisplayName.toLowerCase());
    });

    return items.take(3).toList();
  }

  /// Evaluates lag 0 vs lag 1 for a single trigger-outcome pair.
  PatternInsight? _evaluateTriggerOutcomePair({
    required String triggerId,
    required String triggerDisplayName,
    required _OutcomeCandidate outcome,
    required List<DailyLog> windowLogs,
    required Map<DateTime, DailyLog> logsByDate,
    required bool isProtective,
  }) {
    final lag0Result = _computeLagCorrelation(
      triggerId: triggerId,
      outcome: outcome,
      windowLogs: windowLogs,
      logsByDate: logsByDate,
      lag: PatternLag.lag0,
      isProtective: isProtective,
    );

    final lag1Result = _computeLagCorrelation(
      triggerId: triggerId,
      outcome: outcome,
      windowLogs: windowLogs,
      logsByDate: logsByDate,
      lag: PatternLag.lag1,
      isProtective: isProtective,
    );

    if (lag0Result == null && lag1Result == null) return null;

    // Lag selection rule:
    // If lag 1 beats lag 0 by less than 0.05 in strength, lag 0 wins.
    final _LagComputation winning;
    if (lag0Result == null) {
      winning = lag1Result!;
    } else if (lag1Result == null) {
      winning = lag0Result;
    } else {
      final strength0 = lag0Result.strength;
      final strength1 = lag1Result.strength;
      if (strength1 - strength0 >= 0.05) {
        winning = lag1Result;
      } else {
        winning = lag0Result;
      }
    }

    // Gating checks on winning lag
    // At least 7 exposed events
    if (winning.eventCount < 7) return null;
    // At least 3 unexposed comparison days
    if (winning.comparisonDaysCount < 3) return null;
    // Strength of at least 30%
    if (winning.strength < 0.30) return null;

    // Polarity guard:
    // For worsening: only positive association (r > 0, effect > 0)
    // For protective: only negative association (r < 0, effect < 0)
    if (!isProtective) {
      if (winning.rawR <= 0 || winning.effect <= 0) return null;
    } else {
      if (winning.rawR >= 0 || winning.effect >= 0) return null;
    }

    final PatternType patternType =
        isProtective ? PatternType.protective : PatternType.worsening;
    final int correlationPercent = (winning.strength * 100).round();

    // Confidence: High only at >= 14 events and >= 70% correlation
    final PatternConfidence confidence =
        (winning.eventCount >= 14 && winning.strength >= 0.70)
            ? PatternConfidence.high
            : PatternConfidence.standard;

    // Headline copy per specification
    final String headlineText;
    if (isProtective) {
      headlineText =
          '$triggerDisplayName → ${outcome.displayName} tends to be milder on days you log it.';
    } else {
      headlineText =
          '$triggerDisplayName → ${outcome.displayName} tends to be stronger ${winning.lag.displayText}.';
    }

    // Evidence copy
    final String evidenceText =
        'Average ${winning.exposedAvg.toStringAsFixed(1)} vs ${winning.unexposedAvg.toStringAsFixed(1)} on other days · $correlationPercent% correlation · ${winning.eventCount} events';

    // Hit rate copy
    final String hitRateText;
    if (isProtective) {
      hitRateText =
          'You logged $triggerDisplayName on ${winning.eventCount} days. ${outcome.displayName} was lower than usual ${winning.hitRateCount} of those times.';
    } else {
      hitRateText =
          'You logged $triggerDisplayName on ${winning.eventCount} days. ${outcome.displayName} was higher than usual ${winning.hitRateCount} of those times.';
    }

    return PatternInsight(
      triggerId: triggerId,
      triggerDisplayName: triggerDisplayName,
      outcomeId: outcome.id,
      outcomeDisplayName: outcome.displayName,
      isOverallDayLevel: outcome.isOverallDayLevel,
      lag: winning.lag,
      type: patternType,
      confidence: confidence,
      rawCorrelation: winning.rawR,
      strength: winning.strength,
      correlationPercent: correlationPercent,
      effect: winning.effect,
      exposedAverage: winning.exposedAvg,
      unexposedAverage: winning.unexposedAvg,
      eventCount: winning.eventCount,
      comparisonDaysCount: winning.comparisonDaysCount,
      hitRateCount: winning.hitRateCount,
      headlineText: headlineText,
      evidenceText: evidenceText,
      hitRateText: hitRateText,
      eventDays: winning.exposedEvents,
    );
  }

  /// Computes Pearson correlation and effect for a specific lag.
  _LagComputation? _computeLagCorrelation({
    required String triggerId,
    required _OutcomeCandidate outcome,
    required List<DailyLog> windowLogs,
    required Map<DateTime, DailyLog> logsByDate,
    required PatternLag lag,
    required bool isProtective,
  }) {
    final List<double> xSeries = [];
    final List<double> ySeries = [];
    final List<PatternEventDay> exposedEvents = [];

    for (final triggerLog in windowLogs) {
      final triggerDate = AnalysisEngine.normalizeDate(triggerLog.date);

      final DateTime outcomeDate;
      if (lag == PatternLag.lag0) {
        outcomeDate = triggerDate;
      } else {
        outcomeDate = AnalysisEngine.addDays(triggerDate, 1);
      }

      // An exposure is a valid pair only if the outcome day is logged!
      final outcomeLog = logsByDate[outcomeDate];
      if (outcomeLog == null) {
        continue;
      }

      // Determine exposure X (1.0 or 0.0)
      final bool isExposed;
      if (triggerId == 'exercise_30plus') {
        final extracted = triggerNormalizer.extractTriggers(triggerLog);
        final ex = extracted['exercise'];
        isExposed = ex != null && ex.durationMinutes != null && ex.durationMinutes! >= 30;
      } else {
        final extracted = triggerNormalizer.extractTriggers(triggerLog);
        isExposed = extracted.containsKey(triggerId);
      }
      final double x = isExposed ? 1.0 : 0.0;

      // Determine outcome score Y
      final double y;
      if (outcome.isOverallDayLevel) {
        y = _extractDayLevel(outcomeLog);
      } else {
        y = _extractSymptomScore(outcomeLog, outcome.id);
      }

      xSeries.add(x);
      ySeries.add(y);
      if (isExposed) {
        exposedEvents.add(PatternEventDay(
          date: triggerDate,
          outcomeScore: y,
          isLagged: lag == PatternLag.lag1,
          outcomeDate: outcomeDate,
        ));
      }
    }

    final int n = xSeries.length;
    if (n == 0) return null;

    final List<double> yExposed = [];
    final List<double> yUnexposed = [];

    double sumX = 0.0;
    double sumY = 0.0;
    double sumXY = 0.0;
    double sumX2 = 0.0;
    double sumY2 = 0.0;

    for (int i = 0; i < n; i++) {
      final x = xSeries[i];
      final y = ySeries[i];

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumY2 += y * y;

      if (x == 1.0) {
        yExposed.add(y);
      } else {
        yUnexposed.add(y);
      }
    }

    // If no variance in X or no variance in Y, skip
    final double denominatorPart1 = (n * sumX2) - (sumX * sumX);
    final double denominatorPart2 = (n * sumY2) - (sumY * sumY);
    if (denominatorPart1 <= 0.0 || denominatorPart2 <= 0.0) {
      return null;
    }

    final double denominator = math.sqrt(denominatorPart1 * denominatorPart2);
    if (denominator == 0.0) return null;

    final double rawR = ((n * sumXY) - (sumX * sumY)) / denominator;
    if (rawR.isNaN || rawR.isInfinite) return null;

    final double clampedR = rawR.clamp(-1.0, 1.0);
    final double strength = clampedR.abs();

    final double exposedAvg =
        yExposed.isEmpty ? 0.0 : yExposed.reduce((a, b) => a + b) / yExposed.length;
    final double unexposedAvg =
        yUnexposed.isEmpty ? 0.0 : yUnexposed.reduce((a, b) => a + b) / yUnexposed.length;
    final double effect = exposedAvg - unexposedAvg;

    // Hit rate count
    int hitRateCount = 0;
    for (final y in yExposed) {
      if (isProtective) {
        if (y < unexposedAvg) hitRateCount++;
      } else {
        if (y > unexposedAvg) hitRateCount++;
      }
    }

    return _LagComputation(
      lag: lag,
      rawR: clampedR,
      strength: strength,
      effect: effect,
      exposedAvg: exposedAvg,
      unexposedAvg: unexposedAvg,
      eventCount: yExposed.length,
      comparisonDaysCount: yUnexposed.length,
      hitRateCount: hitRateCount,
      exposedEvents: exposedEvents,
    );
  }

  /// Extracts daily score on 0-5 scale for a symptom (0.0 if absent).
  double _extractSymptomScore(DailyLog log, String symptomId) {
    for (final s in log.symptoms) {
      final id = s.symptom.id.isNotEmpty ? s.symptom.id : s.symptom.name;
      if (id.toLowerCase() == symptomId.toLowerCase()) {
        final sev = s.severity?.trim().toLowerCase();
        if (sev == 'mild') return 1.0;
        if (sev == 'moderate') return 3.0;
        if (sev == 'severe') return 5.0;
        if (s.intensity != null) return (s.intensity! / 2.0).clamp(0.0, 5.0);
        return 0.0;
      }
    }
    return 0.0; // Absent = 0.0 per SD-3
  }

  /// Extracts overall day level score (mean of present symptoms with score, 0 on symptom-free).
  double _extractDayLevel(DailyLog log) {
    if (log.symptoms.isEmpty) return 0.0;

    double sum = 0.0;
    int count = 0;

    for (final s in log.symptoms) {
      final sev = s.severity?.trim().toLowerCase();
      double? score;
      if (sev == 'mild') {
        score = 1.0;
      } else if (sev == 'moderate') {
        score = 3.0;
      } else if (sev == 'severe') {
        score = 5.0;
      } else if (s.intensity != null) {
        score = (s.intensity! / 2.0).clamp(0.0, 5.0);
      }

      if (score != null && score > 0.0) {
        sum += score;
        count++;
      }
    }

    if (count == 0) return 0.0;
    return sum / count;
  }
}

class _OutcomeCandidate {
  final String id;
  final String displayName;
  final bool isOverallDayLevel;

  const _OutcomeCandidate({
    required this.id,
    required this.displayName,
    required this.isOverallDayLevel,
  });
}

class _LagComputation {
  final PatternLag lag;
  final double rawR;
  final double strength;
  final double effect;
  final double exposedAvg;
  final double unexposedAvg;
  final int eventCount;
  final int comparisonDaysCount;
  final int hitRateCount;
  final List<PatternEventDay> exposedEvents;

  const _LagComputation({
    required this.lag,
    required this.rawR,
    required this.strength,
    required this.effect,
    required this.exposedAvg,
    required this.unexposedAvg,
    required this.eventCount,
    required this.comparisonDaysCount,
    required this.hitRateCount,
    this.exposedEvents = const [],
  });
}
