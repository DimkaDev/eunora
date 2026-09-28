import 'dart:math' as math;

import '../../home/domain/entities/daily_log.dart';
import '../../onboarding/domain/models/medication.dart';
import '../domain/models/analysis_period.dart';
import '../domain/models/home_insight.dart';
import '../domain/models/hrt_change_result.dart';
import '../domain/models/pattern_result.dart';
import '../domain/models/period_comparison.dart';
import '../domain/models/window_analysis_result.dart';
import 'analysis_engine.dart';
import 'symptom_categorizer.dart';
import 'trigger_normalizer.dart';

/// Service that selects personal Daily and Weekly Home Insights and evaluates
/// the High Severity Alert according to Task 4 specifications.
class HomeInsightSelector {
  final AnalysisEngine analysisEngine;
  final TriggerNormalizer triggerNormalizer;
  final SymptomCategorizer symptomCategorizer;

  const HomeInsightSelector({
    this.analysisEngine = const AnalysisEngine(),
    this.triggerNormalizer = const TriggerNormalizer(),
    this.symptomCategorizer = const SymptomCategorizer(),
  });

  /// Selects the complete [HomeInsightsBundle] for Home.
  HomeInsightsBundle selectInsights({
    required List<DailyLog> logs,
    DateTime? today,
    required WindowAnalysisResult analysis30,
    required WindowAnalysisResult analysis7,
    required PatternEngineResult patternsResult,
    required HrtAnalysisResult hrtResult,
    required List<Medication> medications,
    HomeInsightCardData? previousDayDailyInsight,
    HomeInsightCardData? previousDayWeeklyInsight,
    bool proactiveTipsEnabled = false,
  }) {
    final refToday = AnalysisEngine.normalizeDate(today ?? DateTime.now());

    // Map completed logs by normalized date
    final Map<DateTime, DailyLog> logsByDate = {};
    for (final log in logs) {
      if (!log.isCompleted) continue;
      final d = AnalysisEngine.normalizeDate(log.date);
      if (!logsByDate.containsKey(d) || log.createdAt.isAfter(logsByDate[d]!.createdAt)) {
        logsByDate[d] = log;
      }
    }

    // 1. High Severity Alert
    final highSeverityAlert = _evaluateHighSeverityAlert(
      logsByDate: logsByDate,
      today: refToday,
      showProactiveTips: proactiveTipsEnabled,
    );

    // 2. Daily Insight
    final dailyInsight = _selectDailyInsight(
      logsByDate: logsByDate,
      today: refToday,
      analysis30: analysis30,
      analysis7: analysis7,
      patternsResult: patternsResult,
      hrtResult: hrtResult,
      previousDayDailyInsight: previousDayDailyInsight,
    );

    // 3. Weekly Insight
    final weeklyInsight = _selectWeeklyInsight(
      logsByDate: logsByDate,
      today: refToday,
      analysis7: analysis7,
      patternsResult: patternsResult,
      hrtResult: hrtResult,
      medications: medications,
      previousDayWeeklyInsight: previousDayWeeklyInsight,
    );

    return HomeInsightsBundle(
      dailyInsight: dailyInsight,
      weeklyInsight: weeklyInsight,
      highSeverityAlert: highSeverityAlert,
    );
  }

  /// High Severity Alert: 3 consecutive calendar days of Severe hot flashes (all logged).
  HighSeverityAlertData? _evaluateHighSeverityAlert({
    required Map<DateTime, DailyLog> logsByDate,
    required DateTime today,
    required bool showProactiveTips,
  }) {
    int consecutiveSevereDays = 0;
    DateTime cursor = today;

    // Check last 3 consecutive calendar days: today, yesterday, 2 days ago
    for (int i = 0; i < 3; i++) {
      final log = logsByDate[cursor];
      if (log == null) {
        // Interrupted by an unlogged day -> fails consecutive condition
        return null;
      }

      final hasSevereHotFlashes = log.symptoms.any((s) {
        final id = s.symptom.id.isNotEmpty ? s.symptom.id : s.symptom.name;
        final isHotFlash = id.toLowerCase().contains('hot_flash') ||
            id.toLowerCase().contains('hot flash') ||
            s.symptom.name.toLowerCase().contains('hot flash');
        if (!isHotFlash) return false;

        final sev = s.severity?.trim().toLowerCase();
        final intensity = s.intensity;
        return sev == 'severe' || (intensity != null && intensity >= 9);
      });

      if (!hasSevereHotFlashes) {
        return null;
      }

      consecutiveSevereDays++;
      cursor = AnalysisEngine.addDays(cursor, -1);
    }

    if (consecutiveSevereDays >= 3) {
      return HighSeverityAlertData(
        isActive: true,
        consecutiveSevereDays: consecutiveSevereDays,
        showProactiveTips: showProactiveTips,
      );
    }

    return null;
  }

