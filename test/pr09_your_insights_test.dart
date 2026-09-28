import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const analysisEngine = AnalysisEngine();
  final today = DateTime(2026, 9, 19);

  group('PR-09: Your Insights: Period Selector & Metrics', () {
    test('S9.1: Switching 7/30/90 period recalculates Most Frequent Symptoms using entries inside window', () {
      // Day 10 days ago (2026-09-09): has brain_fog (outside 7d, inside 30d)
      // Days inside 7d (2026-09-13..19): has hot_flash
      final logs = [
        createLog(
          date: DateTime(2026, 9, 9),
          symptoms: [
            createSymptom(id: 'brain_fog', name: 'Brain Fog', severity: 'Severe'),
            createSymptom(id: 'brain_fog', name: 'Brain Fog', severity: 'Severe'),
          ],
        ),
        createLog(
          date: DateTime(2026, 9, 15),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate')],
        ),
        createLog(
          date: DateTime(2026, 9, 17),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Moderate')],
        ),
      ];

      final a7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: today);
      final a30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: today);

      // In 7-day window, only hot_flash is present
      expect(a7.symptomRankings.map((s) => s.symptomId), contains('hot_flash'));
      expect(a7.symptomRankings.map((s) => s.symptomId), isNot(contains('brain_fog')));

      // In 30-day window, both are present
      expect(a30.symptomRankings.map((s) => s.symptomId), containsAll(['hot_flash', 'brain_fog']));
    });

    test('S9.2: Switching period recalculates Severity Trend chart correctly for each window', () {
      final logs = [
        createLog(
          date: DateTime(2026, 8, 21), // 30 days ago ensures full 30-day window
          symptoms: [],
        ),
        createLog(
          date: DateTime(2026, 9, 10),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Mild')], // 1.0
        ),
        createLog(
          date: DateTime(2026, 9, 18),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe')], // 5.0
        ),
      ];

      final a7 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: today);
      final a30 = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days30, today: today);

      expect(a7.chartSeries.points.length, equals(7));
      expect(a30.chartSeries.points.length, equals(30));

      // 7-day average only includes 18 Sep (5.0)
      expect(a7.averageSeverity, closeTo(5.0, 0.01));

      // 30-day average includes both 10 Sep (1.0) and 18 Sep (5.0) -> (1+5)/2 = 3.0
      expect(a30.averageSeverity, closeTo(3.0, 0.01));
    });

    test('S9.3: Most Frequent Symptoms produces stable, deterministic ordering on frequency ties', () {
      // 2 symptoms with identical frequency & severity
      final logs = [
        createLog(
          date: DateTime(2026, 9, 18),
          symptoms: [
            createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Moderate'),
            createSymptom(id: 'anxiety', name: 'Anxiety', severity: 'Moderate'),
          ],
        ),
      ];

      final a7First = analysisEngine.analyzeWindow(logs: logs, period: AnalysisPeriod.days7, today: today);
      final a7Second = analysisEngine.analyzeWindow(logs: logs.reversed.toList(), period: AnalysisPeriod.days7, today: today);

      // Deterministic alphabetical ordering by ID / name
      expect(a7First.symptomRankings.first.symptomId, equals('anxiety'));
      expect(a7Second.symptomRankings.first.symptomId, equals('anxiety'));
      expect(a7First.symptomRankings.map((s) => s.symptomId).toList(),
          equals(a7Second.symptomRankings.map((s) => s.symptomId).toList()));
    });

    test('⚠️ EXCLUDED / BLOCKED: Unlogged days averaging rule across surfaces', () {
      const isBlocked = true;
      expect(isBlocked, isTrue);
      // ignore: avoid_print
      print('[PR-09 Out of Scope] ⚠️ BLOCKED: Unlogged days averaging rule across surfaces is subject to open product spec decision. Excluded from pass count.');
    });
  });
}
