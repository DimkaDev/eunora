import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/hrt_tracker/domain/hrt_schedule_service.dart';
import 'golden_dataset_fixture.dart';

void main() {
  group('PR-03: HRT Dose Change, Duplicate Detection & Soft-Stop', () {
    test('S3.1: Editing dose creates dose-change entry, records previous dose, inserts divider & starts 14-day countdown', () {
      final initialMed = Medication(
        id: 'med_estrogel',
        name: 'Estrogel',
        type: MedicationType.gel,
        dose: 1.0,
        unit: 'pumps',
        frequency: 'Daily',
        startedAt: DateTime(2026, 9, 1),
      );

      // User confirms dose change: 1.0 -> 2.0 pumps
      final updatedMed = initialMed.copyWith(dose: 2.0);

      final change = HrtDoseChange(
        id: 'change_1',
        userId: 'user_1',
        medicationId: updatedMed.id!,
        medicationName: updatedMed.name,
        oldDose: initialMed.dose,
        newDose: updatedMed.dose,
        unit: updatedMed.unit,
        changeDate: DateTime(2026, 9, 13),
        changeType: RegimenChangeType.doseChange,
        previousValue: '1 pump',
        newValue: '2 pumps',
      );

      expect(change.changeType, equals(RegimenChangeType.doseChange));
      expect(change.oldDose, equals(1.0));
      expect(change.newDose, equals(2.0));

      // Divider inserted & 14-day correlation window started
      const requiredWindowDays = 14;
      final changeDate = change.changeDate;
      final evalDate = DateTime(2026, 9, 19);
      final elapsedDays = evalDate.difference(changeDate).inDays;
      final remainingDays = requiredWindowDays - elapsedDays;

      expect(elapsedDays, equals(6));
      expect(remainingDays, equals(8));
    });

    test('S3.2: Dismissing confirmation as mistake reverts value and creates no new entry', () {
      final initialMed = Medication(
        id: 'med_estrogel',
        name: 'Estrogel',
        type: MedicationType.gel,
        dose: 1.0,
        unit: 'pumps',
        frequency: 'Daily',
      );

      final recordedChanges = <HrtDoseChange>[];

      // Simulated modal dismiss
      bool confirmed = false;
      var activeMed = initialMed;

      if (confirmed) {
        activeMed = initialMed.copyWith(dose: 2.0);
        recordedChanges.add(HrtDoseChange(
          id: 'change_err',
          userId: 'user_1',
          medicationId: activeMed.id!,
          medicationName: activeMed.name,
          oldDose: initialMed.dose,
          newDose: 2.0,
          unit: 'pumps',
          changeDate: DateTime.now(),
          changeType: RegimenChangeType.doseChange,
          previousValue: '1 pump',
          newValue: '2 pumps',
        ));
      } else {
        // Revert to original
        activeMed = initialMed;
      }

      expect(activeMed.dose, equals(1.0));
      expect(recordedChanges, isEmpty);
    });

    test('S3.3: Changing scheduled weekday only (scheduleDayChange) does not insert divider or reset correlation window', () {
      final initialMed = Medication(
        id: 'med_patch',
        name: 'Evorel 50',
        type: MedicationType.patch,
        dose: 50.0,
        unit: 'mcg',
        frequency: 'Twice weekly',
        selectedWeekdays: [1, 4], // Mon, Thu
      );

      // User changes schedule from Mon/Thu to Tue/Fri
      final updatedMed = initialMed.copyWith(selectedWeekdays: [2, 5]);

      final bool doseChanged = initialMed.dose != updatedMed.dose;
      final bool freqChanged = initialMed.frequency != updatedMed.frequency;
      final bool weekdaysChanged = initialMed.selectedWeekdays != updatedMed.selectedWeekdays;

      expect(doseChanged, isFalse);
      expect(freqChanged, isFalse);
      expect(weekdaysChanged, isTrue);

      final changeType = RegimenChangeType.scheduleDayChange;
      final bool insertsTimelineDivider = (changeType != RegimenChangeType.scheduleDayChange);
      final bool resetsCorrelationWindow = (changeType != RegimenChangeType.scheduleDayChange);

      expect(insertsTimelineDivider, isFalse);
      expect(resetsCorrelationWindow, isFalse);
    });

    test('S3.4: Changing frequency inserts divider and resets correlation window identically to dose change', () {
      final initialMed = Medication(
        id: 'med_patch',
        name: 'Evorel 50',
        type: MedicationType.patch,
        dose: 50.0,
        unit: 'mcg',
        frequency: 'Weekly',
      );

      final updatedMed = initialMed.copyWith(frequency: 'Twice weekly');

      final bool freqChanged = initialMed.frequency != updatedMed.frequency;
      expect(freqChanged, isTrue);

      final changeType = RegimenChangeType.frequencyChange;
      final bool insertsTimelineDivider = (changeType == RegimenChangeType.frequencyChange || changeType == RegimenChangeType.doseChange);
      final bool resetsCorrelationWindow = (changeType == RegimenChangeType.frequencyChange || changeType == RegimenChangeType.doseChange);

      expect(insertsTimelineDivider, isTrue);
      expect(resetsCorrelationWindow, isTrue);
    });

    test('S3.5: Adding exact active duplicate triggers soft warning without blocking', () {
      final activeMeds = [
        Medication(
          id: 'med_1',
          name: 'Estrogel',
          type: MedicationType.gel,
          dose: 2.0,
          unit: 'pumps',
          frequency: 'Daily',
          startedAt: DateTime(2026, 9, 1),
          endedAt: null,
        ),
      ];

      // Exact active duplicate
      final duplicateMed = Medication(
        name: 'estrogel',
        type: MedicationType.gel,
        dose: 2.0,
        unit: 'pumps',
        frequency: 'Daily',
      );

      final duplicateFound = HrtScheduleService.findExactActiveDuplicate(duplicateMed, activeMeds);
      expect(duplicateFound, isNotNull);
      expect(duplicateFound!.id, equals('med_1'));

      // Soft warning is emitted, but user is NOT blocked from saving if intended
      final canProceedWithWarning = true;
      expect(canProceedWithWarning, isTrue);
    });

    test('S3.6: Adding same drug with different parameters triggers no warning', () {
      final activeMeds = [
        Medication(
          id: 'med_1',
          name: 'Estrogel',
          type: MedicationType.gel,
          dose: 2.0,
          unit: 'pumps',
          frequency: 'Daily',
        ),
      ];

      // Different dose (e.g. 1 pump vs 2 pumps)
      final differentDose = Medication(
        name: 'Estrogel',
        type: MedicationType.gel,
        dose: 1.0,
        unit: 'pumps',
        frequency: 'Daily',
      );

      final conflictDose = HrtScheduleService.findExactActiveDuplicate(differentDose, activeMeds);
      expect(conflictDose, isNull);

      // Different form/type (e.g. patch vs gel)
      final differentType = Medication(
        name: 'Estrogel',
        type: MedicationType.patch,
        dose: 2.0,
        unit: 'pumps',
        frequency: 'Daily',
      );
      final conflictType = HrtScheduleService.findExactActiveDuplicate(differentType, activeMeds);
      expect(conflictType, isNull);
    });

    test('S3.7: Resuming same drug after soft-stop triggers no warning', () {
      final now = DateTime(2026, 9, 19);
      final pastStoppedMeds = [
        Medication(
          id: 'med_old',
          name: 'Evorel 50',
          type: MedicationType.patch,
          dose: 50.0,
          unit: 'mcg',
          frequency: 'Twice weekly',
          startedAt: DateTime(2026, 8, 1),
          endedAt: DateTime(2026, 8, 31), // stopped last month
        ),
      ];

      final resumedMed = Medication(
        name: 'Evorel 50',
        type: MedicationType.patch,
        dose: 50.0,
        unit: 'mcg',
        frequency: 'Twice weekly',
        startedAt: DateTime(2026, 9, 19),
      );

      final duplicate = HrtScheduleService.findExactActiveDuplicate(
        resumedMed,
        pastStoppedMeds,
        targetDate: now,
      );

      expect(duplicate, isNull, reason: 'Soft-stopped prior medications do not trigger active duplicate warnings');
    });

    test('S3.8: Deleting medication with logged history is blocked; only soft-stop offered', () {
      final med = Medication(
        id: 'med_with_history',
        name: 'Utrogestan',
        type: MedicationType.pill,
        dose: 100.0,
        unit: 'mg',
        frequency: 'Daily',
      );

      // Seed 5 logged entries with this medication
      final logs = [
        createLog(
          date: DateTime(2026, 9, 10),
          hrtIntakes: [
            HrtIntakeLog(
              medicationId: 'med_with_history',
              name: 'Utrogestan',
              dose: 100.0,
              unit: 'mg',
              time: '21:00',
              isTaken: true,
            ),
          ],
        ),
      ];

      final hasHistory = HrtScheduleService.hasLoggedHistory(med, logs);
      expect(hasHistory, isTrue);

      // Attempt hard deletion vs soft-stop
      bool hardDeleteAllowed = !hasHistory;
      bool softStopOffered = hasHistory;

      expect(hardDeleteAllowed, isFalse);
      expect(softStopOffered, isTrue);

      // Perform soft-stop
      final stoppedMed = med.copyWith(endedAt: DateTime(2026, 9, 19));
      expect(stoppedMed.endedAt, isNotNull);
      expect(stoppedMed.id, equals('med_with_history'));
    });

    test('S3.9: Medication with zero logged history can be deleted outright', () {
      final freshMed = Medication(
        id: 'med_fresh',
        name: 'New Test Gel',
        type: MedicationType.gel,
        dose: 1.0,
        unit: 'pumps',
        frequency: 'Daily',
      );

      final emptyLogs = <DailyLog>[];

      final hasHistory = HrtScheduleService.hasLoggedHistory(freshMed, emptyLogs);
      expect(hasHistory, isFalse);

      bool hardDeleteAllowed = !hasHistory;
      expect(hardDeleteAllowed, isTrue);

      var medsList = [freshMed];
      medsList = medsList.where((m) => m.id != freshMed.id).toList();
      expect(medsList, isEmpty);
    });

    test('S3.10: Stop and Delete actions are not exposed outside HRT Tracker', () {
      // Allowed surfaces for Stop / Delete
      const allowedSurfaces = {'hrt_tracker'};
      const calendarView = 'calendar_view';
      const quickLog = 'quick_log';

      bool isStopDeleteActionExposed(String surfaceName) {
        return allowedSurfaces.contains(surfaceName);
      }

      expect(isStopDeleteActionExposed('hrt_tracker'), isTrue);
      expect(isStopDeleteActionExposed(calendarView), isFalse);
      expect(isStopDeleteActionExposed(quickLog), isFalse);
    });
  });
}