  /// Selects Daily Insight in strict order: D-1 -> D-2 -> D-5 -> D-4 -> D-3 -> D-6 -> D-7 -> D-8.
  /// Falls back to Yesterday or prompt to log if today is not logged.
  HomeInsightCardData _selectDailyInsight({
    required Map<DateTime, DailyLog> logsByDate,
    required DateTime today,
    required WindowAnalysisResult analysis30,
    required WindowAnalysisResult analysis7,
    required PatternEngineResult patternsResult,
    required HrtAnalysisResult hrtResult,
    HomeInsightCardData? previousDayDailyInsight,
  }) {
    final avgSevDisplay = analysis30.severityDisplay ?? '—';
    final consistencyPct = (analysis7.consistency * 100).round();

    final todayLog = logsByDate[today];
    if (todayLog != null) {
      final candidate = _evaluateDailyCandidates(
        log: todayLog,
        logDate: today,
        isYesterday: false,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: patternsResult,
        hrtResult: hrtResult,
        avgSevDisplay: avgSevDisplay,
        consistencyPct: consistencyPct,
        previousInsight: previousDayDailyInsight,
      );
      if (candidate != null) return candidate;
    }

    // Today is not logged: check yesterday
    final yesterday = AnalysisEngine.addDays(today, -1);
    final yesterdayLog = logsByDate[yesterday];
    if (yesterdayLog != null) {
      final candidate = _evaluateDailyCandidates(
        log: yesterdayLog,
        logDate: yesterday,
        isYesterday: true,
        analysis30: analysis30,
        analysis7: analysis7,
        patternsResult: patternsResult,
        hrtResult: hrtResult,
        avgSevDisplay: avgSevDisplay,
        consistencyPct: consistencyPct,
        previousInsight: previousDayDailyInsight,
      );
      if (candidate != null) return candidate;
    }

    // Neither today nor yesterday logged: gentle prompt to log
    return HomeInsightCardData(
      title: 'Daily Insight',
      tag: HomeInsightTag.insight,
      headline: 'Log today to keep your picture up to date.',
      evidence: 'Consistent logging helps discover trends and patterns.',
      averageSeverityDisplay: avgSevDisplay,
      consistencyPercent: consistencyPct,
      targetMetric: 'overall_severity',
      targetPeriod: AnalysisPeriod.days30,
      evidenceSummary: 'Keep logging daily to build personal patterns.',
      candidateType: 'promptToLog',
      subjectKey: 'prompt_to_log',
      isPromptToLog: true,
    );
  }

