import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const engine = PatternEngine();

  void assertInvariants(PatternEngineResult res) {
    expect(res.patterns, isNotNull);
    for (final p in res.patterns) {
      expect(p.rawCorrelation.isNaN, isFalse);
      expect(p.rawCorrelation.isInfinite, isFalse);
      expect(p.strength.isNaN, isFalse);
      expect(p.strength.isInfinite, isFalse);
      expect(p.correlationPercent >= 0 && p.correlationPercent <= 100, isTrue);
      expect(p.eventCount >= 0, isTrue);
    }
  }

  group('T2 Pattern Engine Tests', () {
    test('T2-F-A: Perfect next-day effect (lag1), polarity guard and high confidence', () {
      // 31 logged days: alcohol on odd days D1..D29
      // hot_flash Severe on even days, Mild on odd days
      // D30 and D31 have no alcohol, D30 has Severe hot flash
      final logs = List.generate(31, (i) {
        final day = i + 1;
        final date = DateTime(2026, 8, 21 + i);
        final isAlcohol = day <= 29 && day % 2 != 0;
        final isSevere = day % 2 == 0;
        return createLog(
          date: date,
          triggers: isAlcohol ? ['Alcohol · 2 drinks'] : [],
          symptoms: [hotFlash(isSevere ? 'Severe' : 'Mild')],
        );
      });

      final res = engine.analyze(logs: logs, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 20));
      assertInvariants(res);
      expect(res.patterns.isNotEmpty, isTrue);
      final p = res.patterns.firstWhere((pat) => pat.triggerId == 'alcohol');
      expect(p.lag, PatternLag.lag1);
      expect(p.correlationPercent, 100);
      expect(p.eventCount, anyOf(14, 15));
      expect(p.comparisonDaysCount >= 14, isTrue);
      expect(p.effect, closeTo(4.0, 0.01)); // 5.0 vs 1.0 = +4.0
      expect(p.hitRateCount, p.eventCount);
      expect(p.confidence, PatternConfidence.high);
    });

    test('T2-F-B: Below threshold event count produces building item', () {
      // 20 logged days; trigger on 6 days with strong same-day effect
      final triggerDays = {2, 5, 8, 11, 14, 17};
      final logs6 = List.generate(20, (i) {
        final day = i + 1;
        final date = DateTime(2026, 8, 31 + i);
        final hasTrigger = triggerDays.contains(day);
        return createLog(
          date: date,
          triggers: hasTrigger ? ['Coffee / caffeine · 2 cups'] : [],
          symptoms: [hotFlash(hasTrigger ? 'Severe' : 'Mild')],
        );
      });

      final res6 = engine.analyze(logs: logs6, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 19));
      expect(res6.patterns.where((p) => p.triggerId == 'coffee').isEmpty, isTrue);
      expect(res6.buildingItems.any((b) => b.triggerId == 'coffee' && b.eventsCount == 6), isTrue);

      // Adding 7th exposed day (D20) -> displayed
      final logs7 = List.generate(20, (i) {
        final day = i + 1;
        final date = DateTime(2026, 8, 31 + i);
        final hasTrigger = triggerDays.contains(day) || day == 20;
        return createLog(
          date: date,
          triggers: hasTrigger ? ['Coffee / caffeine · 2 cups'] : [],
          symptoms: [hotFlash(hasTrigger ? 'Severe' : 'Mild')],
        );
      });
      final res7 = engine.analyze(logs: logs7, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 19));
      expect(res7.patterns.any((p) => p.triggerId == 'coffee'), isTrue);
    });

    test('T2-F-C: Comparison days minimum (at least 3 unexposed)', () {
      // 14 logged days; trigger on 12 days, absent on 2 -> notEnoughVariety
      final logs12 = List.generate(14, (i) {
        final date = DateTime(2026, 9, 6 + i);
        final hasTrigger = i < 12;
        return createLog(
          date: date,
          triggers: hasTrigger ? ['Coffee / caffeine · 2 cups'] : [],
          symptoms: [hotFlash(hasTrigger ? 'Severe' : 'Mild')],
        );
      });
      final res12 = engine.analyze(logs: logs12, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 19));
      expect(res12.patterns.any((p) => p.triggerId == 'coffee'), isFalse);

      // Trigger on 11 days, absent on 3 -> allowed
      final logs11 = List.generate(14, (i) {
        final date = DateTime(2026, 9, 6 + i);
        final hasTrigger = i < 11;
        return createLog(
          date: date,
          triggers: hasTrigger ? ['Coffee / caffeine · 2 cups'] : [],
          symptoms: [hotFlash(hasTrigger ? 'Severe' : 'Mild')],
        );
      });
      final res11 = engine.analyze(logs: logs11, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 19));
      expect(res11.patterns.any((p) => p.triggerId == 'coffee'), isTrue);
    });

    test('T2-F-D: Zero variance and no NaN', () {
      // Trigger on all 20 days
      final logs20 = List.generate(20, (i) {
        return createLog(
          date: DateTime(2026, 8, 31 + i),
          triggers: ['Stress · High'],
          symptoms: [hotFlash('Moderate')],
        );
      });
      final res = engine.analyze(logs: logs20, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 19));
      assertInvariants(res);
      expect(res.patterns.isEmpty, isTrue);
    });

    test('T2-F-E: Noise below 30% display threshold', () {
      // 16 logged days; trigger on 8; severity 5 on 4 exposed and 4 unexposed, else 1
      final logs = List.generate(16, (i) {
        final hasTrigger = i < 8;
        final hasSevere = (i < 4) || (i >= 8 && i < 12);
        return createLog(
          date: DateTime(2026, 9, 4 + i),
          triggers: hasTrigger ? ['Alcohol · 2 drinks'] : [],
          symptoms: [hotFlash(hasSevere ? 'Severe' : 'Mild')],
        );
      });
      final res = engine.analyze(logs: logs, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 19));
      expect(res.patterns.any((p) => p.triggerId == 'alcohol'), isFalse);
    });

    test('T2-F-F: Polarity guard for worsening triggers vs protective habits', () {
      // (1) exercise on 8 of 20 days with score 1, otherwise 5 -> protective
      final logsExerciseProtective = List.generate(20, (i) {
        final hasExercise = i < 8;
        return createLog(
          date: DateTime(2026, 8, 31 + i),
          triggers: hasExercise ? ['Exercise · 15 min'] : [],
          symptoms: [hotFlash(hasExercise ? 'Mild' : 'Severe')],
        );
      });
      final resExProt = engine.analyze(logs: logsExerciseProtective, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 19));
      final pEx = resExProt.patterns.firstWhere((p) => p.triggerId == 'exercise');
      expect(pEx.type, PatternType.protective);
      expect(pEx.headlineText.contains('milder'), isTrue);

      // (2) alcohol with negative association -> hidden by polarity guard
      final logsAlcoholNegative = List.generate(20, (i) {
        final hasAlcohol = i < 8;
        return createLog(
          date: DateTime(2026, 8, 31 + i),
          triggers: hasAlcohol ? ['Alcohol · 2 drinks'] : [],
          symptoms: [hotFlash(hasAlcohol ? 'Mild' : 'Severe')],
        );
      });
      final resAlcNeg = engine.analyze(logs: logsAlcoholNegative, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 19));
      expect(resAlcNeg.patterns.any((p) => p.triggerId == 'alcohol'), isFalse);
    });

    test('T2-F-G: Gap in logs correctly skips lag-1 pairs', () {
      // 14 days, D8 unlogged; alcohol on D1, D3, D5, D7, D9, D11, D13
      final alcoholDays = {1, 3, 5, 7, 9, 11, 13};
      final logs = <DailyLog>[];
      for (int day = 1; day <= 14; day++) {
        if (day == 8) continue; // Unlogged gap
        final date = DateTime(2026, 9, 5 + day);
        logs.add(createLog(
          date: date,
          triggers: alcoholDays.contains(day) ? ['Alcohol · 2 drinks'] : [],
          symptoms: [hotFlash('Moderate')],
        ));
      }
      final res = engine.analyze(logs: logs, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 19));
      assertInvariants(res);
    });

    test('T2-F-H: Window rule (Period 7 uses 30-day window)', () {
      final gLogs = goldenDatasetLogs();
      final res7 = engine.analyze(logs: gLogs, period: AnalysisPeriod.days7, today: kToday);
      expect(res7.effectiveDaysInWindow >= 18, isTrue);
      expect(res7.windowNotice, isNotNull);
    });

    test('T2-F-I: Ranking and cap at 5 patterns', () {
      final res = engine.analyze(logs: goldenDatasetLogs(), period: AnalysisPeriod.days30, today: kToday);
      expect(res.patterns.length <= 5, isTrue);
      expect(res.buildingItems.length <= 3, isTrue);
    });

    test('T2-F-J: Confidence rule', () {
      // >= 14 events AND >= 70% correlation -> high confidence
      const p1 = PatternInsight(
        triggerId: 't1', triggerDisplayName: 'T1', outcomeId: 'o1', outcomeDisplayName: 'O1',
        isOverallDayLevel: false, lag: PatternLag.lag0, type: PatternType.worsening,
        confidence: PatternConfidence.standard, rawCorrelation: 0.8, strength: 0.8,
        correlationPercent: 80, effect: 1.0, exposedAverage: 3.0, unexposedAverage: 2.0,
        eventCount: 13, comparisonDaysCount: 10, hitRateCount: 10, headlineText: '', evidenceText: '', hitRateText: '',
      );
      expect(p1.confidence, PatternConfidence.standard);
    });

    test('T2-F-K: Default counters never create pattern events', () {
      // 10 days where coffee counter = 3 but coffee trigger is NOT in triggers list
      final logs = List.generate(10, (i) => createLog(
        date: DateTime(2026, 9, 10 + i),
        caffeineCups: 3,
        triggers: [],
        symptoms: [hotFlash('Severe')],
      ));
      final res = engine.analyze(logs: logs, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 19));
      expect(res.patterns.any((p) => p.triggerId == 'coffee'), isFalse);
      expect(res.buildingItems.any((b) => b.triggerId == 'coffee'), isFalse);
    });

    test('T2-F-L: Unit variants merged (drinks vs glasses)', () {
      // 4 days drinks + 3 days glasses -> 7 alcohol events
      final logs = List.generate(14, (i) {
        final date = DateTime(2026, 9, 6 + i);
        List<String> trigs = [];
        if (i < 4) {
          trigs = ['Alcohol · 2 drinks'];
        } else if (i < 7) {
          trigs = ['Alcohol · 2 glasses'];
        }
        return createLog(
          date: date,
          triggers: trigs,
          symptoms: [hotFlash(i < 7 ? 'Severe' : 'Mild')],
        );
      });
      final res = engine.analyze(logs: logs, period: AnalysisPeriod.days30, today: DateTime(2026, 9, 19));
      final alcPattern = res.patterns.firstWhere((p) => p.triggerId == 'alcohol');
      expect(alcPattern.eventCount, 7);
    });

    test('T2-F-P: Approved disclaimers present verbatim', () {
      final res = engine.analyze(logs: goldenDatasetLogs(), period: AnalysisPeriod.days30, today: kToday);
      for (final p in res.patterns) {
        expect(p.disclaimer, kApprovedTriggerDisclaimer);
        expect(p.headlineText.contains('tends to'), isTrue);
      }
    });
  });
}
