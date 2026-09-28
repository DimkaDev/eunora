import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const engine = AnalysisEngine();

  void assertInvariants(List<DailyLog> logs, WindowAnalysisResult res) {
    expect(res.coverage.isNaN, isFalse);
    expect(res.coverage.isInfinite, isFalse);
    expect(res.consistency.isNaN, isFalse);
    expect(res.consistency.isInfinite, isFalse);
    if (res.averageSeverity != null) {
      expect(res.averageSeverity!.isNaN, isFalse);
      expect(res.averageSeverity!.isInfinite, isFalse);
    }
  }

  group('T1 Foundation Tests', () {
    test('T1-A: Period windows and DST calculations', () {
      final today = DateTime(2026, 9, 19);

      // Period 1
      final res1 = engine.analyzeWindow(logs: [], period: AnalysisPeriod.day1, today: today);
      expect(res1.windowStart, DateTime(2026, 9, 19));
      expect(res1.windowEnd, DateTime(2026, 9, 19));
      expect(res1.calendarDaysInWindow, 1);

      // Period 7
      final res7 = engine.analyzeWindow(logs: [], period: AnalysisPeriod.days7, today: today);
      expect(res7.windowStart, DateTime(2026, 9, 13));
      expect(res7.windowEnd, DateTime(2026, 9, 19));
      expect(res7.calendarDaysInWindow, 7);

      // Period 30
      final res30 = engine.analyzeWindow(logs: [], period: AnalysisPeriod.days30, today: today);
      expect(res30.windowStart, DateTime(2026, 8, 21));
      expect(res30.windowEnd, DateTime(2026, 9, 19));
      expect(res30.calendarDaysInWindow, 30);

      // Period 90
      final res90 = engine.analyzeWindow(logs: [], period: AnalysisPeriod.days90, today: today);
      expect(res90.windowStart, DateTime(2026, 6, 22));
      expect(res90.windowEnd, DateTime(2026, 9, 19));
      expect(res90.calendarDaysInWindow, 90);

      // First log 2 Sep, period 30: window clamped to 2 Sep (18 calendar days), no previous window
      final gLogs = goldenDatasetLogs();
      final resClamped = engine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: today);
      expect(resClamped.isHistoryClamped, isTrue);
      expect(resClamped.windowStart, DateTime(2026, 9, 2));
      expect(resClamped.calendarDaysInWindow, 18);
      expect(resClamped.daysOfData, 18);
      expect(resClamped.severityComparison?.status, ComparisonStatus.notEnoughData);

      // Daylight saving: 2026-10-28, period 7 contains 7 calendar days including 25 Oct
      final dstToday = DateTime(2026, 10, 28);
      final resDst = engine.analyzeWindow(logs: [], period: AnalysisPeriod.days7, today: dstToday);
      expect(resDst.windowStart, DateTime(2026, 10, 22));
      expect(resDst.windowEnd, DateTime(2026, 10, 28));
      expect(resDst.calendarDaysInWindow, 7);
    });

    test('T1-B: Day identification by calendar date, not timestamp', () {
      final logs = [
        createLog(date: DateTime(2026, 9, 19, 17, 3)),
        createLog(date: DateTime(2026, 9, 18, 0, 0)),
        createLog(date: DateTime(2026, 9, 18, 23, 59)),
      ];
      final res = engine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: DateTime(2026, 9, 19));
      expect(res.loggedDaysCount, 2);
    });

    test('T1-C: Logged, unlogged, symptom-free days & metrics', () {
      final today = DateTime(2026, 9, 19);
      // 7-day window, 5 logged days (first log on 13 Sep so history covers all 7 days)
      final logs5 = [
        createLog(date: DateTime(2026, 9, 13)),
        createLog(date: DateTime(2026, 9, 15)),
        createLog(date: DateTime(2026, 9, 16)),
        createLog(date: DateTime(2026, 9, 17)),
        createLog(date: DateTime(2026, 9, 18)),
      ];
      final res5 = engine.analyzeWindow(
        logs: logs5,
        period: AnalysisPeriod.days7,
        today: today,
        accountCreatedDate: DateTime(2026, 9, 13),
      );
      expect((res5.coverage * 100).round(), 71); // 5 logged / 7 days = 71.4%

      // Day A severe hot flash, Day B symptom-free (score 0), Day C unlogged
      final dayA = createLog(date: DateTime(2026, 9, 18), symptoms: [hotFlash('Severe')]);
      final dayB = createLog(date: DateTime(2026, 9, 19), symptoms: []);
      final resAB = engine.analyzeWindow(logs: [dayA, dayB], period: AnalysisPeriod.days7, today: today);
      final hf = resAB.symptomsMap['hot_flash']!;
      expect(hf.daysPresent, 1);
      expect(hf.dayRate, 0.5); // 1 present / 2 logged
      expect(hf.averageSeverity, 5.0);
      expect(hf.burden, 2.5); // (5 + 0) / 2

      // Incomplete log ignored
      final incomplete = createLog(date: DateTime(2026, 9, 17), isCompleted: false, symptoms: [hotFlash('Severe')]);
      final resIncomp = engine.analyzeWindow(logs: [dayA, dayB, incomplete], period: AnalysisPeriod.days7, today: today);
      expect(resIncomp.loggedDaysCount, 2);

      // Symptom present without severity counted in dayRate, excluded from average severity
      final noSevLog = createLog(date: DateTime(2026, 9, 19), symptoms: [createSymptom(id: 'mood', name: 'Mood', severity: null)]);
      final resNoSev = engine.analyzeWindow(logs: [noSevLog], period: AnalysisPeriod.day1, today: today);
      expect(resNoSev.symptomsMap['mood']!.daysPresent, 1);
      expect(resNoSev.symptomsMap['mood']!.averageSeverity, isNull);
    });

    test('T1-D: Severity normalization, rounding and labels', () {
      expect(AnalysisEngine.severityLabelForScore(1.7), 'Mild');
      expect(AnalysisEngine.severityLabelForScore(2.0), 'Moderate');
      expect(AnalysisEngine.severityLabelForScore(3.5), 'Moderate');
      expect(AnalysisEngine.severityLabelForScore(4.0), 'Severe');
      expect(AnalysisEngine.severityLabelForScore(4.3), 'Severe');
    });

    test('T1-E: Material change (SD-4)', () {
      // 2.0 -> 1.6: delta -0.4 (< 0.5) -> steady
      final c1 = MetricComparison.evaluate(current: 1.6, previous: 2.0, lowerIsBetter: true);
      expect(c1.changeType, MaterialChangeType.steady);

      // 2.0 -> 1.4: delta -0.6 and -30% -> improved
      final c2 = MetricComparison.evaluate(current: 1.4, previous: 2.0, lowerIsBetter: true);
      expect(c2.changeType, MaterialChangeType.improved);
      expect(c2.percentChange, -30);

      // 4.0 -> 3.5: delta -0.5 but only 12.5% (< 15%) -> steady
      final c3 = MetricComparison.evaluate(current: 3.5, previous: 4.0, lowerIsBetter: true);
      expect(c3.changeType, MaterialChangeType.steady);

      // 1.0 -> 1.6: +0.6 and +60% -> worsened
      final c4 = MetricComparison.evaluate(current: 1.6, previous: 1.0, lowerIsBetter: true);
      expect(c4.changeType, MaterialChangeType.worsened);

      // 0 -> 1.0: "new"
      final c5 = MetricComparison.evaluate(current: 1.0, previous: 0.0, lowerIsBetter: true);
      expect(c5.changeType, MaterialChangeType.newOccurrence);
      expect(c5.percentChange, isNull);

      // 1.0 -> 5.0: capped at 100%
      final c6 = MetricComparison.evaluate(current: 5.0, previous: 1.0, lowerIsBetter: true);
      expect(c6.changeType, MaterialChangeType.worsened);
      expect(c6.percentChange, 100);
    });

    test('T1-F: Comparison minimums', () {
      final today = DateTime(2026, 9, 19);
      // Period 7: needs 3 in both
      final logsCurr3 = List.generate(3, (i) => createLog(date: DateTime(2026, 9, 17 + i)));
      final logsPrev3 = List.generate(3, (i) => createLog(date: DateTime(2026, 9, 10 + i)));
      final logsPrev2 = List.generate(2, (i) => createLog(date: DateTime(2026, 9, 10 + i)));

      final res7Eligible = engine.analyzeWindow(logs: [...logsCurr3, ...logsPrev3], period: AnalysisPeriod.days7, today: today);
      expect(res7Eligible.severityComparison?.status, ComparisonStatus.eligible);

      final res7Ineligible = engine.analyzeWindow(logs: [...logsCurr3, ...logsPrev2], period: AnalysisPeriod.days7, today: today);
      expect(res7Ineligible.severityComparison?.status, ComparisonStatus.notEnoughData);

      // Period 1 never has delta
      final res1 = engine.analyzeWindow(logs: logsCurr3, period: AnalysisPeriod.day1, today: today);
      expect(res1.severityComparison?.status, ComparisonStatus.notEnoughData);
    });

    test('T1-G: Chart series preserves null for gaps', () {
      final today = DateTime(2026, 9, 19);
      // Log on 13 Sep and 15 Sep, 14 Sep unlogged
      final logs = [
        createLog(date: DateTime(2026, 9, 13), symptoms: [fatigue('Moderate')]),
        createLog(date: DateTime(2026, 9, 15), symptoms: [fatigue('Severe')]),
      ];
      final res = engine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: today);
      expect(res.chartSeries.points.length, 7);
      // Day 2 (14 Sep) must be null
      expect(res.chartSeries.points[1].value, isNull);
    });

    test('T1-H: Calendar week compares same weekdays', () {
      final today = DateTime(2026, 9, 19); // Saturday
      final logs = goldenDatasetLogs();
      final comp = engine.compareCalendarWeeks(logs: logs, today: today);
      expect(comp.status, ComparisonStatus.eligible);
    });

    test('T1-I: Trigger normalization and default counter immunity', () {
      final logWithDefaults = createLog(
        date: DateTime(2026, 9, 19),
        caffeineCups: 3,
        alcoholGlasses: 2,
        triggers: ['Stress · High'],
      );
      final pic = engine.analyzeDay(logWithDefaults, logWithDefaults.date, today: logWithDefaults.date);
      expect(pic.triggers.containsKey('stress'), isTrue);
      expect(pic.triggers['stress']!.level, 'High');
      // Coffee and Alcohol counters must NOT create events when not selected
      expect(pic.triggers.containsKey('coffee'), isFalse);
      expect(pic.triggers.containsKey('alcohol'), isFalse);

      // Legacy key merge
      final legacyLog = createLog(
        date: DateTime(2026, 9, 8),
        triggers: ['Exercise · 10 min', 'workout · 10 min'],
      );
      final picLegacy = engine.analyzeDay(legacyLog, legacyLog.date, today: legacyLog.date);
      expect(picLegacy.triggers.containsKey('exercise'), isTrue);
      expect(picLegacy.triggers.length, 1);
    });

    test('T1-J: Sleep trust gate', () {
      // 15 of 18 days identical (83%) -> suppressed
      final gLogs = goldenDatasetLogs();
      final res = engine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(res.isSleepTrusted, isFalse);
      expect(res.averageSleepHours, isNotNull);

      // 12 of 18 identical (67%) -> trusted
      final variedLogs = List.generate(18, (i) => createLog(
        date: DateTime(2026, 9, 2 + i),
        sleepDuration: i < 12 ? 7.5 : (6.0 + i * 0.2),
      ));
      final resVaried = engine.analyzeWindow(logs: variedLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(resVaried.isSleepTrusted, isTrue);
    });

    test('T1-K: Recalculation & order independence', () {
      final gLogs = goldenDatasetLogs();
      final shuffled = shuffleLogs(gLogs);

      final r1 = engine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final r2 = engine.analyzeWindow(logs: shuffled, period: AnalysisPeriod.days30, today: kToday);

      expect(r1.coverage, equals(r2.coverage));
      expect(r1.averageSeverity, equals(r2.averageSeverity));
      expect(r1.symptomRankings.length, equals(r2.symptomRankings.length));
      assertInvariants(gLogs, r1);
    });
  });
}