  HomeInsightCardData? _evaluateDailyCandidates({
    required DailyLog log,
    required DateTime logDate,
    required bool isYesterday,
    required WindowAnalysisResult analysis30,
    required WindowAnalysisResult analysis7,
    required PatternEngineResult patternsResult,
    required HrtAnalysisResult hrtResult,
    required String avgSevDisplay,
    required int consistencyPct,
    HomeInsightCardData? previousInsight,
  }) {
    final String title = isYesterday ? "Yesterday's Insight" : "Daily Insight";
    final double? normSeverity = analysis30.averageSeverity;
    final int baselineCount = analysis30.loggedDaysCount;

    // Day level and symptom-free check for this day
    final dayPicture = analysisEngine.analyzeDay(log, logDate, today: logDate);
    final bool isSymptomFree = dayPicture.isSymptomFree;
    final double? dayLevel = dayPicture.dayLevel;

    final List<HomeInsightCardData> candidates = [];

    // D-1: Symptom-free day (baseline >= 3 logged days)
    if (isSymptomFree && baselineCount >= 3) {
      candidates.add(HomeInsightCardData(
        title: title,
        tag: HomeInsightTag.positiveTrend,
        headline: isYesterday ? "No symptoms were logged yesterday." : "No symptoms logged today.",
        evidence: "Symptom-free days establish your baseline.",
        averageSeverityDisplay: avgSevDisplay,
        consistencyPercent: consistencyPct,
        targetMetric: 'overall_severity',
        targetPeriod: AnalysisPeriod.days30,
        evidenceSummary: 'Symptom-free day: score 0 across all symptoms.',
        candidateType: 'D-1',
        subjectKey: 'd1_symptom_free',
        keyNumber: 0.0,
        isYesterday: isYesterday,
      ));
    }

    // D-2: Lighter than usual (at least 0.5 below norm, baseline >= 7)
    if (!isSymptomFree &&
        dayLevel != null &&
        normSeverity != null &&
        baselineCount >= 7 &&
        (dayLevel <= normSeverity - 0.5)) {
      candidates.add(HomeInsightCardData(
        title: title,
        tag: HomeInsightTag.positiveTrend,
        headline: isYesterday
            ? "Yesterday's symptoms were milder than your usual (${dayLevel.toStringAsFixed(1)} vs ${normSeverity.toStringAsFixed(1)})."
            : "Today's symptoms were milder than your usual (${dayLevel.toStringAsFixed(1)} vs ${normSeverity.toStringAsFixed(1)}).",
        evidence: "Your 30-day average severity is ${normSeverity.toStringAsFixed(1)}.",
        averageSeverityDisplay: avgSevDisplay,
        consistencyPercent: consistencyPct,
        targetMetric: 'overall_severity',
        targetPeriod: AnalysisPeriod.days30,
        evidenceSummary: 'Average severity was ${dayLevel.toStringAsFixed(1)} vs 30-day norm of ${normSeverity.toStringAsFixed(1)}.',
        candidateType: 'D-2',
        subjectKey: 'd2_lighter',
        keyNumber: dayLevel,
        isYesterday: isYesterday,
      ));
    }

    // D-5: Protective habit logged today with a ready protective pattern
    final extractedTriggers = triggerNormalizer.extractTriggers(log);
    for (final pattern in patternsResult.patterns) {
      final canonId = triggerNormalizer.canonicalizeId(pattern.triggerId);
      final isExposed = extractedTriggers.containsKey(pattern.triggerId) ||
          extractedTriggers.containsKey(canonId) ||
          (pattern.triggerId == 'exercise_30plus' && extractedTriggers.containsKey('exercise'));
      if (pattern.type == PatternType.protective && isExposed) {
        candidates.add(HomeInsightCardData(
          title: title,
          tag: HomeInsightTag.positiveTrend,
          headline:
              "You logged ${pattern.triggerDisplayName} ${isYesterday ? 'yesterday' : 'today'}. In your data, ${pattern.outcomeDisplayName} tends to be milder on those days.",
          evidence: pattern.evidenceText,
          averageSeverityDisplay: avgSevDisplay,
          consistencyPercent: consistencyPct,
          targetMetric: pattern.outcomeId,
          targetPeriod: AnalysisPeriod.days30,
          evidenceSummary: pattern.evidenceText,
          candidateType: 'D-5',
          subjectKey: 'd5_${pattern.triggerId}',
          keyNumber: pattern.strength,
          isYesterday: isYesterday,
        ));
        break; // Take first matching protective pattern
      }
    }

    // D-4: Known trigger logged today with a ready pattern
    for (final pattern in patternsResult.patterns) {
      final canonId = triggerNormalizer.canonicalizeId(pattern.triggerId);
      final isExposed = extractedTriggers.containsKey(pattern.triggerId) ||
          extractedTriggers.containsKey(canonId);
      if (pattern.type == PatternType.worsening && isExposed) {
        final lagPhrase = pattern.lag == PatternLag.lag0 ? 'on days you log it' : 'the day after';
        candidates.add(HomeInsightCardData(
          title: title,
          tag: HomeInsightTag.pattern,
          headline:
              "You logged ${pattern.triggerDisplayName} ${isYesterday ? 'yesterday' : 'today'}. In your data, ${pattern.outcomeDisplayName} tends to be stronger $lagPhrase.",
          evidence: pattern.evidenceText,
          averageSeverityDisplay: avgSevDisplay,
          consistencyPercent: consistencyPct,
          targetMetric: pattern.outcomeId,
          targetPeriod: AnalysisPeriod.days30,
          evidenceSummary: pattern.evidenceText,
          candidateType: 'D-4',
          subjectKey: 'd4_${pattern.triggerId}',
          keyNumber: pattern.strength,
          isYesterday: isYesterday,
        ));
        break; // Take first matching trigger pattern
      }
    }

    // D-3: Stronger than usual (at least 0.5 above norm, baseline >= 7)
    if (!isSymptomFree &&
        dayLevel != null &&
        normSeverity != null &&
        baselineCount >= 7 &&
        (dayLevel >= normSeverity + 0.5)) {
      candidates.add(HomeInsightCardData(
        title: title,
        tag: HomeInsightTag.worthNoting,
        headline: isYesterday
            ? "Yesterday's symptoms were stronger than your usual (${dayLevel.toStringAsFixed(1)} vs ${normSeverity.toStringAsFixed(1)})."
            : "Today's symptoms were stronger than your usual (${dayLevel.toStringAsFixed(1)} vs ${normSeverity.toStringAsFixed(1)}). Tomorrow's log will show whether this continues.",
        evidence: "Your 30-day average severity is ${normSeverity.toStringAsFixed(1)}.",
        averageSeverityDisplay: avgSevDisplay,
        consistencyPercent: consistencyPct,
        targetMetric: 'overall_severity',
        targetPeriod: AnalysisPeriod.days30,
        evidenceSummary: 'Average severity was ${dayLevel.toStringAsFixed(1)} vs 30-day norm of ${normSeverity.toStringAsFixed(1)}.',
        candidateType: 'D-3',
        subjectKey: 'd3_stronger',
        keyNumber: dayLevel,
        isYesterday: isYesterday,
      ));
    }

    // D-6: HRT pending
    if (hrtResult.groups.isNotEmpty) {
      final latest = hrtResult.groups.first;
      if (latest.status == HrtChangeStatus.pending && latest.daysToGo != null) {
        final n = latest.daysSinceChange + 1;
        final bigN = latest.daysToGo!;
        candidates.add(HomeInsightCardData(
          title: title,
          tag: HomeInsightTag.insight,
          headline: "Day $n of 14 since your regimen changed — comparison ready in $bigN days.",
          evidence: latest.summaryTitle,
          averageSeverityDisplay: avgSevDisplay,
          consistencyPercent: consistencyPct,
          targetMetric: 'overall_severity',
          targetPeriod: AnalysisPeriod.days30,
          evidenceSummary: latest.summaryTitle,
          candidateType: 'D-6',
          subjectKey: 'd6_hrt_pending',
          keyNumber: bigN.toDouble(),
          isYesterday: isYesterday,
        ));
      }
    }

    // D-7: Logged 7 of last 7 days
    if (analysis7.loggedDaysCount >= 7 && consistencyPct == 100) {
      candidates.add(HomeInsightCardData(
        title: title,
        tag: HomeInsightTag.insight,
        headline: "You've logged 7 of the last 7 days.",
        evidence: "Consistent logging makes your trends and patterns more reliable.",
        averageSeverityDisplay: avgSevDisplay,
        consistencyPercent: consistencyPct,
        targetMetric: 'overall_severity',
        targetPeriod: AnalysisPeriod.days30,
        evidenceSummary: '100% logging consistency over trailing 7 days.',
        candidateType: 'D-7',
        subjectKey: 'd7_logged_7_of_7',
        keyNumber: 7.0,
        isYesterday: isYesterday,
      ));
    }

    // D-8: Fallback
    final needed = math.max(1, 7 - baselineCount);
    candidates.add(HomeInsightCardData(
      title: title,
      tag: HomeInsightTag.insight,
      headline: "Log $needed more days to unlock personal insights.",
      evidence: "We need at least 7 logged days to establish your personal norm.",
      averageSeverityDisplay: avgSevDisplay,
      consistencyPercent: consistencyPct,
      targetMetric: 'overall_severity',
      targetPeriod: AnalysisPeriod.days30,
      evidenceSummary: 'Currently $baselineCount of 7 required baseline days logged.',
      candidateType: 'D-8',
      subjectKey: 'd8_fallback',
      keyNumber: needed.toDouble(),
      isYesterday: isYesterday,
    ));

    // Anti-repetition filter:
    // The same insight (same candidateType and subjectKey) is not shown on two consecutive days
    // unless its keyNumber changed materially per SD-4 or nothing else is eligible.
    return _applyAntiRepetition(candidates, previousInsight);
  }

