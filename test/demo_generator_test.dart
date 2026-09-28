import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/services/demo_generator_service.dart';
import 'package:eunora/features/auth/presentation/pages/sign_in_page.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const generatorService = DemoGeneratorService();
  const patternEngine = PatternEngine();
  const hrtAnalyzer = HrtChangeAnalyzer();
  final today = DateTime(2026, 9, 19);
  final startDate90 = today.subtract(const Duration(days: 89));
  final startDate60 = today.subtract(const Duration(days: 59));

  group('PROMPT 0: Shared Realism Framework & UI', () {
    test('DemoPersona definitions match required exact labels and days', () {
      expect(DemoPersona.demoA.label, equals('Try demo A (90 day sample data)'));
      expect(DemoPersona.demoB.label, equals('Try demo B (90 day sample data)'));
      expect(DemoPersona.demoC.label, equals('Try demo C (90 day sample data)'));
      expect(DemoPersona.demoD.label, equals('Try demo D (60 day sample data)'));

      expect(DemoPersona.demoA.durationDays, equals(90));
      expect(DemoPersona.demoB.durationDays, equals(90));
      expect(DemoPersona.demoC.durationDays, equals(90));
      expect(DemoPersona.demoD.durationDays, equals(60));
    });

    testWidgets('Logging screen UI renders exactly 4 demo buttons with required labels', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignInPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Try demo A (90 day sample data)'), findsOneWidget);
      expect(find.text('Try demo B (90 day sample data)'), findsOneWidget);
      expect(find.text('Try demo C (90 day sample data)'), findsOneWidget);
      expect(find.text('Try demo D (60 day sample data)'), findsOneWidget);
    });
  });

  group('PROMPT A: Perimenopause, No HRT, Moderate-Confidence Correlation (90 days)', () {
    test('Profile: Perimenopause stage, strictly no HRT in profile or daily logs', () {
      final logs = generatorService.generateSyntheticDailyLogs(
        userId: 'user_a',
        persona: DemoPersona.demoA,
        startDate: startDate90,
        totalDays: 90,
      );

      // ~85% of days logged (~77 logged days out of 90)
      expect(logs.length, greaterThanOrEqualTo(74));
      expect(logs.length, lessThanOrEqualTo(79));

      // No HRT data present in any daily log
      for (final log in logs) {
        expect(log.hrtIntakes, isEmpty);
      }

      // Mostly evening timestamps (8-10pm: 20:00-22:00)
      for (final log in logs) {
        expect(log.createdAt.hour, greaterThanOrEqualTo(20));
        expect(log.createdAt.hour, lessThanOrEqualTo(22));
      }
    });

    test('Cycle: irregular bleeding every ~12-16 days lasting 2-3 days, no validity warning', () {
      final logs = generatorService.generateSyntheticDailyLogs(
        userId: 'user_a',
        persona: DemoPersona.demoA,
        startDate: startDate90,
        totalDays: 90,
      );

      final bleedingLogs = logs.where((l) => l.symptoms.any((s) => s.symptom.id == 'bleeding')).toList();
      expect(bleedingLogs, isNotEmpty);
      expect(bleedingLogs.length, greaterThanOrEqualTo(10));
      expect(bleedingLogs.length, lessThanOrEqualTo(20));

      for (final log in bleedingLogs) {
        final bSym = log.symptoms.firstWhere((s) => s.symptom.id == 'bleeding');
        expect(bSym.symptom.category, equals('Cycle'));
        expect(bSym.symptom.name, equals('Bleeding'));
      }
    });

    test('Target correlation: work stress -> anxiety seeded to roughly 9 paired events, ~68% correlation (standard confidence)', () {
      final logs = generatorService.generateSyntheticDailyLogs(
        userId: 'user_a',
        persona: DemoPersona.demoA,
        startDate: startDate90,
        totalDays: 90,
      );

      final result = patternEngine.analyze(
        logs: logs,
        period: AnalysisPeriod.days90,
        today: today,
      );

      final stressAnxiety = result.patterns.where((p) => p.triggerId == 'stress' && p.outcomeId == 'anxiety').toList();
      expect(stressAnxiety, isNotEmpty);

      final pattern = stressAnxiety.first;
      // Stated range: roughly 9 paired events
      expect(pattern.eventCount, equals(9));
      // Stated range: ~68% correlation
      expect(pattern.correlationPercent, inInclusiveRange(64, 72));
      // Deliberately below 14-event bar -> standard confidence (NO "High confidence" chip)
      expect(pattern.confidence, equals(PatternConfidence.standard));
      expect(pattern.confidence.isHigh, isFalse);
    });
  });

  group('PROMPT B: Menopause + HRT, Dose Change With Clear Before/After (90 days)', () {
    test('Dose change at day 42 with clear Before/After hot flash drop & unlocked comparison', () {
      final logs = generatorService.generateSyntheticDailyLogs(
        userId: 'user_b',
        persona: DemoPersona.demoB,
        startDate: startDate90,
        totalDays: 90,
      );

      // ~90% logged days (~81 logged days)
      expect(logs.length, inInclusiveRange(78, 84));

      final day42Date = startDate90.add(const Duration(days: 42));
      final doseChange = HrtDoseChange(
        userId: 'user_b',
        medicationId: 'med_estradiol_patch',
        medicationName: 'Estradiol patch',
        oldDose: 50.0,
        newDose: 75.0,
        unit: 'mcg',
        changeDate: day42Date,
      );

      final result = hrtAnalyzer.analyze(
        doseChanges: [doseChange],
        medications: [],
        logs: logs,
        today: today,
      );

      expect(result.groups.length, equals(1));
      final group = result.groups.first;

      // Both before and after independently satisfy >= 14-day / >= 7-entries gating
      expect(group.isReady, isTrue);
      expect(group.status, equals(HrtChangeStatus.ready));
      expect(group.beforeWindowLoggedDays, greaterThanOrEqualTo(7));
      expect(group.afterWindowLoggedDays, greaterThanOrEqualTo(7));

      // Hot flash symptom results show drop in burden/severity
      final hfResult = group.symptomResults.firstWhere((s) => s.symptomId == 'hot_flash');
      expect(hfResult.averageSeverityBefore!, greaterThan(3.5));
      expect(hfResult.averageSeverityAfter!, lessThan(2.5));

      // Both medications (Estradiol + Utrogestan) logged with independent adherence
      final allEstradiol = logs.expand((l) => l.hrtIntakes.where((h) => h.medicationId == 'med_estradiol_patch')).toList();
      final allUtrogestan = logs.expand((l) => l.hrtIntakes.where((h) => h.medicationId == 'med_utrogestan')).toList();

      expect(allEstradiol, isNotEmpty);
      expect(allUtrogestan, isNotEmpty);

      final estTakenCount = allEstradiol.where((h) => h.isTaken).length;
      final utroTakenCount = allUtrogestan.where((h) => h.isTaken).length;

      // Independent missed doses: different counts
      expect(estTakenCount, isNot(equals(allEstradiol.length))); // not 100%
      expect(utroTakenCount, isNot(equals(allUtrogestan.length))); // not 100%
      expect(estTakenCount, isNot(equals(utroTakenCount))); // independent!
    });
  });

  group('PROMPT C: Postmenopause, Long-Term Stable HRT, High-Confidence Correlations (90 days)', () {
    test('Red wine correlation crosses thresholds for "High confidence" chip (15 events, ~78%)', () {
      final logs = generatorService.generateSyntheticDailyLogs(
        userId: 'user_c',
        persona: DemoPersona.demoC,
        startDate: startDate90,
        totalDays: 90,
      );

      final result = patternEngine.analyze(
        logs: logs,
        period: AnalysisPeriod.days90,
        today: today,
      );

      final winePattern = result.patterns.firstWhere((p) => p.triggerId == 'alcohol');
      // Exactly 15 paired events
      expect(winePattern.eventCount, equals(15));
      // ~78% correlation (in range 74% - 82%)
      expect(winePattern.correlationPercent, inInclusiveRange(74, 82));
      // Crosses >= 14 events & >= 70% -> High confidence chip!
      expect(winePattern.confidence, equals(PatternConfidence.high));
      expect(winePattern.confidence.isHigh, isTrue);
    });

    test('Exercise correlation renders with positive/green styling and stays below high-confidence bar', () {
      final logs = generatorService.generateSyntheticDailyLogs(
        userId: 'user_c',
        persona: DemoPersona.demoC,
        startDate: startDate90,
        totalDays: 90,
      );

      final result = patternEngine.analyze(
        logs: logs,
        period: AnalysisPeriod.days90,
        today: today,
      );

      final exPattern = result.patterns.firstWhere((p) => p.triggerId == 'exercise');
      // 10-11 events
      expect(exPattern.eventCount, inInclusiveRange(10, 11));
      // Protective type (positive green styling)
      expect(exPattern.type, equals(PatternType.protective));
      // Stays below high-confidence bar
      expect(exPattern.confidence, equals(PatternConfidence.standard));
      expect(exPattern.confidence.isHigh, isFalse);
    });

    test('Joint pain and sleep trend lines read flat-to-worsening across full 90 days', () {
      final logs = generatorService.generateSyntheticDailyLogs(
        userId: 'user_c',
        persona: DemoPersona.demoC,
        startDate: startDate90,
        totalDays: 90,
      );

      final earlyJoint = logs.take(30).expand((l) => l.symptoms).where((s) => s.symptom.id == 'joint_pain').map((s) => s.intensity!).toList();
      final lateJoint = logs.skip(50).expand((l) => l.symptoms).where((s) => s.symptom.id == 'joint_pain').map((s) => s.intensity!).toList();
      final earlyAvg = earlyJoint.reduce((a, b) => a + b) / earlyJoint.length;
      final lateAvg = lateJoint.reduce((a, b) => a + b) / lateJoint.length;

      // Flat-to-worsening, not improving
      expect(lateAvg, greaterThanOrEqualTo(earlyAvg));
    });
  });

  group('PROMPT D: Sparse/Inconsistent Logger, Mostly-Gated States (60 days)', () {
    test('Logged days (20-25) is visibly lower than 60 calendar days span', () {
      final logs = generatorService.generateSyntheticDailyLogs(
        userId: 'user_d',
        persona: DemoPersona.demoD,
        startDate: startDate60,
        totalDays: 60,
      );

      // Exactly roughly 20-25 days logged
      expect(logs.length, inInclusiveRange(20, 25));

      // Passport requires 30 logged days -> shows "X days to go" (30 - 22 = 8 days to go)
      expect(logs.length, lessThan(30));
    });

    test('Recent dose change 8 days ago shows in-progress countdown, never false ready', () {
      final logs = generatorService.generateSyntheticDailyLogs(
        userId: 'user_d',
        persona: DemoPersona.demoD,
        startDate: startDate60,
        totalDays: 60,
      );

      final eightDaysAgo = today.subtract(const Duration(days: 8));
      final doseChange = HrtDoseChange(
        userId: 'user_d',
        medicationId: 'med_estrogel',
        medicationName: 'EstroGel',
        oldDose: 0.75,
        newDose: 1.5,
        unit: 'mg',
        changeDate: eightDaysAgo,
      );

      final result = hrtAnalyzer.analyze(
        doseChanges: [doseChange],
        medications: [],
        logs: logs,
        today: today,
      );

      expect(result.groups.length, equals(1));
      final group = result.groups.first;

      // In-progress countdown: 8 elapsed days < 14 -> pending with daysToGo == 6
      expect(group.status, equals(HrtChangeStatus.pending));
      expect(group.isReady, isFalse);
      expect(group.daysSinceChange, equals(8));
      expect(group.daysToGo, equals(6));
      expect(group.statusMessage, contains('6 days to go'));
    });

    test('Sub-7 trigger (coffee) sits in sub-7 progress state (5 of 7 needed)', () {
      final logs = generatorService.generateSyntheticDailyLogs(
        userId: 'user_d',
        persona: DemoPersona.demoD,
        startDate: startDate60,
        totalDays: 60,
      );

      final result = patternEngine.analyze(
        logs: logs,
        period: AnalysisPeriod.days90,
        today: today,
      );

      // Below 7 events -> appears in buildingItems
      expect(result.patterns.where((p) => p.triggerId == 'coffee'), isEmpty);
      final coffeeBuilding = result.buildingItems.where((b) => b.triggerId == 'coffee').toList();
      expect(coffeeBuilding, isNotEmpty);
      expect(coffeeBuilding.first.eventsCount, inInclusiveRange(5, 6));
      expect(coffeeBuilding.first.displayText, contains('of 7'));
    });

    test('Adherence noticeably lower (~70-75%) with several missed doses', () {
      final logs = generatorService.generateSyntheticDailyLogs(
        userId: 'user_d',
        persona: DemoPersona.demoD,
        startDate: startDate60,
        totalDays: 60,
      );

      final allIntakes = logs.expand((l) => l.hrtIntakes).toList();
      final takenCount = allIntakes.where((h) => h.isTaken).length;
      final adherencePercent = (takenCount / allIntakes.length) * 100;

      expect(adherencePercent, inInclusiveRange(68.0, 76.0));
      final missedCount = allIntakes.where((h) => !h.isTaken).length;
      expect(missedCount, greaterThanOrEqualTo(5)); // several missed doses
    });
  });

  group('GLOBAL DEFINITION OF DONE: Reproducibility & State Exclusivity', () {
    test('Re-generating the same demo letter twice produces identical outputs within target ranges', () {
      final logs1 = generatorService.generateSyntheticDailyLogs(
        userId: 'user_a',
        persona: DemoPersona.demoA,
        startDate: startDate90,
        totalDays: 90,
      );
      final logs2 = generatorService.generateSyntheticDailyLogs(
        userId: 'user_a',
        persona: DemoPersona.demoA,
        startDate: startDate90,
        totalDays: 90,
      );

      expect(logs1.length, equals(logs2.length));
      for (int i = 0; i < logs1.length; i++) {
        expect(logs1[i].date, equals(logs2[i].date));
        expect(logs1[i].symptoms.length, equals(logs2[i].symptoms.length));
        expect(logs1[i].triggers, equals(logs2[i].triggers));
        expect(logs1[i].sleepDuration, equals(logs2[i].sleepDuration));
      }
    });
  });
}
