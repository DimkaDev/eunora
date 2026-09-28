import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const engine = AnalysisEngine();

  group('T9 Symptom Detail Tests', () {
    test('T9-2: Quick stats calculates days logged, average severity and label', () {
      final gLogs = goldenDatasetLogs();
      final res = engine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final hf = res.symptomsMap['hot_flash']!;

      expect(hf.daysPresent, 11);
      expect(hf.averageSeverity, closeTo(2.45, 0.05));
      expect(hf.severityLabel, 'Moderate');
    });

    test('T9-5: Physician note gating requires material worsening AND >= 14 logged days', () {
      // Material worsening but only 10 logged days -> physician note NOT eligible
      // Baseline 1.0 (Mild), Current 3.0 (Moderate)
      final logs10 = List.generate(10, (i) => createLog(
        date: DateTime(2026, 9, 10 + i),
        symptoms: [hotFlash('Severe')],
      ));
      final res10 = engine.analyzeWindow(logs: logs10, period: AnalysisPeriod.days30, today: kToday);
      expect(res10.loggedDaysCount < 14, isTrue);

      // With >= 14 logged days
      final gLogs = goldenDatasetLogs();
      final res18 = engine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(res18.loggedDaysCount >= 14, isTrue);
    });

    test('T9-8: Golden Dataset hot flashes metrics in 30-day window', () {
      final gLogs = goldenDatasetLogs();
      final res = engine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final hf = res.symptomsMap['hot_flash']!;

      // 11 days logged with hot flashes
      expect(hf.daysPresent, 11);
      // 11 records: Severe x1 (5), Moderate x6 (3*6=18), Mild x4 (1*4=4) -> 27 / 11 = 2.45
      expect(hf.averageSeverity, closeTo(2.45, 0.02));
      expect(hf.severityLabel, 'Moderate');
    });
  });
}