  /// Selects Weekly Insight in strict order:
  /// W-1 -> W-2 -> W-3 -> W-4 -> W-5 -> W-1b -> W-6 -> W-7.
  HomeInsightCardData _selectWeeklyInsight({
    required Map<DateTime, DailyLog> logsByDate,
    required DateTime today,
    required WindowAnalysisResult analysis7,
    required PatternEngineResult patternsResult,
    required HrtAnalysisResult hrtResult,
    required List<Medication> medications,
    HomeInsightCardData? previousDayWeeklyInsight,
  }) {
    final avgSevDisplay = analysis7.severityDisplay ?? '—';
    final consistencyPct = (analysis7.consistency * 100).round();

    // Week 1 (last 7 days): [today - 6, today]
    // Week 2 (previous 7 days): [today - 13, today - 7]
    final w1Start = AnalysisEngine.addDays(today, -6);
    final w1End = today;
    final w2Start = AnalysisEngine.addDays(today, -13);
    final w2End = AnalysisEngine.addDays(today, -7);

    final List<DailyLog> w1Logs = [];
    DateTime c1 = w1Start;
    while (!c1.isAfter(w1End)) {
      final l = logsByDate[c1];
      if (l != null) w1Logs.add(l);
      c1 = AnalysisEngine.addDays(c1, 1);
    }

    final List<DailyLog> w2Logs = [];
    DateTime c2 = w2Start;
    while (!c2.isAfter(w2End)) {
      final l = logsByDate[c2];
      if (l != null) w2Logs.add(l);
      c2 = AnalysisEngine.addDays(c2, 1);
    }

    final int w1Logged = w1Logs.length;
    final int w2Logged = w2Logs.length;

    final List<HomeInsightCardData> candidates = [];

    // Calculate week 1 and week 2 average severities
    double? w1Avg;
    double? w2Avg;
    int w1SevCount = 0;
    double w1SevSum = 0.0;
    for (final l in w1Logs) {
      for (final s in l.symptoms) {
        final sc = _normalizeScore(s);
        if (sc != null && sc > 0) {
          w1SevSum += sc;
          w1SevCount++;
        }
      }
    }
    if (w1SevCount > 0) w1Avg = w1SevSum / w1SevCount;

    int w2SevCount = 0;
    double w2SevSum = 0.0;
    for (final l in w2Logs) {
      for (final s in l.symptoms) {
        final sc = _normalizeScore(s);
        if (sc != null && sc > 0) {
          w2SevSum += sc;
          w2SevCount++;
        }
      }
    }
    if (w2SevCount > 0) w2Avg = w2SevSum / w2SevCount;

    // W-1: Overall change (at least 3 logged days in each week, material per SD-4)
    if (w1Logged >= 3 && w2Logged >= 3 && w1Avg != null && w2Avg != null) {
      final comp = MetricComparison.evaluate(current: w1Avg, previous: w2Avg, lowerIsBetter: true);
      if (comp.changeType == MaterialChangeType.improved ||
          comp.changeType == MaterialChangeType.worsened) {
        final bool isImproved = comp.changeType == MaterialChangeType.improved;
        final verb = isImproved ? 'improved' : 'rose';
        final pct = comp.percentChange?.abs() ?? 0;
        candidates.add(HomeInsightCardData(
          title: 'Weekly Data Insight',
          tag: isImproved ? HomeInsightTag.positiveTrend : HomeInsightTag.worthNoting,
          headline:
              'Your average symptom severity $verb $pct% compared with the previous 7 days (${w1Avg.toStringAsFixed(1)} vs ${w2Avg.toStringAsFixed(1)}).',
          evidence: 'Based on 7-day comparison (${w1Logged} days vs ${w2Logged} days).',
          averageSeverityDisplay: avgSevDisplay,
          consistencyPercent: consistencyPct,
          targetMetric: 'overall_severity',
          targetPeriod: AnalysisPeriod.days7,
          evidenceSummary: 'Average severity changed from ${w2Avg.toStringAsFixed(1)} to ${w1Avg.toStringAsFixed(1)}.',
          candidateType: 'W-1',
          subjectKey: 'w1_overall',
          keyNumber: comp.delta,
        ));
      }
    }

    // W-2: Top symptom change (symptom present >= 3 days in either week, largest material change)
    final Set<String> candidateSymptomIds = {};
    for (final l in [...w1Logs, ...w2Logs]) {
      for (final s in l.symptoms) {
        final id = s.symptom.id.isNotEmpty ? s.symptom.id : s.symptom.name;
        candidateSymptomIds.add(id);
      }
    }

    _SymptomWeekChange? bestSymptomChange;

    for (final sId in candidateSymptomIds) {
      int xDays = 0;
      double xSum = 0.0;
      for (final l in w1Logs) {
        final s = _findSymptom(l, sId);
        if (s != null) {
          xDays++;
          final sc = _normalizeScore(s) ?? 0.0;
          xSum += sc;
        }
      }

      int yDays = 0;
      double ySum = 0.0;
      for (final l in w2Logs) {
        final s = _findSymptom(l, sId);
        if (s != null) {
          yDays++;
          final sc = _normalizeScore(s) ?? 0.0;
          ySum += sc;
        }
      }

      // Must be present >= 3 days in either week
      if (xDays < 3 && yDays < 3) continue;

      final burden1 = w1Logged > 0 ? (xSum / w1Logged) : 0.0;
      final burden2 = w2Logged > 0 ? (ySum / w2Logged) : 0.0;

      final comp = MetricComparison.evaluate(current: burden1, previous: burden2, lowerIsBetter: true);
      if (comp.changeType == MaterialChangeType.improved ||
          comp.changeType == MaterialChangeType.worsened) {
        final change = _SymptomWeekChange(
          symptomId: sId,
          displayName: symptomCategorizer.getLabel(sId),
          daysThisWeek: xDays,
          daysLastWeek: yDays,
          comparison: comp,
        );

        if (bestSymptomChange == null ||
            (comp.delta?.abs() ?? 0.0) > (bestSymptomChange.comparison.delta?.abs() ?? 0.0)) {
          bestSymptomChange = change;
        }
      }
    }

    if (bestSymptomChange != null) {
      final isImproved = bestSymptomChange.comparison.changeType == MaterialChangeType.improved;
      final verb = isImproved ? 'eased' : 'increased';
      candidates.add(HomeInsightCardData(
        title: 'Weekly Data Insight',
        tag: isImproved ? HomeInsightTag.positiveTrend : HomeInsightTag.worthNoting,
        headline:
            '${bestSymptomChange.displayName} $verb: logged on ${bestSymptomChange.daysThisWeek} days this week vs ${bestSymptomChange.daysLastWeek} last week.',
        evidence: 'Burden shifted by ${(bestSymptomChange.comparison.delta ?? 0.0).toStringAsFixed(1)} points.',
        averageSeverityDisplay: avgSevDisplay,
        consistencyPercent: consistencyPct,
        targetMetric: bestSymptomChange.symptomId,
        targetPeriod: AnalysisPeriod.days7,
        evidenceSummary: 'Logged on ${bestSymptomChange.daysThisWeek} days this week vs ${bestSymptomChange.daysLastWeek} last week.',
        candidateType: 'W-2',
        subjectKey: 'w2_${bestSymptomChange.symptomId}',
        keyNumber: bestSymptomChange.comparison.delta,
      ));
    }

    // W-3: Sleep split (>= 3 days under 6h and >= 3 days >= 6h, sleep trust gate passed)
    final sleepCandidate = _evaluateSleepSplit(
      w1Logs: w1Logs,
      analysis7: analysis7,
      avgSevDisplay: avgSevDisplay,
      consistencyPct: consistencyPct,
    );
    if (sleepCandidate != null) {
      candidates.add(sleepCandidate);
    }

    // W-4: Strongest pattern this week
    if (patternsResult.patterns.isNotEmpty) {
      final strongest = patternsResult.patterns.first;
      candidates.add(HomeInsightCardData(
        title: 'Weekly Data Insight',
        tag: HomeInsightTag.pattern,
        headline:
            'This week\'s strongest pattern: ${strongest.triggerDisplayName} → ${strongest.outcomeDisplayName} (${strongest.correlationPercent}%).',
        evidence: strongest.evidenceText,
        averageSeverityDisplay: avgSevDisplay,
        consistencyPercent: consistencyPct,
        targetMetric: strongest.outcomeId,
        targetPeriod: AnalysisPeriod.days7,
        evidenceSummary: strongest.evidenceText,
        candidateType: 'W-4',
        subjectKey: 'w4_${strongest.triggerId}_${strongest.outcomeId}',
        keyNumber: strongest.strength,
      ));
    }

    // W-5: HRT adherence (at least 3 scheduled doses in the week)
    final hrtCandidate = _evaluateWeeklyHrtAdherence(
      w1Start: w1Start,
      w1End: w1End,
      logsByDate: logsByDate,
      medications: medications,
      avgSevDisplay: avgSevDisplay,
      consistencyPct: consistencyPct,
    );
    if (hrtCandidate != null) {
      candidates.add(hrtCandidate);
    }

    // W-1b: Steady week (comparison possible, not material)
    if (w1Logged >= 3 && w2Logged >= 3 && w1Avg != null && w2Avg != null) {
      final comp = MetricComparison.evaluate(current: w1Avg, previous: w2Avg, lowerIsBetter: true);
      if (comp.changeType == MaterialChangeType.steady) {
        candidates.add(HomeInsightCardData(
          title: 'Weekly Data Insight',
          tag: HomeInsightTag.insight,
          headline: 'Your symptoms were about the same as the previous 7 days.',
          evidence: 'Average severity was ${w1Avg.toStringAsFixed(1)} this week vs ${w2Avg.toStringAsFixed(1)} last week.',
          averageSeverityDisplay: avgSevDisplay,
          consistencyPercent: consistencyPct,
          targetMetric: 'overall_severity',
          targetPeriod: AnalysisPeriod.days7,
          evidenceSummary: 'Average severity steady: ${w1Avg.toStringAsFixed(1)} vs ${w2Avg.toStringAsFixed(1)}.',
          candidateType: 'W-1b',
          subjectKey: 'w1b_steady',
          keyNumber: comp.delta,
        ));
      }
    }

    // W-6: Logging coverage below 100%
    if (w1Logged > 0 && w1Logged < 7) {
      candidates.add(HomeInsightCardData(
        title: 'Weekly Data Insight',
        tag: HomeInsightTag.insight,
        headline: 'You logged $w1Logged of 7 days this week.',
        evidence: 'Logging every day gives a more complete picture of your trends.',
        averageSeverityDisplay: avgSevDisplay,
        consistencyPercent: consistencyPct,
        targetMetric: 'overall_severity',
        targetPeriod: AnalysisPeriod.days7,
        evidenceSummary: 'Logged $w1Logged of 7 days this week.',
        candidateType: 'W-6',
        subjectKey: 'w6_coverage_$w1Logged',
        keyNumber: w1Logged.toDouble(),
      ));
    }

    // W-7: Fallback
    candidates.add(HomeInsightCardData(
      title: 'Weekly Data Insight',
      tag: HomeInsightTag.insight,
      headline: 'Keep logging — your weekly picture builds as you go.',
      evidence: 'After 3 logged days this week and last week, your weekly comparison unlocks.',
      averageSeverityDisplay: avgSevDisplay,
      consistencyPercent: consistencyPct,
      targetMetric: 'overall_severity',
      targetPeriod: AnalysisPeriod.days7,
      evidenceSummary: 'Weekly trend analysis unlocks with 3+ logged days per week.',
      candidateType: 'W-7',
      subjectKey: 'w7_fallback',
      keyNumber: 0.0,
    ));

    return _applyAntiRepetition(candidates, previousDayWeeklyInsight)!;
  }

