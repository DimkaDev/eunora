import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const engine = AnalysisEngine();

  group('T5 Trend Detail Tests', () {
    test('T5-1 & T5-11: Golden Dataset overall severity, period 30 matches header metrics', () {
      final gLogs = goldenDatasetLogs();
      final res = engine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);

      expect(res.loggedDaysCount, 18);
      expect(res.coverage, 1.0); // 18 of 18 days
      expect(res.averageSeverity, closeTo(3.17, 0.05));
      expect(res.severityLabel, 'Moderate');
    });

    test('T5-2: 7-day series with unlogged day preserves null gap', () {
      final logs = [
        createLog(date: DateTime(2026, 9, 13), symptoms: [fatigue('Moderate')]),
        // 14 Sep unlogged
        createLog(date: DateTime(2026, 9, 15), symptoms: [fatigue('Severe')]),
      ];
      final res = engine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: kToday);
      expect(res.chartSeries.points.length, 7);
      expect(res.chartSeries.points[1].isGap, isTrue);
      expect(res.chartSeries.points[1].value, isNull);
    });

    test('T5-3: 90-day series has weekly buckets', () {
      final gLogs = goldenDatasetLogs();
      final res = engine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days90, today: kToday);
      expect(res.chartSeries.isWeekly, isTrue);
      expect(res.chartSeries.points.isNotEmpty, isTrue);
    });

    test('T5-8: Symptom table metrics match foundation metrics', () {
      final gLogs = goldenDatasetLogs();
      final res = engine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final fatigueMetric = res.symptomsMap['fatigue']!;
      expect(fatigueMetric.daysPresent, 16);
      expect(fatigueMetric.averageSeverity, isNotNull);
    });

    test('T5-9: Sleep gate failure suppresses sleep insights', () {
      final gLogs = goldenDatasetLogs();
      final res = engine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(res.isSleepTrusted, isFalse);
    });

    test('T5-10: Period with no logs returns calm safe state without NaN', () {
      final res = engine.analyzeWindow(logs: [], period: AnalysisPeriod.days30, today: kToday);
      expect(res.loggedDaysCount, 0);
      expect(res.averageSeverity, isNull);
      expect(res.coverage, 0.0);
      expect(res.chartSeries.points.every((p) => p.isGap), isTrue);
    });
  });
}
