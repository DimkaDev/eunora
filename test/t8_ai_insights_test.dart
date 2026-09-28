import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const patternEngine = PatternEngine();
  const hrtAnalyzer = HrtChangeAnalyzer();

  group('T8 AI Insights Page Tests', () {
    test('T8-1: Hero count equals number of displayed pattern cards', () {
      final gLogs = goldenDatasetLogs();
      final res = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(res.patterns.length, greaterThan(0));
      expect(res.patterns.length <= 5, isTrue);

      final emptyRes = patternEngine.analyze(logs: [], period: AnalysisPeriod.days30, today: kToday);
      expect(emptyRes.patterns.length, 0);
      expect(emptyRes.emptyStateType, isNot(SD10EmptyType.none));
    });

    test('T8-2: Caps and order (patterns <= 5, building <= 3, HRT groups newest first)', () {
      final gLogs = goldenDatasetLogs();
      final pRes = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(pRes.patterns.length <= 5, isTrue);
      expect(pRes.buildingItems.length <= 3, isTrue);

      final hrtRes = hrtAnalyzer.analyze(
        doseChanges: goldenHrtDoseChanges(),
        medications: goldenMedications(),
        logs: gLogs,
        today: kToday,
      );
      expect(hrtRes.groups.length <= 5, isTrue);
      if (hrtRes.groups.length >= 2) {
        expect(hrtRes.groups[0].changeDate.isAfter(hrtRes.groups[1].changeDate) ||
            hrtRes.groups[0].changeDate.isAtSameMomentAs(hrtRes.groups[1].changeDate), isTrue);
      }
    });

    test('T8-3: Disclaimers shown without tap', () {
      final gLogs = goldenDatasetLogs();
      final pRes = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      for (final p in pRes.patterns) {
        expect(p.disclaimer, kApprovedTriggerDisclaimer);
      }

      final hrtRes = hrtAnalyzer.analyze(
        doseChanges: goldenHrtDoseChanges(),
        medications: goldenMedications(),
        logs: gLogs,
        today: kToday,
      );
      for (final g in hrtRes.groups) {
        expect(g.disclaimer, kApprovedHrtDisclaimer);
      }
    });

    test('T8-4: Pattern detail numbers match card', () {
      final gLogs = goldenDatasetLogs();
      final pRes = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final alcPattern = pRes.patterns.firstWhere((p) => p.triggerId == 'alcohol');
      expect(alcPattern.eventCount, 11);
      expect(alcPattern.exposedAverage, closeTo(3.4, 0.2));
      expect(alcPattern.unexposedAverage, closeTo(1.9, 0.2));
    });

    test('T8-8: Determinism under log shuffle', () {
      final gLogs = goldenDatasetLogs();
      final shuffled = shuffleLogs(gLogs, 99);

      final r1 = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      final r2 = patternEngine.analyze(logs: shuffled, period: AnalysisPeriod.days30, today: kToday);

      expect(r1.patterns.length, equals(r2.patterns.length));
      for (int i = 0; i < r1.patterns.length; i++) {
        expect(r1.patterns[i].triggerId, equals(r2.patterns[i].triggerId));
        expect(r1.patterns[i].correlationPercent, equals(r2.patterns[i].correlationPercent));
      }
    });
  });
}