  HomeInsightCardData? _evaluateSleepSplit({
    required List<DailyLog> w1Logs,
    required WindowAnalysisResult analysis7,
    required String avgSevDisplay,
    required int consistencyPct,
  }) {
    if (!analysis7.isSleepTrusted) return null;

    final List<double> under6DayLevels = [];
    final List<double> over6DayLevels = [];

    for (final log in w1Logs) {
      final sleep = log.sleepDuration;
      final level = _calcDayLevel(log);

      if (sleep < 6.0) {
        under6DayLevels.add(level);
      } else {
        over6DayLevels.add(level);
      }
    }

    if (under6DayLevels.length < 3 || over6DayLevels.length < 3) {
      return null;
    }

    final double a = under6DayLevels.reduce((x, y) => x + y) / under6DayLevels.length;
    final double b = over6DayLevels.reduce((x, y) => x + y) / over6DayLevels.length;

    return HomeInsightCardData(
      title: 'Weekly Data Insight',
      tag: HomeInsightTag.pattern,
      headline:
          'On days with under 6 hours of sleep, symptom severity averaged ${a.toStringAsFixed(1)} vs ${b.toStringAsFixed(1)} on other days.',
      evidence: 'Sleep duration shows an association with daily symptom severity.',
      averageSeverityDisplay: avgSevDisplay,
      consistencyPercent: consistencyPct,
      targetMetric: 'sleep',
      targetPeriod: AnalysisPeriod.days7,
      evidenceSummary: 'Average severity ${a.toStringAsFixed(1)} (<6h) vs ${b.toStringAsFixed(1)} (≥6h).',
      candidateType: 'W-3',
      subjectKey: 'w3_sleep_split',
      keyNumber: a - b,
    );
  }

