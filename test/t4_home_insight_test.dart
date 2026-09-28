import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const selector = HomeInsightSelector();
  const analysisEngine = AnalysisEngine();
  const patternEngine = PatternEngine();

  group('T4 Home Insight Tests', () {
    test('T4-D-1: D-1 Symptom-free day when baseline >= 3 logged days', () {
      final today = DateTime(2026, 9, 20);
      final logs = [
        createLog(date: DateTime(2026, 9, 17), symptoms: [hotFlash('Moderate')]),
        createLog(date: DateTime(2026, 9, 18), symptoms: [hotFlash('Moderate')]),
        createLog(date: DateTime(2026, 9, 19), symptoms: [hotFlash('Moderate')]),
        createLog(date: today, symptoms: []), // Symptom-free today
      ];
      final a30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: today);
      final a7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: today);
      final p = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: today);

      final bundle = selector.selectInsights(
        logs: logs,
        today: today,
        analysis30: a30,
        analysis7: a7,
        patternsResult: p,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );
      expect(bundle.dailyInsight.candidateType, 'D-1');
      expect(bundle.dailyInsight.headline, contains('No symptoms logged today'));
    });

    test('T4-D-2: D-2 Milder than usual when today at least 0.5 below norm', () {
      final today = DateTime(2026, 9, 20);
      // Baseline average is 3.0 (Moderate)
      final baselineLogs = List.generate(7, (i) => createLog(
        date: DateTime(2026, 9, 12 + i),
        symptoms: [hotFlash('Moderate')],
      ));
      // Today is 1.0 (Mild) -> 1.0 vs 3.0 (2.0 below norm)
      final todayLog = createLog(date: today, symptoms: [hotFlash('Mild')]);
      final logs = [...baselineLogs, todayLog];

      final a30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: today);
      final a7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: today);
      final p = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: today);

      final bundle = selector.selectInsights(
        logs: logs,
        today: today,
        analysis30: a30,
        analysis7: a7,
        patternsResult: p,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );
      expect(bundle.dailyInsight.candidateType, 'D-2');
      expect(bundle.dailyInsight.tag, HomeInsightTag.positiveTrend);
      expect(bundle.dailyInsight.headline, contains('milder than your usual'));
    });

    test('T4-D-3: D-3 Stronger than usual when today at least 0.5 above norm', () {
      final today = DateTime(2026, 9, 20);
      final baselineLogs = List.generate(7, (i) => createLog(
        date: DateTime(2026, 9, 12 + i),
        symptoms: [hotFlash('Moderate')],
      ));
      // Today is 5.0 (Severe) -> 5.0 vs 3.0 (2.0 above norm)
      final todayLog = createLog(date: today, symptoms: [hotFlash('Severe')]);
      final logs = [...baselineLogs, todayLog];

      final a30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: today);
      final a7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: today);
      final p = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: today);

      final bundle = selector.selectInsights(
        logs: logs,
        today: today,
        analysis30: a30,
        analysis7: a7,
        patternsResult: p,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );
      expect(bundle.dailyInsight.candidateType, 'D-3');
      expect(bundle.dailyInsight.tag, HomeInsightTag.worthNoting);
      expect(bundle.dailyInsight.headline, contains('stronger than your usual'));
    });

    test('T4-D-7: D-4 Trigger logged today with ready pattern', () {
      final today = DateTime(2026, 9, 20);
      // Alcohol logged today, alcohol -> fatigue pattern ready
      final logs = goldenDatasetLogs();
      final a30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: kToday);
      final a7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: kToday);
      final p = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: kToday);

      final bundle = selector.selectInsights(
        logs: logs,
        today: kToday,
        analysis30: a30,
        analysis7: a7,
        patternsResult: p,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );
      expect(bundle.dailyInsight.candidateType, 'D-4');
      expect(bundle.dailyInsight.headline, contains('tends to be stronger'));
    });

    test('T4-W-1: W-1 Overall material improvement vs previous 7 days', () {
      final today = DateTime(2026, 9, 20);
      // Current week (14-20 Sep): 5 logged, average 2.0 (Mild/Moderate mix)
      final currLogs = List.generate(5, (i) => createLog(
        date: DateTime(2026, 9, 14 + i),
        symptoms: [hotFlash('Mild'), hotFlash('Moderate')], // mean 2.0
      ));
      // Previous week (7-13 Sep): 4 logged, average 3.0 (Moderate)
      final prevLogs = List.generate(4, (i) => createLog(
        date: DateTime(2026, 9, 7 + i),
        symptoms: [hotFlash('Moderate')], // 3.0
      ));
      final logs = [...prevLogs, ...currLogs];

      final a30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: today);
      final a7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: today);
      final p = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: today);

      final bundle = selector.selectInsights(
        logs: logs,
        today: today,
        analysis30: a30,
        analysis7: a7,
        patternsResult: p,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );
      expect(bundle.weeklyInsight.candidateType, 'W-1');
      expect(bundle.weeklyInsight.tag, HomeInsightTag.positiveTrend);
      expect(bundle.weeklyInsight.headline, contains('improved'));
    });

    test('T4 High Severity Alert: fires on 3 consecutive severe hot flashes only', () {
      final today = DateTime(2026, 9, 19);
      // Hot flashes severe on 17, 18, 19 Sep
      final logs = [
        createLog(date: DateTime(2026, 9, 17), symptoms: [hotFlash('Severe')]),
        createLog(date: DateTime(2026, 9, 18), symptoms: [hotFlash('Severe')]),
        createLog(date: DateTime(2026, 9, 19), symptoms: [hotFlash('Severe')]),
      ];
      final a30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: today);
      final a7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: today);
      final p = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: today);

      final bundle = selector.selectInsights(
        logs: logs,
        today: today,
        analysis30: a30,
        analysis7: a7,
        patternsResult: p,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );
      expect(bundle.highSeverityAlert, isNotNull);
      expect(bundle.highSeverityAlert!.isActive, isTrue);

      // Does NOT fire if one day in sequence is unlogged (gap)
      final logsGap = [
        createLog(date: DateTime(2026, 9, 17), symptoms: [hotFlash('Severe')]),
        createLog(date: DateTime(2026, 9, 19), symptoms: [hotFlash('Severe')]),
      ];
      final bundleGap = selector.selectInsights(
        logs: logsGap,
        today: today,
        analysis30: a30,
        analysis7: a7,
        patternsResult: p,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );
      expect(bundleGap.highSeverityAlert, isNull);
    });
  });
}
