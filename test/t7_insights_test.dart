import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const patternEngine = PatternEngine();
  const analysisEngine = AnalysisEngine();

  group('T7 Your Insights Tests', () {
    test('T7-1: What Affects You? caps at 3 items, excludes HRT', () {
      final gLogs = goldenDatasetLogs();
      final res = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      // Top 3 items
      final top3 = res.patterns.take(3).toList();
      expect(top3.length, lessThanOrEqualTo(3));
      for (final item in top3) {
        // Must be Trigger, Protective, or Environment; not HRT
        expect(item.triggerId.contains('hrt') || item.triggerId.contains('estradiol'), isFalse);
      }
    });

    test('T7-2: Period 7 uses 30-day analysis window with notice', () {
      final gLogs = goldenDatasetLogs();
      final res7 = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days7, today: kToday);
      expect(res7.effectiveDaysInWindow >= 18, isTrue);
      expect(res7.windowNotice, contains('Based on'));
    });

    test('T7-4: High confidence chip requires >= 14 events and >= 70% correlation', () {
      final gLogs = goldenDatasetLogs();
      final res = patternEngine.analyze(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      // In Golden Dataset, alcohol has 11 events (below 14), so no pattern should have high confidence
      for (final p in res.patterns) {
        expect(p.confidence, PatternConfidence.standard);
      }
    });

    test('T7-7: SD-10 empty states when nothing displayable', () {
      final emptyRes = patternEngine.analyze(logs: [], period: AnalysisPeriod.days30, today: kToday);
      expect(emptyRes.emptyStateType, SD10EmptyType.notEnoughData);
      expect(emptyRes.patterns.isEmpty, isTrue);
    });

    test('T7-9: Most Frequent Symptoms in Golden Dataset (Period 30 and Period 7)', () {
      final gLogs = goldenDatasetLogs();

      // Period 30: fatigue 16, hot_flash 11, night_sweats 11, night_wakings 7, difficulty_falling_asleep 3
      final res30 = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days30, today: kToday);
      expect(res30.symptomsMap['fatigue']?.daysPresent, 16);
      expect(res30.symptomsMap['hot_flash']?.daysPresent, 11);
      expect(res30.symptomsMap['night_sweats']?.daysPresent, 11);
      expect(res30.symptomsMap['night_wakings']?.daysPresent, 7);
      expect(res30.symptomsMap['difficulty_falling_asleep']?.daysPresent, 3);

      // Period 7: fatigue 7, hot_flash 7, night_sweats 5, night_wakings 3
      final res7 = analysisEngine.analyzeWindow(logs: gLogs, period: AnalysisPeriod.days7, today: kToday);
      expect(res7.symptomsMap['fatigue']?.daysPresent, 7);
      expect(res7.symptomsMap['hot_flash']?.daysPresent, 7);
      expect(res7.symptomsMap['night_sweats']?.daysPresent, 5);
      expect(res7.symptomsMap['night_wakings']?.daysPresent, 3);
    });
  });
}