  HomeInsightCardData? _evaluateWeeklyHrtAdherence({
    required DateTime w1Start,
    required DateTime w1End,
    required Map<DateTime, DailyLog> logsByDate,
    required List<Medication> medications,
    required String avgSevDisplay,
    required int consistencyPct,
  }) {
    int scheduled = 0;
    int taken = 0;

    DateTime cursor = w1Start;
    while (!cursor.isAfter(w1End)) {
      final weekday = cursor.weekday;
      final log = logsByDate[cursor];

      for (final med in medications) {
        final freqLower = med.frequency.toLowerCase();
        if (freqLower.contains('needed')) continue;

        if (med.selectedWeekdays.contains(weekday)) {
          scheduled++;
          if (log != null) {
            final took = log.hrtIntakes.any((i) =>
                (i.medicationId == med.id || i.name.toLowerCase() == med.name.toLowerCase()) &&
                i.isTaken);
            if (took) taken++;
          }
        }
      }
      cursor = AnalysisEngine.addDays(cursor, 1);
    }

    if (scheduled < 3) return null;

    return HomeInsightCardData(
      title: 'Weekly Data Insight',
      tag: HomeInsightTag.insight,
      headline: 'You took $taken of $scheduled scheduled HRT doses this week.',
      evidence: 'Consistent timing supports steady hormone levels.',
      averageSeverityDisplay: avgSevDisplay,
      consistencyPercent: consistencyPct,
      targetMetric: 'overall_severity',
      targetPeriod: AnalysisPeriod.days7,
      evidenceSummary: 'Adherence: $taken / $scheduled scheduled doses taken this week.',
      candidateType: 'W-5',
      subjectKey: 'w5_adherence',
      keyNumber: (taken / scheduled) * 100,
    );
  }

