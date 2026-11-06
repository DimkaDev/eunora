import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/core/services/demo_generator_service.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';

void main() {
  const service = DemoGeneratorService();
  const hrtAnalyzer = HrtChangeAnalyzer();
  final today = DateTime(2026, 9, 28);

  group('DemoPersona Manual Scenarios (1–11) Metadata & Resolution', () {
    test('All 11 scenarios are registered with correct durations and stages', () {
      expect(DemoPersona.manualScenarios.length, equals(11));

      const s1 = DemoPersona.scenario1;
      expect(s1.durationDays, equals(7));
      expect(s1.stage, equals(MenopauseStage.noPeriod12Months));

      const s2 = DemoPersona.scenario2;
      expect(s2.durationDays, equals(15));
      expect(s2.stage, equals(MenopauseStage.noPeriod12Months));

      const s3 = DemoPersona.scenario3;
      expect(s3.durationDays, equals(30));
      expect(s3.stage, equals(MenopauseStage.noPeriod12Months));

      const s4 = DemoPersona.scenario4;
      expect(s4.durationDays, equals(30));
      expect(s4.stage, equals(MenopauseStage.irregular));

      const s5 = DemoPersona.scenario5;
      expect(s5.durationDays, equals(60));
      expect(s5.stage, equals(MenopauseStage.postmenopause));

      const s6 = DemoPersona.scenario6;
      expect(s6.durationDays, equals(60));
      expect(s6.stage, equals(MenopauseStage.surgical));

      const s7 = DemoPersona.scenario7;
      expect(s7.durationDays, equals(30));
      expect(s7.stage, equals(MenopauseStage.postmenopause));

      const s8 = DemoPersona.scenario8;
      expect(s8.durationDays, equals(15));
      expect(s8.stage, equals(MenopauseStage.noPeriod12Months));

      const s9 = DemoPersona.scenario9;
      expect(s9.durationDays, equals(20));
      expect(s9.stage, equals(MenopauseStage.noPeriod12Months));

      const s10 = DemoPersona.scenario10;
      expect(s10.durationDays, equals(30));
      expect(s10.stage, equals(MenopauseStage.pcos));

      const s11 = DemoPersona.scenario11;
      expect(s11.durationDays, equals(60));
      expect(s11.stage, equals(MenopauseStage.postmenopause));
    });

    test('DemoPersona.fromCode resolves numbers, scenario IDs, and letters correctly', () {
      expect(DemoPersona.fromCode('1'), equals(DemoPersona.scenario1));
      expect(DemoPersona.fromCode('scenario_1'), equals(DemoPersona.scenario1));
      expect(DemoPersona.fromCode('s1'), equals(DemoPersona.scenario1));
      expect(DemoPersona.fromCode('5'), equals(DemoPersona.scenario5));
      expect(DemoPersona.fromCode('11'), equals(DemoPersona.scenario11));
      expect(DemoPersona.fromCode('A'), equals(DemoPersona.demoA));
      expect(DemoPersona.fromCode('D'), equals(DemoPersona.demoD));
    });
  });

  group('Scenario 1: 7 days — Floor / Baseline', () {
    test('Generates exactly 7 logs with 100% adherence and 3 stress events', () {
      final startDate = today.subtract(const Duration(days: 6));
      final logs = service.generateSyntheticDailyLogs(
        userId: 'u1',
        persona: DemoPersona.scenario1,
        startDate: startDate,
        totalDays: 7,
      );

      expect(logs.length, equals(7));

      // Day 7 (last day, today): HF 2, NS 1, Anxiety 1 -> mean severity (2+1+1)/3 = 1.33
      final day7 = logs.last;
      expect(day7.symptoms.length, equals(3));
      final hf = day7.symptoms.firstWhere((s) => s.symptom.id == 'hot_flash');
      final ns = day7.symptoms.firstWhere((s) => s.symptom.id == 'night_sweats');
      final anx = day7.symptoms.firstWhere((s) => s.symptom.id == 'anxiety');
      expect(hf.intensity, equals(2));
      expect(ns.intensity, equals(1));
      expect(anx.intensity, equals(1));

      final meanDay7 = (hf.intensity! + ns.intensity! + anx.intensity!) / 3.0;
      expect(double.parse(meanDay7.toStringAsFixed(2)), equals(1.33));

      // Adherence: 7/7
      for (final log in logs) {
        expect(log.hrtIntakes.length, equals(1));
        expect(log.hrtIntakes.first.isTaken, isTrue);
      }

      // Exactly 3 stress days (Days 2, 4, 6)
      final stressLogs = logs.where((l) => l.triggers.contains('Stress')).toList();
      expect(stressLogs.length, equals(3));
      for (final sl in stressLogs) {
        final a = sl.symptoms.firstWhere((s) => s.symptom.id == 'anxiety');
        expect(a.intensity, equals(3));
      }
    });
  });

  group('Scenario 2: 15 days — HRT Unreachable Threshold (< 14 days)', () {
    test('Before window has only 7 days, HRT analyzer gates as notEnoughBaseline', () {
      final startDate = today.subtract(const Duration(days: 14));
      final logs = service.generateSyntheticDailyLogs(
        userId: 'u2',
        persona: DemoPersona.scenario2,
        startDate: startDate,
        totalDays: 15,
      );
      expect(logs.length, equals(15));

      final day8Date = startDate.add(const Duration(days: 7));
      final doseChanges = [
        HrtDoseChange(
          userId: 'u2',
          medicationId: 'med_estradiol_patch',
          medicationName: 'Estradiol patch',
          oldDose: 50.0,
          newDose: 75.0,
          unit: 'mcg',
          changeDate: day8Date,
        ),
      ];

      final result = hrtAnalyzer.analyze(
        doseChanges: doseChanges,
        medications: const [],
        logs: logs,
        today: today,
      );

      expect(result.groups.length, equals(1));
      expect(result.groups.first.beforeWindowLoggedDays, equals(7));
      expect(result.groups.first.afterWindowLoggedDays, equals(7));
      expect(result.groups.first.status, isNot(equals(HrtChangeStatus.ready)));
      // It is pending countdown because elapsedDays < 14 and beforeLoggedCount is 7
      expect(result.groups.first.status, equals(HrtChangeStatus.pending));
    });
  });

  group('Scenario 3: 30 days — HRT 14/14 Boundary + Moderate Correlation', () {
    test('Before window = 14 days, unlocks at Day 30, exactly 9 wine events', () {
      final startDate = today.subtract(const Duration(days: 29));
      final logs = service.generateSyntheticDailyLogs(
        userId: 'u3',
        persona: DemoPersona.scenario3,
        startDate: startDate,
        totalDays: 30,
      );
      expect(logs.length, equals(30));

      final wineLogs = logs.where((l) => l.triggers.contains('Wine')).toList();
      expect(wineLogs.length, equals(9));

      // Calculate before and after average HF occurrences
      int sumBefore = 0;
      for (int i = 0; i < 14; i++) {
        sumBefore += logs[i].customTriggerCounters['hot_flash_occurrences'] ?? 0;
      }
      final avgBefore = sumBefore / 14.0;
      expect(double.parse(avgBefore.toStringAsFixed(2)), equals(6.86));

      int sumAfter = 0;
      for (int i = 14; i < 30; i++) {
        sumAfter += logs[i].customTriggerCounters['hot_flash_occurrences'] ?? 0;
      }
      final avgAfter = sumAfter / 16.0;
      expect(double.parse(avgAfter.toStringAsFixed(2)), equals(2.94));

      // HRT change on Day 15
      final day15Date = startDate.add(const Duration(days: 14));
      final doseChanges = [
        HrtDoseChange(
          userId: 'u3',
          medicationId: 'med_estradiol_patch',
          medicationName: 'Estradiol patch',
          oldDose: 50.0,
          newDose: 75.0,
          unit: 'mcg',
          changeDate: day15Date,
        ),
      ];

      final result = hrtAnalyzer.analyze(
        doseChanges: doseChanges,
        medications: const [],
        logs: logs,
        today: today,
      );

      expect(result.groups.length, equals(1));
      expect(result.groups.first.status, equals(HrtChangeStatus.ready));
      expect(result.groups.first.beforeWindowLoggedDays, equals(14));
      expect(result.groups.first.afterWindowLoggedDays, equals(14));
    });
  });

  group('Scenario 4: 30 days — Perimenopause No HRT, Exactly 7 Events', () {
    test('No HRT, exactly 7 stress events, flat HF severity 2, both bleeding periods', () {
      final startDate = today.subtract(const Duration(days: 29));
      final logs = service.generateSyntheticDailyLogs(
        userId: 'u4',
        persona: DemoPersona.scenario4,
        startDate: startDate,
        totalDays: 30,
      );
      expect(logs.length, equals(30));

      for (final l in logs) {
        expect(l.hrtIntakes, isEmpty);
        final hf = l.symptoms.firstWhere((s) => s.symptom.id == 'hot_flash');
        expect(hf.intensity, equals(2));
      }

      final stressLogs = logs.where((l) => l.triggers.contains('Stress')).toList();
      expect(stressLogs.length, equals(7));

      final mediumBleedingLogs = logs.where((l) => l.symptoms.any((s) => s.symptom.id == 'bleeding' && s.intensity == 2)).toList();
      expect(mediumBleedingLogs.length, equals(3)); // Days 1-3

      final lightBleedingLogs = logs.where((l) => l.symptoms.any((s) => s.symptom.id == 'bleeding' && s.intensity == 1)).toList();
      expect(lightBleedingLogs.length, equals(2)); // Days 15-16
    });
  });

  group('Scenario 5: 60 days — Postmenopause High Conf & Worsening', () {
    test('14 wine days, 10 exercise days, worsening joint & sleep at Day 31, 58/60 adherence', () {
      final startDate = today.subtract(const Duration(days: 59));
      final logs = service.generateSyntheticDailyLogs(
        userId: 'u5',
        persona: DemoPersona.scenario5,
        startDate: startDate,
        totalDays: 60,
      );
      expect(logs.length, equals(60));

      final wineLogs = logs.where((l) => l.triggers.contains('Wine')).toList();
      expect(wineLogs.length, equals(14));

      final exerciseLogs = logs.where((l) => l.triggers.any((t) => t.contains('Exercise'))).toList();
      expect(exerciseLogs.length, equals(10));

      // Adherence: exactly 2 missed doses (Day 20, 45) -> 58/60
      final takenLogs = logs.where((l) => l.hrtIntakes.first.isTaken).toList();
      expect(takenLogs.length, equals(58));

      // Day 1-30: joint pain 2, sleep quality 4
      for (int i = 0; i < 30; i++) {
        final jp = logs[i].symptoms.firstWhere((s) => s.symptom.id == 'joint_pain');
        expect(jp.intensity, equals(2));
        expect(logs[i].customTriggerTexts['sleep_info'], contains('quality 4/5'));
      }

      // Day 31-60: joint pain 3, sleep quality 2
      for (int i = 30; i < 60; i++) {
        final jp = logs[i].symptoms.firstWhere((s) => s.symptom.id == 'joint_pain');
        expect(jp.intensity, equals(3));
        expect(logs[i].customTriggerTexts['sleep_info'], contains('quality 2/5'));
      }
    });
  });

  group('Scenario 6: 60 days — Sparse Logging (26/60 days)', () {
    test('Exactly 26 logged days, dose change on Day 52, 6 stress days', () {
      final startDate = today.subtract(const Duration(days: 59));
      final logs = service.generateSyntheticDailyLogs(
        userId: 'u6',
        persona: DemoPersona.scenario6,
        startDate: startDate,
        totalDays: 60,
      );
      expect(logs.length, equals(26));

      final stressLogs = logs.where((l) => l.triggers.contains('Stress')).toList();
      expect(stressLogs.length, equals(6));
    });
  });

  group('Scenario 7: 30 days — Symptom Diversity (Progynova)', () {
    test('Exact hierarchy: Fatigue(30) > Irritability(15) > Dryness(10) > Brain fog(9) > Headache(8) > Low mood(5)', () {
      final startDate = today.subtract(const Duration(days: 29));
      final logs = service.generateSyntheticDailyLogs(
        userId: 'u7',
        persona: DemoPersona.scenario7,
        startDate: startDate,
        totalDays: 30,
      );
      expect(logs.length, equals(30));

      final fatigueCount = logs.where((l) => l.symptoms.any((s) => s.symptom.id == 'fatigue')).length;
      final irritCount = logs.where((l) => l.symptoms.any((s) => s.symptom.id == 'irritability')).length;
      final dryCount = logs.where((l) => l.symptoms.any((s) => s.symptom.id == 'skin_dryness')).length;
      final fogCount = logs.where((l) => l.symptoms.any((s) => s.symptom.id == 'brain_fog')).length;
      final headacheCount = logs.where((l) => l.symptoms.any((s) => s.symptom.id == 'headache')).length;
      final lowMoodCount = logs.where((l) => l.symptoms.any((s) => s.symptom.id == 'low_mood')).length;

      expect(fatigueCount, equals(30));
      expect(irritCount, equals(15));
      expect(dryCount, equals(10));
      expect(fogCount, equals(9));
      expect(headacheCount, equals(8));
      expect(lowMoodCount, equals(5));

      final coffeeCount = logs.where((l) => l.triggers.contains('Coffee')).length;
      final weatherCount = logs.where((l) => l.triggers.contains('Weather')).length;
      expect(coffeeCount, equals(8));
      expect(weatherCount, equals(9));
    });
  });

  group('Scenario 8: 15 days — Weekday vs Frequency Change', () {
    test('Utrogestan twice-weekly intakes on Days 1, 4, 8, 11, 15', () {
      final startDate = today.subtract(const Duration(days: 14));
      final logs = service.generateSyntheticDailyLogs(
        userId: 'u8',
        persona: DemoPersona.scenario8,
        startDate: startDate,
        totalDays: 15,
      );
      expect(logs.length, equals(15));

      final takenDays = [
        for (int i = 0; i < logs.length; i++)
          if (logs[i].hrtIntakes.isNotEmpty) i + 1,
      ];
      expect(takenDays, equals([1, 4, 8, 11, 15]));
    });
  });

  group('Scenario 9: 20 days — Duplicate Detection & Deletion Rules', () {
    test('Evorel 75mcg has history on Days 5, 12, 19; Evorel 50mcg on Days 1, 15', () {
      final startDate = today.subtract(const Duration(days: 19));
      final logs = service.generateSyntheticDailyLogs(
        userId: 'u9',
        persona: DemoPersona.scenario9,
        startDate: startDate,
        totalDays: 20,
      );
      expect(logs.length, equals(20));

      final evorel75Logs = logs.where((l) => l.hrtIntakes.any((h) => h.medicationId == 'med_evorel_75')).toList();
      expect(evorel75Logs.length, equals(3));

      final evorel50Logs = logs.where((l) => l.hrtIntakes.any((h) => h.medicationId == 'med_evorel_50')).toList();
      expect(evorel50Logs.length, equals(2));
    });
  });

  group('Scenario 10: 30 days — PCOS Mode', () {
    test('Bleeding Days 1-5, no HRT intakes, 25-day gap without warnings', () {
      final startDate = today.subtract(const Duration(days: 29));
      final logs = service.generateSyntheticDailyLogs(
        userId: 'u10',
        persona: DemoPersona.scenario10,
        startDate: startDate,
        totalDays: 30,
      );
      expect(logs.length, equals(30));

      for (int i = 0; i < 30; i++) {
        expect(logs[i].hrtIntakes, isEmpty);
        final hasBleeding = logs[i].symptoms.any((s) => s.symptom.id == 'bleeding');
        if (i < 5) {
          expect(hasBleeding, isTrue); // Days 1-5
        } else {
          expect(hasBleeding, isFalse); // Days 6-30
        }
      }
    });
  });

  group('Scenario 11: 60 days — Gel + Ring, Soft-Stop/Resume, Weak Correlation', () {
    test('Ring taken 60 days, Gel taken Days 1-30 & 45-60, 20 coffee days with 50% jump', () {
      final startDate = today.subtract(const Duration(days: 59));
      final logs = service.generateSyntheticDailyLogs(
        userId: 'u11',
        persona: DemoPersona.scenario11,
        startDate: startDate,
        totalDays: 60,
      );
      expect(logs.length, equals(60));

      for (int i = 0; i < 60; i++) {
        final dayNum = i + 1;
        final hasRing = logs[i].hrtIntakes.any((h) => h.medicationId == 'med_vaginal_ring');
        expect(hasRing, isTrue);

        final hasGel = logs[i].hrtIntakes.any((h) => h.medicationId == 'med_estradiol_gel');
        if (dayNum >= 31 && dayNum <= 44) {
          expect(hasGel, isFalse); // soft-stopped
        } else {
          expect(hasGel, isTrue); // active
        }
      }

      final coffeeLogs = logs.where((l) => l.triggers.contains('Coffee')).toList();
      expect(coffeeLogs.length, equals(20));

      final severeIrrit = coffeeLogs.where((l) => l.symptoms.any((s) => s.symptom.id == 'irritability' && s.intensity == 3)).length;
      final moderateIrrit = coffeeLogs.where((l) => l.symptoms.any((s) => s.symptom.id == 'irritability' && s.intensity == 2)).length;
      expect(severeIrrit, equals(10));
      expect(moderateIrrit, equals(10));
    });
  });
}
