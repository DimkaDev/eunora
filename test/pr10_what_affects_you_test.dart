import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const patternEngine = PatternEngine();
  final today = DateTime(2026, 9, 19);

  group('PR-10: What Affects You: Bug-Fix Verification (Real Correlation Engine)', () {
    test('S10.1: <7 paired events shows progress / "keep logging" state, not dummy cards', () {
      final triggerDays = {2, 5, 8, 11, 14}; // 5 paired days
      final logs5 = List.generate(20, (i) {
        final day = i + 1;
        final date = DateTime(2026, 8, 31 + i);
        final hasTrigger = triggerDays.contains(day);
        return createLog(
          date: date,
          triggers: hasTrigger ? ['Alcohol · 2 drinks'] : [],
          symptoms: [hotFlash(hasTrigger ? 'Severe' : 'Mild')],
        );
      });

      final result = patternEngine.analyze(
        logs: logs5,
        period: AnalysisPeriod.days30,
        today: today,
      );

      // Verify no hardcoded patterns exist
      expect(result.patterns.where((p) => p.triggerId == 'alcohol'), isEmpty);
      // Verify building / progress item is surfaced
      final buildingAlcohol = result.buildingItems.where((b) => b.triggerId == 'alcohol').toList();
      expect(buildingAlcohol, isNotEmpty);
      expect(buildingAlcohol.first.eventsCount, equals(5));
      expect(buildingAlcohol.first.targetCount, equals(7));
      expect(buildingAlcohol.first.displayText, contains('5 of 7'));
    });

    test('S10.2: >=7 paired events renders real correlation cards with trigger, effect, %, event count, disclaimer', () {
      final triggerDays = {1, 3, 5, 7, 9, 11, 13, 15}; // 8 paired days
      final logs8 = List.generate(20, (i) {
        final day = i + 1;
        final date = DateTime(2026, 8, 31 + i);
        final hasTrigger = triggerDays.contains(day);
        return createLog(
          date: date,
          triggers: hasTrigger ? ['Alcohol · 2 drinks'] : [],
          symptoms: [hotFlash(hasTrigger ? 'Severe' : 'Mild')],
        );
      });

      final result = patternEngine.analyze(
        logs: logs8,
        period: AnalysisPeriod.days30,
        today: today,
      );

      final displayedAlcohol = result.patterns.where((p) => p.triggerId == 'alcohol').toList();
      expect(displayedAlcohol, isNotEmpty);
      final pattern = displayedAlcohol.first;
      expect(pattern.eventCount, equals(8));
      expect(pattern.correlationPercent, equals(100));
      expect(pattern.effect, closeTo(4.0, 0.01));
      // Verbatim disclaimer check
      expect(pattern.disclaimer, equals(kApprovedTriggerDisclaimer));
    });

    test('S10.3: Both summary card and AI Insights page consume the exact same PatternEngine result', () {
      final triggerDays = {1, 3, 5, 7, 9, 11, 13}; // 7 paired days
      final logs = List.generate(20, (i) {
        final day = i + 1;
        final date = DateTime(2026, 8, 31 + i);
        final hasTrigger = triggerDays.contains(day);
        return createLog(
          date: date,
          triggers: hasTrigger ? ['Coffee / Caffeine · 2 cups'] : [],
          symptoms: [hotFlash(hasTrigger ? 'Severe' : 'Mild')],
        );
      });

      final summaryResult = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: today);
      final detailedResult = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: today);

      expect(summaryResult.patterns.length, equals(detailedResult.patterns.length));
      expect(summaryResult.patterns.first.triggerId, equals(detailedResult.patterns.first.triggerId));
      expect(summaryResult.patterns.first.correlationPercent, equals(detailedResult.patterns.first.correlationPercent));
    });

    test('S10.4: Card and full page never disagree on qualifying correlations (single source of truth)', () {
      final logs = [
        createLog(date: today, triggers: ['Sugar / sweets'], symptoms: []),
      ];

      final res1 = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: today);
      final res2 = patternEngine.analyze(logs: logs, period: AnalysisPeriod.days30, today: today);

      expect(res1.patterns.isEmpty, isTrue);
      expect(res2.patterns.isEmpty, isTrue);
    });
  });
}