  /// Anti-repetition helper:
  /// The same insight (same candidateType and subjectKey) is not shown on two consecutive days
  /// unless its keyNumber changed materially per SD-4 (|delta| >= 0.5 and >= 15%) or nothing else is eligible.
  HomeInsightCardData? _applyAntiRepetition(
    List<HomeInsightCardData> candidates,
    HomeInsightCardData? previousInsight,
  ) {
    if (candidates.isEmpty) return null;
    if (previousInsight == null) return candidates.first;

    for (final candidate in candidates) {
      final isSameInsight = candidate.candidateType == previousInsight.candidateType &&
          candidate.subjectKey == previousInsight.subjectKey;

      if (!isSameInsight) {
        return candidate;
      }

      // Same insight: check if keyNumber changed materially per SD-4
      final prevKey = previousInsight.keyNumber;
      final currKey = candidate.keyNumber;
      if (prevKey != null && currKey != null) {
        final delta = (currKey - prevKey).abs();
        final relChange = prevKey != 0.0 ? (delta / prevKey.abs()) : 1.0;
        if (delta >= 0.5 && relChange >= 0.15) {
          // Material change occurred -> allowed!
          return candidate;
        }
      }
    }

    // Nothing else is eligible, return candidates.first
    return candidates.first;
  }

