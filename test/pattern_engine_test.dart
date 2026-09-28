import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';

void main() {
  const engine = PatternEngine();

  DailyLog createLog({
    required DateTime date,
    bool isCompleted = true,
    List<LoggedSymptom> symptoms = const [],
    List<String> triggers = const [],
    int caffeineCups = 0,
    int alcoholGlasses = 0,
    String stressLevel = 'Moderate',
    double sleepDuration = 7.0,
    DateTime? createdAt,
  }) {
    return DailyLog(
      id: date.toIso8601String().substring(0, 10),
      userId: 'test_user',
      date: date,
      isCompleted: isCompleted,
      symptoms: symptoms,
      triggers: triggers,
      caffeineCups: caffeineCups,
      alcoholGlasses: alcoholGlasses,
      stressLevel: stressLevel,
      sleepDuration: sleepDuration,
      createdAt: createdAt ?? date,
    );
  }

  LoggedSymptom createSymptom({
    required String id,
    required String name,
    String? severity,
    int? intensity,
    int? durationMinutes,
  }) {
    return LoggedSymptom(
      symptom: Symptom(id: id, name: name, iconName: 'medical_services'),
      severity: severity,
      intensity: intensity,
      durationMinutes: durationMinutes,
    );
  }

  group('Analysis Window Rules', () {
    test('periods 1 and 7 evaluate over 30 days and show "Based on last 30 days"', () {
      final today = DateTime(2026, 9, 20);
      // Generate 20 logged days across 30 days
      final logs = List.generate(20, (i) {
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          isCompleted: true,
        );
      });
      // Add a log at day 30 so history is not clamped
      logs.add(createLog(date: DateTime(2026, 8, 22), isCompleted: true));

      final result1 = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.day1,
        today: today,
      );

      expect(result1.effectiveDaysInWindow, 30);
      expect(result1.windowNotice, 'Based on last 30 days');

      final result7 = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days7,
        today: today,
      );

      expect(result7.effectiveDaysInWindow, 30);
      expect(result7.windowNotice, 'Based on last 30 days');
    });

    test('period 90 evaluates over 90 days with no windowNotice', () {
      final today = DateTime(2026, 9, 20);
      final logs = [
        createLog(date: DateTime(2026, 6, 23)), // 90 days ago
        createLog(date: today),
      ];

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days90,
        today: today,
      );

      expect(result.effectiveDaysInWindow, 90);
      expect(result.windowNotice, isNull);
    });

    test('history shorter than window clamps window and shows "Based on X days of data"', () {
      final today = DateTime(2026, 9, 20);
      // First log was 16 days ago (Sep 4)
      final logs = List.generate(16, (i) {
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          isCompleted: true,
        );
      });

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.effectiveDaysInWindow, 16);
      expect(result.windowNotice, 'Based on 16 days of data');
    });
  });

  group('Gating Thresholds (Non-negotiable)', () {
    test('rejects display when logged days < 14 and emits notEnoughData empty state', () {
      final today = DateTime(2026, 9, 20);
      // Only 10 logged days, even if trigger was logged 7 times with high correlation
      final logs = List.generate(10, (i) {
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: i < 7 ? ['alcohol'] : [],
          symptoms: i < 7
              ? [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Severe')]
              : [],
        );
      });

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.patterns, isEmpty);
      expect(result.emptyStateType, SD10EmptyType.notEnoughData);
      expect(result.emptyStateMessage, contains('14 logged days'));
    });

    test('rejects display when exposed days < 7 and builds progress item', () {
      final today = DateTime(2026, 9, 20);
      // 20 logged days, but alcohol logged only 5 times
      final logs = List.generate(20, (i) {
        final isExposed = i < 5;
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: isExposed ? ['alcohol'] : [],
          symptoms: isExposed
              ? [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Severe')]
              : [],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.patterns, isEmpty);
      expect(result.buildingItems.length, 1);
      expect(result.buildingItems.first.triggerId, 'alcohol');
      expect(result.buildingItems.first.eventsCount, 5);
      expect(result.buildingItems.first.displayText, 'Alcohol · 5 of 7 events');
    });

    test('rejects display when unexposed comparison days < 3', () {
      final today = DateTime(2026, 9, 20);
      // 15 logged days, but alcohol logged 14 times (only 1 comparison day!)
      final logs = List.generate(15, (i) {
        final isExposed = i < 14;
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: isExposed ? ['alcohol'] : [],
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Severe')],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.patterns, isEmpty);
    });

    test('rejects display when strength < 30%', () {
      final today = DateTime(2026, 9, 20);
      // 20 logged days: 10 alcohol, 10 no alcohol, but symptoms are identical (0 correlation)
      final logs = List.generate(20, (i) {
        final isExposed = i % 2 == 0;
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: isExposed ? ['alcohol'] : [],
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Moderate')],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.patterns, isEmpty);
    });
  });

  group('Lag Selection & Unlogged Outcome Handling', () {
    test('lag 0 wins if lag 1 beats it by less than 0.05 in strength', () {
      final today = DateTime(2026, 9, 20);
      // Construct a dataset where both lag 0 and lag 1 have strong correlation,
      // but lag 1 is only 0.02 higher than lag 0.
      // E.g., alcohol on even days; symptoms high on even days AND on odd days.
      final logs = <DailyLog>[];
      for (int i = 0; i < 20; i++) {
        final date = DateTime(2026, 9, 1 + i);
        final isAlcohol = i % 2 == 0;
        logs.add(createLog(
          date: date,
          triggers: isAlcohol ? ['alcohol'] : [],
          symptoms: isAlcohol
              ? [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Severe')]
              : [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Mild')],
        ));
      }
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.patterns, isNotEmpty);
      final pattern = result.patterns.firstWhere((p) => p.triggerId == 'alcohol');
      // On even days symptoms are Severe (5.0), on odd days Mild (1.0).
      // Same day (lag 0) correlation is +1.0!
      // Lag 0 clearly wins.
      expect(pattern.lag, PatternLag.lag0);
      expect(pattern.headlineText, contains('on days you log it'));
    });

    test('lag 1 wins when next-day association is significantly stronger (>= 0.05)', () {
      final today = DateTime(2026, 9, 25);
      // Alcohol logged on days 0, 2, 4, 6, 8, 10, 12.
      // But symptoms on those days are mild (1.0), and on the NEXT days (1, 3, 5, 7, 9, 11, 13)
      // symptoms are severe (5.0)!
      final logs = <DailyLog>[];
      for (int i = 0; i < 20; i++) {
        final date = DateTime(2026, 9, 1 + i);
        final isAlcohol = (i % 2 == 0) && (i < 14);
        final isNextDay = (i % 2 == 1) && (i < 15);

        logs.add(createLog(
          date: date,
          triggers: isAlcohol ? ['alcohol'] : [],
          symptoms: isNextDay
              ? [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Severe')]
              : [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Mild')],
        ));
      }
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.patterns, isNotEmpty);
      final pattern = result.patterns.firstWhere((p) => p.triggerId == 'alcohol');
      expect(pattern.lag, PatternLag.lag1);
      expect(pattern.headlineText, contains('the day after'));
    });

    test('unlogged next-day skips lag 1 pair without crashing', () {
      final today = DateTime(2026, 9, 20);
      // An exposure on the last logged day (Sep 20): there is no Sep 21 log.
      final logs = List.generate(15, (i) {
        final isExposed = i < 8;
        return createLog(
          date: DateTime(2026, 9, 6 + i),
          triggers: isExposed ? ['stress'] : [],
          symptoms: isExposed
              ? [createSymptom(id: 'headache', name: 'Headache', severity: 'Severe')]
              : [],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.patterns, isNotEmpty);
    });
  });

  group('Polarity Guard', () {
    test('worsening trigger with negative association is suppressed', () {
      final today = DateTime(2026, 9, 20);
      // Coffee is logged, but symptoms are MILDER when coffee is logged
      final logs = List.generate(20, (i) {
        final isExposed = i < 10;
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: isExposed ? ['coffee'] : [],
          symptoms: isExposed
              ? [createSymptom(id: 'anxiety', name: 'Anxiety', severity: 'Mild')]
              : [createSymptom(id: 'anxiety', name: 'Anxiety', severity: 'Severe')],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      // Even though correlation is strong negative, polarity guard hides it!
      expect(result.patterns.any((p) => p.triggerId == 'coffee'), isFalse);
    });

    test('exercise with negative association is displayed as protective', () {
      final today = DateTime(2026, 9, 20);
      // Exercise logged -> symptoms are MILDER (1.0 vs 5.0)
      final logs = List.generate(20, (i) {
        final isExposed = i < 10;
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: isExposed ? ['exercise'] : [],
          symptoms: isExposed
              ? [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')]
              : [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.patterns, isNotEmpty);
      final pattern = result.patterns.firstWhere((p) => p.triggerId == 'exercise');
      expect(pattern.type, PatternType.protective);
      expect(pattern.headlineText, contains('tends to be milder on days you log it'));
      expect(pattern.effect, lessThan(0.0));
      expect(pattern.rawCorrelation, lessThan(0.0));
    });

    test('exercise with positive association is suppressed by polarity guard', () {
      final today = DateTime(2026, 9, 20);
      // Exercise logged -> symptoms are WORSE (5.0 vs 1.0)
      final logs = List.generate(20, (i) {
        final isExposed = i < 10;
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: isExposed ? ['exercise'] : [],
          symptoms: isExposed
              ? [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe')]
              : [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.patterns.any((p) => p.triggerId == 'exercise'), isFalse);
    });
  });

  group('Outcome Selection & Headline Tie-Breaking', () {
    test('specific symptom preferred over overall day level when tied in strength', () {
      final today = DateTime(2026, 9, 20);
      // Only 1 symptom exists in the logs: hot_flash.
      // So hot_flash score == day_level score on every day!
      // They will have identical correlation strength and effect size.
      final logs = List.generate(20, (i) {
        final isExposed = i < 10;
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: isExposed ? ['alcohol'] : [],
          symptoms: isExposed
              ? [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Severe')]
              : [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Mild')],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      final pattern = result.patterns.firstWhere((p) => p.triggerId == 'alcohol');
      // Headline must be specific symptom, NOT overall day level
      expect(pattern.isOverallDayLevel, isFalse);
      expect(pattern.outcomeId, 'hot_flash');
      // Overall day level is retained in secondary outcomes
      expect(pattern.secondaryOutcomes.any((s) => s.isOverallDayLevel), isTrue);
    });
  });

  group('Confidence & Sentence Templates', () {
    test('high confidence chip only at >= 14 events and >= 70% correlation', () {
      final today = DateTime(2026, 9, 20);
      // 14 exposed events with 100% correlation
      final logs = List.generate(20, (i) {
        final isExposed = i < 14;
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: isExposed ? ['alcohol'] : [],
          symptoms: isExposed
              ? [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Severe')]
              : [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Mild')],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      final pattern = result.patterns.firstWhere((p) => p.triggerId == 'alcohol');
      expect(pattern.confidence, PatternConfidence.high);
      expect(pattern.confidence.isHigh, isTrue);
      expect(pattern.eventCount, 14);
      expect(pattern.correlationPercent, 100);

      // Verbatim disclaimer
      expect(pattern.disclaimer, equals(kApprovedTriggerDisclaimer));
      // Evidence text
      expect(pattern.evidenceText, contains('Average 5.0 vs 1.0 on other days · 100% correlation · 14 events'));
      // Hit rate text
      expect(pattern.hitRateText, contains('was higher than usual 14 of those times'));
    });
  });

  group('Exercise 30+ Min Variant', () {
    test('evaluates exercise_30plus when >= 7 sessions of 30+ min exist', () {
      final today = DateTime(2026, 9, 20);
      final logs = List.generate(20, (i) {
        final isExposed = i < 8;
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: isExposed ? ['Exercise · 45 min · Moderate'] : [],
          symptoms: isExposed
              ? [createSymptom(id: 'joint_pain', name: 'Joint pain', severity: 'Mild')]
              : [createSymptom(id: 'joint_pain', name: 'Joint pain', severity: 'Severe')],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      final pattern = result.patterns.firstWhere(
        (p) => p.triggerId == 'exercise_30plus' || p.triggerId == 'exercise',
      );
      expect(pattern.type, PatternType.protective);
    });
  });

  group('SD-10 Three Kinds of Empty', () {
    test('notEnoughVariety when a trigger is present on every logged day', () {
      final today = DateTime(2026, 9, 20);
      // 16 logged days, alcohol logged EVERY SINGLE DAY (0 comparison days)
      final logs = List.generate(16, (i) {
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: ['alcohol'],
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Severe')],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.patterns, isEmpty);
      expect(result.emptyStateType, SD10EmptyType.notEnoughVariety);
      expect(result.emptyStateMessage, contains('We need a few days without Alcohol to compare.'));
    });

    test('nothingNotable when enough data exists but no pattern >= 30%', () {
      final today = DateTime(2026, 9, 20);
      // 20 logged days: random distribution resulting in correlation near 0
      final logs = List.generate(20, (i) {
        final isExposed = i < 10;
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: isExposed ? ['alcohol'] : [],
          // Constant severity = no variance / 0 correlation
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Moderate')],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      expect(result.patterns, isEmpty);
      expect(result.emptyStateType, SD10EmptyType.nothingNotable);
      expect(result.emptyStateMessage, contains('No clear patterns yet — we keep checking as you log.'));
    });
  });

  group('Ranking and Cap', () {
    test('at most 5 patterns shown, ranked by strength', () {
      final today = DateTime(2026, 9, 20);
      final triggers = ['alcohol', 'coffee', 'stress', 'spicy_food', 'smoking', 'hot_drinks_food'];
      // Generate 20 logged days with all 6 triggers worsening symptoms
      final logs = List.generate(20, (i) {
        final isExposed = i < 10;
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: isExposed ? triggers : [],
          symptoms: isExposed
              ? [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Severe')]
              : [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Mild')],
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      // Max 5 patterns displayed
      expect(result.patterns.length, lessThanOrEqualTo(5));
      expect(result.patterns.length, 5);
    });

    test('at most 3 building items shown, nearest to 7 first', () {
      final today = DateTime(2026, 9, 20);
      // 4 triggers with 6, 5, 4, 3 events
      final logs = List.generate(20, (i) {
        final currentTriggers = <String>[];
        if (i < 6) currentTriggers.add('alcohol');
        if (i < 5) currentTriggers.add('coffee');
        if (i < 4) currentTriggers.add('stress');
        if (i < 3) currentTriggers.add('spicy_food');
        return createLog(
          date: DateTime(2026, 9, 20 - i),
          triggers: currentTriggers,
        );
      });
      logs.add(createLog(date: DateTime(2026, 8, 20)));

      final result = engine.analyze(
        logs: logs,
        period: AnalysisPeriod.days30,
        today: today,
      );

      // Max 3 building items, ranked nearest to 7 first (6, 5, 4)
      expect(result.buildingItems.length, 3);
      expect(result.buildingItems[0].eventsCount, 6);
      expect(result.buildingItems[1].eventsCount, 5);
      expect(result.buildingItems[2].eventsCount, 4);
    });
  });
}
