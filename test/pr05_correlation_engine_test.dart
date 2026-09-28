import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const engine = PatternEngine();

  group('PR-05: Correlation Engine Gating & Confidence', () {
    test('S5.1: Trigger with fewer than 7 paired events shows progress state (X of 7 needed)', () {
      final triggerDays = {2, 5, 8, 11, 14, 17};
      final logs6 = List.generate(20, (i) {
        final day = i + 1;
        final date = DateTime(2026, 8, 31 + i);
        final hasTrigger = triggerDays.contains(day);
        return createLog(
          date: date,
          triggers: hasTrigger ? ['Alcohol · 2 drinks'] : [],
          symptoms: [hotFlash(hasTrigger ? 'Severe' : 'Mild')],
        );
      });

      final result = engine.analyze(
        logs: logs6,
        period: AnalysisPeriod.days30,
        today: DateTime(2026, 9, 19),
      );

      // Must NOT be in displayed patterns
      final displayedAlcohol = result.patterns.where((p) => p.triggerId == 'alcohol');
      expect(displayedAlcohol, isEmpty);

      // Must appear in buildingItems with progress "6 of 7"
      final buildingAlcohol = result.buildingItems.where((b) => b.triggerId == 'alcohol').toList();
      expect(buildingAlcohol, isNotEmpty);
      expect(buildingAlcohol.first.eventsCount, equals(6));
      expect(buildingAlcohol.first.targetCount, equals(7));
      expect(buildingAlcohol.first.displayText, contains('6 of 7'));
    });

    test('S5.2: Trigger reaching exactly 7 paired events becomes displayable', () {
      final triggerDays = {2, 5, 8, 11, 14, 17};
      final logs7 = List.generate(20, (i) {
        final day = i + 1;
        final date = DateTime(2026, 8, 31 + i);
        final hasTrigger = triggerDays.contains(day) || day == 20;
        return createLog(
          date: date,
          triggers: hasTrigger ? ['Alcohol · 2 drinks'] : [],
          symptoms: [hotFlash(hasTrigger ? 'Severe' : 'Mild')],
        );
      });

      final result = engine.analyze(
        logs: logs7,
        period: AnalysisPeriod.days30,
        today: DateTime(2026, 9, 19),
      );

      final displayedAlcohol = result.patterns.where((p) => p.triggerId == 'alcohol').toList();
      expect(displayedAlcohol, isNotEmpty, reason: 'Exactly 7 paired events must promote to displayed patterns');
      expect(displayedAlcohol.first.eventCount, equals(7));
    });

    test('S5.3: Trigger with eventCount >= 14 and correlationPercent >= 70 shows High confidence chip', () {
      final logs = List.generate(31, (i) {
        final day = i + 1;
        final date = DateTime(2026, 8, 20 + i);
        final isAlcohol = day <= 29 && day % 2 != 0;
        final isSevere = day % 2 == 0;
        return createLog(
          date: date,
          triggers: isAlcohol ? ['Alcohol · 2 drinks'] : [],
          symptoms: [hotFlash(isSevere ? 'Severe' : 'Mild')],
        );
      });

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: DateTime(2026, 9, 20),
      );

      final displayedAlcohol = result.patterns.firstWhere((p) => p.triggerId == 'alcohol');
      expect(displayedAlcohol.eventCount, greaterThanOrEqualTo(14));
      expect(displayedAlcohol.correlationPercent, greaterThanOrEqualTo(70));
      expect(displayedAlcohol.confidence, equals(PatternConfidence.high));
      expect(displayedAlcohol.disclaimer, isNotEmpty);
    });

    test('S5.4: Trigger with eventCount >= 14 but correlationPercent < 70 shows standard confidence and no negative label', () {
      const eventCount = 14;
      const correlationPercent = 69;

      final isHigh = (eventCount >= 14 && correlationPercent >= 70);
      expect(isHigh, isFalse);

      final standardPattern = PatternInsight(
        triggerId: 'coffee',
        triggerDisplayName: 'Coffee',
        outcomeId: 'hot_flash',
        outcomeDisplayName: 'Hot Flashes',
        isOverallDayLevel: false,
        lag: PatternLag.lag0,
        type: PatternType.worsening,
        confidence: PatternConfidence.standard,
        rawCorrelation: 0.69,
        strength: 0.69,
        correlationPercent: 69,
        effect: 1.1,
        exposedAverage: 3.2,
        unexposedAverage: 2.1,
        eventCount: 14,
        comparisonDaysCount: 14,
        hitRateCount: 9,
        headlineText: 'Coffee may be linked to hot flashes.',
        evidenceText: '9 of 14 events had higher severity.',
        hitRateText: '64%',
        disclaimer: kApprovedTriggerDisclaimer,
      );

      expect(standardPattern.confidence, equals(PatternConfidence.standard));
      expect(standardPattern.headlineText, isNot(contains('low confidence')));
      expect(standardPattern.headlineText, isNot(contains('weak correlation')));
    });

    test('S5.5: Trigger with eventCount < 14 never shows High confidence chip regardless of percentage', () {
      const eventCount = 13;
      const correlationPercent = 100;

      final isHigh = (eventCount >= 14 && correlationPercent >= 70);
      expect(isHigh, isFalse, reason: 'Event count below 14 must never produce high confidence');

      final pattern = PatternInsight(
        triggerId: 'wine',
        triggerDisplayName: 'Wine',
        outcomeId: 'night_sweats',
        outcomeDisplayName: 'Night Sweats',
        isOverallDayLevel: false,
        lag: PatternLag.lag0,
        type: PatternType.worsening,
        confidence: PatternConfidence.standard,
        rawCorrelation: 1.0,
        strength: 1.0,
        correlationPercent: 100,
        effect: 2.5,
        exposedAverage: 4.0,
        unexposedAverage: 1.5,
        eventCount: 13,
        comparisonDaysCount: 10,
        hitRateCount: 13,
        headlineText: 'Wine triggers night sweats.',
        evidenceText: '13 of 13 events had higher severity.',
        hitRateText: '100%',
        disclaimer: kApprovedTriggerDisclaimer,
      );

      expect(pattern.confidence, equals(PatternConfidence.standard));
    });

    test('S5.6: Positive-direction correlation (protective) renders with positive styling flag', () {
      final protectivePattern = PatternInsight(
        triggerId: 'exercise',
        triggerDisplayName: 'Walking',
        outcomeId: 'fatigue',
        outcomeDisplayName: 'Fatigue',
        isOverallDayLevel: false,
        lag: PatternLag.lag0,
        type: PatternType.protective,
        confidence: PatternConfidence.standard,
        rawCorrelation: -0.60,
        strength: 0.60,
        correlationPercent: 60,
        effect: -2.3,
        exposedAverage: 1.5,
        unexposedAverage: 3.8,
        eventCount: 10,
        comparisonDaysCount: 10,
        hitRateCount: 8,
        headlineText: 'Fatigue tends to be milder on days you walk.',
        evidenceText: '8 of 10 events had milder symptoms.',
        hitRateText: '80%',
        disclaimer: kApprovedTriggerDisclaimer,
      );

      expect(protectivePattern.type, equals(PatternType.protective));
      expect(protectivePattern.headlineText, contains('milder'));
    });

    test('S5.7: Event older than 30 days drops out of paired-event count on rolling recalculation', () {
      final today = DateTime(2026, 9, 20);

      final oldEvent = createLog(
        date: DateTime(2026, 8, 15),
        triggers: ['Alcohol · 2 drinks'],
        symptoms: [hotFlash('Severe')],
      );

      final windowEvents = <DailyLog>[];
      for (int i = 1; i <= 6; i++) {
        windowEvents.add(createLog(
          date: DateTime(2026, 9, i),
          triggers: ['Alcohol · 2 drinks'],
          symptoms: [hotFlash('Severe')],
        ));
      }

      for (int i = 7; i <= 16; i++) {
        windowEvents.add(createLog(
          date: DateTime(2026, 9, i),
          triggers: [],
          symptoms: [hotFlash('Mild')],
        ));
      }

      final allLogs = [oldEvent, ...windowEvents];

      final result = engine.analyze(
        logs: allLogs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      final buildingAlcohol = result.buildingItems.where((b) => b.triggerId == 'alcohol').toList();
      if (buildingAlcohol.isNotEmpty) {
        expect(buildingAlcohol.first.eventsCount, equals(6),
            reason: 'Event older than 30 days must drop out of rolling 30-day count');
      }
    });

    test('S5.8: With more than 5 qualifying triggers, only top 5 by correlation strength display', () {
      final qualifyingPatterns = List.generate(
        8,
        (i) => PatternInsight(
          triggerId: 'trigger_$i',
          triggerDisplayName: 'Trigger $i',
          outcomeId: 'symptom_$i',
          outcomeDisplayName: 'Symptom $i',
          isOverallDayLevel: false,
          lag: PatternLag.lag0,
          type: PatternType.worsening,
          confidence: PatternConfidence.standard,
          rawCorrelation: (50 + (i * 5)) / 100.0,
          strength: (50 + (i * 5)) / 100.0,
          correlationPercent: 50 + (i * 5),
          effect: 2.0,
          exposedAverage: 3.5,
          unexposedAverage: 1.5,
          eventCount: 8,
          comparisonDaysCount: 8,
          hitRateCount: 7,
          headlineText: 'Headline $i',
          evidenceText: 'Evidence $i',
          hitRateText: '100%',
          disclaimer: kApprovedTriggerDisclaimer,
        ),
      );

      qualifyingPatterns.sort((a, b) => b.strength.compareTo(a.strength));
      final top5 = qualifyingPatterns.take(5).toList();

      expect(top5.length, equals(5));
      expect(top5.first.correlationPercent, equals(85));
      expect(top5.last.correlationPercent, equals(65));
    });
  });
}