  dynamic _findSymptom(DailyLog log, String symptomId) {
    for (final s in log.symptoms) {
      final id = s.symptom.id.isNotEmpty ? s.symptom.id : s.symptom.name;
      if (id.toLowerCase() == symptomId.toLowerCase()) return s;
    }
    return null;
  }

  double? _normalizeScore(dynamic loggedSymptom) {
    final sev = loggedSymptom.severity?.toString().trim().toLowerCase();
    if (sev == 'mild') return 1.0;
    if (sev == 'moderate') return 3.0;
    if (sev == 'severe') return 5.0;
    final intensity = loggedSymptom.intensity as int?;
    if (intensity != null) return (intensity / 2.0).clamp(0.0, 5.0);
    return null;
  }

  double _calcDayLevel(DailyLog log) {
    if (log.symptoms.isEmpty) return 0.0;
    double sum = 0.0;
    int count = 0;
    for (final s in log.symptoms) {
      final score = _normalizeScore(s);
      if (score != null && score > 0.0) {
        sum += score;
        count++;
      }
    }
    return count > 0 ? (sum / count) : 0.0;
  }
}

class _SymptomWeekChange {
  final String symptomId;
  final String displayName;
  final int daysThisWeek;
  final int daysLastWeek;
  final MetricComparison comparison;

  const _SymptomWeekChange({
    required this.symptomId,
    required this.displayName,
    required this.daysThisWeek,
    required this.daysLastWeek,
    required this.comparison,
  });
}
