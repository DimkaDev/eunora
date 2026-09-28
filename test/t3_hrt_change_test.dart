import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'golden_dataset_fixture.dart';

void main() {
  const analyzer = HrtChangeAnalyzer();

  group('T3 HRT Change Tests', () {
    test('T3-H-1: Pending regimen change countdown equals 14 minus elapsed days', () {
      final change = HrtDoseChange(
        id: 'c1',
        userId: 'test_user',
        medicationId: 'med_estradiol',
        medicationName: 'Estradiol gel',
        oldDose: 1,
        newDose: 2,
        unit: 'pumps',
        changeDate: DateTime(2026, 9, 13, 18, 45),
        changeType: RegimenChangeType.doseChange,
      );
      final gLogs = goldenDatasetLogs();
      final res = analyzer.analyze(
        doseChanges: [change],
        medications: goldenMedications(),
        logs: gLogs,
        today: DateTime(2026, 9, 19),
      );

      expect(res.groups.isNotEmpty, isTrue);
      final group = res.groups.first;
      expect(group.status, HrtChangeStatus.pending);
      expect(group.daysSinceChange, 6);
      expect(group.daysToGo, 8); // 14 - 6 = 8
    });

    test('T3-H-2: Boundary conditions for elapsed days (14 days = ready/followUp; 13 days = pending)', () {
      final change5Sep = HrtDoseChange(
        userId: 'test_user', medicationId: 'med_1', medicationName: 'Estradiol',
        oldDose: 1, newDose: 2, unit: 'mg', changeDate: DateTime(2026, 9, 5),
      );
      final change6Sep = HrtDoseChange(
        userId: 'test_user', medicationId: 'med_2', medicationName: 'Estradiol',
        oldDose: 1, newDose: 2, unit: 'mg', changeDate: DateTime(2026, 9, 6),
      );
      // Need at least 7 logs before 5 Sep (e.g. 22 Aug - 4 Sep)
      final baselineLogs = List.generate(14, (i) => createLog(date: DateTime(2026, 8, 22 + i)));
      final logs = [...baselineLogs, ...goldenDatasetLogs()];

      final res5 = analyzer.analyze(
        doseChanges: [change5Sep], medications: [], logs: logs, today: DateTime(2026, 9, 19),
      );
      // Elapsed 14 days -> not pending
      expect(res5.groups.first.status != HrtChangeStatus.pending, isTrue);

      final res6 = analyzer.analyze(
        doseChanges: [change6Sep], medications: [], logs: logs, today: DateTime(2026, 9, 19),
      );
      // Elapsed 13 days -> pending, 1 day to go
      expect(res6.groups.first.status, HrtChangeStatus.pending);
      expect(res6.groups.first.daysToGo, 1);
    });

    test('T3-H-3: Orphan dose change analyzed normally using stored medication name', () {
      final orphanChange = HrtDoseChange(
        userId: 'test_user', medicationId: 'med_orphan', medicationName: 'Old Estradiol Gel',
        oldDose: 2, newDose: 4, unit: 'pumps', changeDate: DateTime(2026, 9, 13),
      );
      final res = analyzer.analyze(
        doseChanges: [orphanChange],
        medications: [], // Empty medications list
        logs: goldenDatasetLogs(),
        today: DateTime(2026, 9, 19),
      );
      expect(res.groups.isNotEmpty, isTrue);
      expect(res.groups.first.events.first.medicationName, 'Old Estradiol Gel');
    });

    test('T3-H-4: notEnoughBaseline when fewer than 7 logged days before change', () {
      final change = HrtDoseChange(
        userId: 'test_user', medicationId: 'med_1', medicationName: 'Estradiol',
        oldDose: 1, newDose: 2, unit: 'mg', changeDate: DateTime(2026, 9, 13),
      );
      // Only 5 logged days before change (8-12 Sep)
      final logs = List.generate(12, (i) => createLog(date: DateTime(2026, 9, 8 + i)));
      final res = analyzer.analyze(
        doseChanges: [change], medications: [], logs: logs, today: DateTime(2026, 9, 19),
      );
      expect(res.groups.first.status, HrtChangeStatus.notEnoughBaseline);
    });

    test('T3-H-5: notEnoughFollowUp when >= 14 elapsed but < 7 logged days in follow-up', () {
      final change = HrtDoseChange(
        userId: 'test_user', medicationId: 'med_1', medicationName: 'Estradiol',
        oldDose: 1, newDose: 2, unit: 'mg', changeDate: DateTime(2026, 8, 25),
      );
      // 10 logged days before; only 4 logged days after
      final beforeLogs = List.generate(10, (i) => createLog(date: DateTime(2026, 8, 15 + i)));
      final afterLogs = List.generate(4, (i) => createLog(date: DateTime(2026, 8, 26 + i)));
      final res = analyzer.analyze(
        doseChanges: [change], medications: [], logs: [...beforeLogs, ...afterLogs], today: DateTime(2026, 9, 19),
      );
      expect(res.groups.first.status, HrtChangeStatus.notEnoughFollowUp);
    });

    test('T3-H-6: Ready change status with neat numbers and direction wording', () {
      final change = HrtDoseChange(
        userId: 'test_user', medicationId: 'med_1', medicationName: 'Estradiol',
        oldDose: 1, newDose: 2, unit: 'mg', changeDate: DateTime(2026, 9, 1),
      );
      // 14 days before (18-31 Aug): hot flash Moderate on 7 of 14 days
      final beforeLogs = List.generate(14, (i) {
        final date = DateTime(2026, 8, 18 + i);
        return createLog(
          date: date,
          symptoms: i < 7 ? [hotFlash('Moderate')] : [],
        );
      });
      // 14 days after (2-15 Sep): hot flash Mild on 7 of 14 days
      final afterLogs = List.generate(14, (i) {
        final date = DateTime(2026, 9, 2 + i);
        return createLog(
          date: date,
          symptoms: i < 7 ? [hotFlash('Mild')] : [],
        );
      });

      final res = analyzer.analyze(
        doseChanges: [change], medications: [], logs: [...beforeLogs, ...afterLogs], today: DateTime(2026, 9, 15),
      );
      final g = res.groups.first;
      expect(g.status, HrtChangeStatus.ready);
      expect(g.symptomResults.isNotEmpty, isTrue);
      final hf = g.symptomResults.firstWhere((s) => s.symptomId == 'hot_flash');
      expect(hf.daysPresentBefore, 7);
      expect(hf.daysPresentAfter, 7);
      expect(hf.averageSeverityBefore, 3.0);
      expect(hf.averageSeverityAfter, 1.0);
      expect(hf.burdenBefore, 1.5);
      expect(hf.burdenAfter, 0.5);
      expect(hf.directionWording, 'milder');
    });

    test('T3-H-10: Same-day grouping and overlapping notes', () {
      final c1 = HrtDoseChange(
        userId: 'u', medicationId: 'm1', medicationName: 'M1',
        oldDose: 1, newDose: 2, unit: 'mg', changeDate: DateTime(2026, 9, 13),
      );
      final c2 = HrtDoseChange(
        userId: 'u', medicationId: 'm2', medicationName: 'M2',
        oldDose: 50, newDose: 100, unit: 'mcg', changeDate: DateTime(2026, 9, 13),
      );
      final c3 = HrtDoseChange(
        userId: 'u', medicationId: 'm3', medicationName: 'M3',
        oldDose: 10, newDose: 20, unit: 'mg', changeDate: DateTime(2026, 9, 18),
      );
      final res = analyzer.analyze(
        doseChanges: [c1, c2, c3], medications: [], logs: goldenDatasetLogs(), today: DateTime(2026, 9, 19),
      );
      // c1 and c2 should group into 1 group; c3 forms another group
      expect(res.groups.length, 2);
      expect(res.groups.any((g) => g.overlappingNotes.isNotEmpty), isTrue);
    });

    test('T3-H-12: Weekday-only administrative changes are ignored', () {
      final change = HrtDoseChange(
        userId: 'u', medicationId: 'm1', medicationName: 'M1',
        oldDose: 1, newDose: 1, unit: 'mg', changeDate: DateTime(2026, 9, 13),
        changeType: RegimenChangeType.scheduleDayChange,
      );
      final res = analyzer.analyze(
        doseChanges: [change], medications: [], logs: goldenDatasetLogs(), today: DateTime(2026, 9, 19),
      );
      expect(res.groups.isEmpty, isTrue);
    });

    test('T3-H-14: Adherence calculation counts scheduled doses only', () {
      // Medication scheduled Mon & Thu (weekdays 1 & 4)
      final med = Medication(
        id: 'med_scheduled',
        name: 'Oestrogel',
        type: MedicationType.gel,
        dose: 2,
        unit: 'pumps',
        frequency: 'Twice weekly',
        selectedWeekdays: [1, 4],
        startedAt: DateTime(2026, 8, 1),
      );
      final change = HrtDoseChange(
        userId: 'u', medicationId: 'med_scheduled', medicationName: 'Oestrogel',
        oldDose: 1, newDose: 2, unit: 'pumps', changeDate: DateTime(2026, 9, 1),
      );
      // Need at least 7 logs before 1 Sep (18-31 Aug)
      final beforeLogs = List.generate(14, (i) => createLog(date: DateTime(2026, 8, 18 + i)));

      // 14 days after (2-15 Sep): Mon 7, 14; Thu 3, 10 -> 4 scheduled doses
      // Provide 3 intakes
      final afterLogs = List.generate(14, (i) {
        final date = DateTime(2026, 9, 2 + i);
        final isIntake = i == 1 || i == 5 || i == 8; // 3 of 4
        return createLog(
          date: date,
          hrtIntakes: isIntake ? [HrtIntakeLog(medicationId: 'med_scheduled', name: 'Oestrogel', dose: 2, unit: 'pumps', time: '08:00', isTaken: true)] : [],
        );
      });

      final res = analyzer.analyze(
        doseChanges: [change], medications: [med], logs: [...beforeLogs, ...afterLogs], today: DateTime(2026, 9, 16),
      );
      final adh = res.groups.first.adherence;
      expect(adh, isNotNull);
      expect(adh!.scheduledDoses, 4);
    });

    test('T3-H-20: Approved HRT disclaimer present verbatim', () {
      final change = HrtDoseChange(
        userId: 'u', medicationId: 'm1', medicationName: 'M1',
        oldDose: 1, newDose: 2, unit: 'mg', changeDate: DateTime(2026, 9, 13),
      );
      final res = analyzer.analyze(
        doseChanges: [change], medications: [], logs: goldenDatasetLogs(), today: DateTime(2026, 9, 19),
      );
      expect(res.groups.first.disclaimer, kApprovedHrtDisclaimer);
    });
  });
}
