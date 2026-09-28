import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const analysisEngine = AnalysisEngine();
  const patternEngine = PatternEngine();
  const hrtAnalyzer = HrtChangeAnalyzer();
  const selector = HomeInsightSelector();
  const calc = WeeklyTrendsCalculator();

  group('T10 Golden Dataset Cross-Surface & Invariants Tests', () {
    final gLogs = goldenDatasetLogs();

    test('G-1: Logged days / coverage / consistency (18 of 18, 100%, 100%)', () {
      final res = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(res.loggedDaysCount, 18);
      expect(res.coverage, 1.0);
      expect(res.consistency, 1.0);
    });

    test('G-2: Symptom frequency in Golden Dataset (fatigue 16, hot_flash 11, night_sweats 11, night_wakings 7, difficulty_falling_asleep 3)', () {
      final res = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(res.symptomsMap['fatigue']?.daysPresent, 16);
      expect(res.symptomsMap['hot_flash']?.daysPresent, 11);
      expect(res.symptomsMap['night_sweats']?.daysPresent, 11);
      expect(res.symptomsMap['night_wakings']?.daysPresent, 7);
      expect(res.symptomsMap['difficulty_falling_asleep']?.daysPresent, 3);
    });

    test('G-3: Average severity 3.2 (Moderate)', () {
      final res = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(res.averageSeverity, closeTo(3.17, 0.05));
      expect(res.severityLabel, 'Moderate');
    });

    test('G-4: Last 7 days vs previous 7 steady', () {
      final res7 = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days7, today: kToday);
      expect(res7.severityComparison?.changeType, MaterialChangeType.steady);
    });

    test('G-5: Sleep trust gate suppresses sleep insights', () {
      final res = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(res.isSleepTrusted, isFalse);
    });

    test('G-6: Trigger events count correctly and default counters are ignored', () {
      final pRes = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final alcPattern = pRes.patterns.firstWhere((p) => p.triggerId == 'alcohol');
      expect(alcPattern.eventCount, 11);
    });

    test('G-7: Displayed patterns strongest first', () {
      final pRes = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(pRes.patterns.isNotEmpty, isTrue);
      // Alcohol -> fatigue should be strongest
      expect(pRes.patterns.first.triggerId, 'alcohol');
    });

    test('G-11: No high confidence chips in Golden Dataset', () {
      final pRes = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      for (final p in pRes.patterns) {
        expect(p.confidence, PatternConfidence.standard);
      }
    });

    test('G-12: Regimen groups newest first and orphan change analyzed', () {
      final hrtRes = hrtAnalyzer.analyze(
        doseChanges: goldenHrtDoseChanges(),
        medications: goldenMedications(),
        logs: gLogs,
        today: kToday,
      );
      expect(hrtRes.groups.isNotEmpty, isTrue);
      final newest = hrtRes.groups.first;
      expect(newest.status, HrtChangeStatus.pending);
      expect(newest.daysToGo, 8); // 14 - 6 = 8
    });

    test('G-13: Home Daily Insight shows D-4 for alcohol', () {
      final a30 = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final a7 = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days7, today: kToday);
      final pRes = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final hrtRes = hrtAnalyzer.analyze(
        doseChanges: goldenHrtDoseChanges(),
        medications: goldenMedications(),
        logs: gLogs,
        today: kToday,
      );

      final bundle = selector.selectInsights(
        logs: gLogs,
        today: kToday,
        analysis30: a30,
        analysis7: a7,
        patternsResult: pRes,
        hrtResult: hrtRes,
        medications: goldenMedications(),
      );
      expect(bundle.dailyInsight.candidateType, 'D-4');
    });

    test('G-15: High Severity Alert not shown for Golden Dataset', () {
      final a30 = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final a7 = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days7, today: kToday);
      final pRes = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);

      final bundle = selector.selectInsights(
        logs: gLogs,
        today: kToday,
        analysis30: a30,
        analysis7: a7,
        patternsResult: pRes,
        hrtResult: const HrtAnalysisResult(groups: []),
        medications: const [],
      );
      expect(bundle.highSeverityAlert, isNull);
    });

    test('G-16: Tracker week 14-20 Sep calculations', () {
      final tData = calc.calculate(logs: gLogs, selectedDate: kToday, today: kToday);
      expect(tData.currentWeekLoggedDays, 6);
      expect(tData.previousWeekLoggedDays, 7);
      expect(tData.hasEnoughDataForValues, isTrue);
      expect(tData.hasEnoughDataForComparison, isTrue);
    });

    test('Robustness & Invariants: Shuffled log order gives identical results', () {
      final shuffled = shuffleLogs(gLogs, 77);

      final a30 = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final a30Shuffled = analysisEngine.analyzeWindow(logs: shuffled, period: AnalysisPeriod.days30, today: kToday);
      expect(a30.averageSeverity, equals(a30Shuffled.averageSeverity));
      expect(a30.coverage, equals(a30Shuffled.coverage));

      final pRes = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final pResShuffled = patternEngine.analyze(logs: shuffled, period: AnalysisPeriod.days30, today: kToday);
      expect(pRes.patterns.length, equals(pResShuffled.patterns.length));
    });

    test('Robustness: Empty logs produce no exception, NaN, or infinity across all surfaces', () {
      final empty30 = analysisEngine.analyzeWindow(logs: [], period: AnalysisPeriod.days30, today: kToday);
      expect(empty30.loggedDaysCount, 0);
      expect(empty30.coverage, 0.0);

      final emptyPatterns = patternEngine.analyze(logs: [], period: AnalysisPeriod.days30, today: kToday);
      expect(emptyPatterns.patterns, isEmpty);

      final emptyTracker = calc.calculate(logs: [], selectedDate: kToday, today: kToday);
      expect(emptyTracker.hasEnoughDataForValues, isFalse);
    });
  });
}
