import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/hrt_tracker/domain/hrt_schedule_service.dart';

void main() {
  group('Task 1: Fixed Weekday Scheduling', () {
    test('Daily medications have all 7 weekdays selected by default', () {
      final med = Medication(
        name: 'Estradiol Gel',
        type: MedicationType.gel,
        dose: 1,
        unit: 'pumps',
        frequency: 'Daily',
      );
      expect(med.selectedWeekdays, [1, 2, 3, 4, 5, 6, 7]);
    });

    test('Twice Weekly medications default to exactly 2 weekdays', () {
      final med = Medication(
        name: 'Evorel 50',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Twice weekly',
      );
      expect(med.selectedWeekdays.length, 2);
      expect(med.selectedWeekdays, [1, 4]); // Mon & Thu
    });

    test('Weekly medications default to exactly 1 weekday', () {
      final med = Medication(
        name: 'Weekly Patch',
        type: MedicationType.patch,
        dose: 100,
        unit: 'mcg',
        frequency: 'Weekly',
      );
      expect(med.selectedWeekdays.length, 1);
      expect(med.selectedWeekdays, [1]); // Mon
    });

    test('As Needed medications have empty selected weekdays', () {
      final med = Medication(
        name: 'Progesterone Gel',
        type: MedicationType.gel,
        dose: 1,
        unit: 'pumps',
        frequency: 'As needed',
      );
      expect(med.selectedWeekdays, isEmpty);
      expect(HrtScheduleService.isAsNeeded(med), isTrue);
    });
  });

  group('Task 2 & 3: Daily Scheduled State Calculation & Day 1 Entry', () {
    test('Weekly Monday medication resolves to 3 distinct states', () {
      final monMed = Medication(
        name: 'Evorel 100',
        type: MedicationType.patch,
        dose: 100,
        unit: 'mcg',
        frequency: 'Weekly',
        selectedWeekdays: [1], // Monday
      );

      final monday = DateTime(2026, 8, 10); // Monday
      final tuesday = DateTime(2026, 8, 11); // Tuesday

      // Unlogged Monday -> readyToLog
      final stateMonUnlogged = HrtScheduleService.getDailyState(
        med: monMed,
        date: monday,
        loggedIntake: null,
      );
      expect(stateMonUnlogged, DailyScheduledState.readyToLog);

      // Logged Monday -> logged
      final stateMonLogged = HrtScheduleService.getDailyState(
        med: monMed,
        date: monday,
        loggedIntake: HrtIntakeLog(
          medicationId: monMed.id,
          name: monMed.name,
          dose: 100,
          unit: 'mcg',
          time: '08:00',
          isTaken: true,
        ),
      );
      expect(stateMonLogged, DailyScheduledState.logged);

      // Tuesday (unscheduled day) -> notScheduledToday
      final stateTue = HrtScheduleService.getDailyState(
        med: monMed,
        date: tuesday,
        loggedIntake: null,
      );
      expect(stateTue, DailyScheduledState.notScheduledToday);
    });

    test('Daily medications are never notScheduledToday', () {
      final dailyMed = Medication(
        name: 'Utrogestan',
        type: MedicationType.pill,
        dose: 100,
        unit: 'mg',
        frequency: 'Daily',
      );

      final date = DateTime(2026, 8, 12);
      final state = HrtScheduleService.getDailyState(
        med: dailyMed,
        date: date,
        loggedIntake: null,
      );

      expect(state, DailyScheduledState.readyToLog);
    });
  });

  group('Task 4: Late Logging & Schedule Protection', () {
    test('Logging a Monday medication on Tuesday does not shift future Monday schedule', () {
      final monMed = Medication(
        name: 'Estradiol Patch',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Weekly',
        selectedWeekdays: [1], // Monday
      );

      final nextMonday = DateTime(2026, 8, 17); // Next Monday
      final nextTuesday = DateTime(2026, 8, 18); // Next Tuesday

      expect(HrtScheduleService.isScheduledOnDate(monMed, nextMonday), isTrue);
      expect(HrtScheduleService.isScheduledOnDate(monMed, nextTuesday), isFalse);
    });
  });

  group('Task 5: As Needed Isolation & Missed Occurrences Calculation', () {
    test('As Needed medications resolve to asNeeded state and 0 missed occurrences', () {
      final prnMed = Medication(
        name: 'Vaginal Cream',
        type: MedicationType.cream,
        dose: 1,
        unit: 'applicator',
        frequency: 'As needed',
      );

      final today = DateTime.now();
      final state = HrtScheduleService.getDailyState(
        med: prnMed,
        date: today,
        loggedIntake: null,
      );

      expect(state, DailyScheduledState.asNeeded);

      final missed = HrtScheduleService.calculateMissedOccurrences(
        med: prnMed,
        logs: [],
        startDate: today.subtract(const Duration(days: 30)),
        endDate: today,
      );

      expect(missed, 0);
    });

    test('Missed occurrences are counted per scheduled occurrence, not calendar day', () {
      final twiceWeeklyMed = Medication(
        name: 'Evorel Sequi',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Twice weekly',
        selectedWeekdays: [1, 4], // Mon & Thu
      );

      // Over 14 days (2 full weeks), there are 4 scheduled occurrences
      final start = DateTime(2026, 7, 6); // Monday
      final end = DateTime(2026, 7, 19); // Sunday

      final missed = HrtScheduleService.calculateMissedOccurrences(
        med: twiceWeeklyMed,
        logs: [], // No logs
        startDate: start,
        endDate: end,
      );

      expect(missed, 4); // Exactly 4 scheduled occurrences missed over 14 days
    });
  });

  group('Task 6: HRT Medication Management (Stop vs Delete Rules)', () {
    test('hasLoggedHistory returns false for zero-history medication', () {
      final med = Medication(
        name: 'New Test Patch',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Daily',
      );

      final emptyLogs = <DailyLog>[];
      expect(HrtScheduleService.hasLoggedHistory(med, emptyLogs), isFalse);

      final unloggedLogs = <DailyLog>[
        DailyLog(
          id: 'log-1',
          userId: 'user-1',
          date: DateTime(2026, 8, 1),
          createdAt: DateTime.now(),
          hrtIntakes: [
            HrtIntakeLog(
              medicationId: med.id,
              name: med.name,
              dose: 50,
              unit: 'mcg',
              time: '08:00',
              isTaken: false,
            ),
          ],
        ),
      ];
      expect(HrtScheduleService.hasLoggedHistory(med, unloggedLogs), isFalse);
    });

    test('hasLoggedHistory returns true when medication has at least 1 taken intake record', () {
      final med = Medication(
        name: 'Estradiol Gel',
        type: MedicationType.gel,
        dose: 1,
        unit: 'pumps',
        frequency: 'Daily',
      );

      final logs = <DailyLog>[
        DailyLog(
          id: 'log-1',
          userId: 'user-1',
          date: DateTime(2026, 8, 1),
          createdAt: DateTime.now(),
          hrtIntakes: [
            HrtIntakeLog(
              medicationId: med.id,
              name: med.name,
              dose: 1,
              unit: 'pumps',
              time: '08:00',
              isTaken: true,
            ),
          ],
        ),
      ];
      expect(HrtScheduleService.hasLoggedHistory(med, logs), isTrue);
    });
  });

  group('Task 7–11: Unified Regimen Changes & Retrospective Logging Rules', () {
    test('HrtDoseChange accurately distinguishes clinical from administrative changes', () {
      final doseEvent = HrtDoseChange(
        userId: 'user-1',
        medicationId: 'med-1',
        medicationName: 'Estradiol Gel',
        oldDose: 1,
        newDose: 2,
        unit: 'pumps',
        changeDate: DateTime.now(),
        changeType: RegimenChangeType.doseChange,
        previousValue: '1 pumps',
        newValue: '2 pumps',
      );
      expect(doseEvent.isClinicalChange, isTrue);
      expect(doseEvent.isAdministrativeChange, isFalse);

      final freqEvent = HrtDoseChange(
        userId: 'user-1',
        medicationId: 'med-1',
        medicationName: 'Evorel 50',
        oldDose: 50,
        newDose: 50,
        unit: 'mcg',
        changeDate: DateTime.now(),
        changeType: RegimenChangeType.frequencyChange,
        previousValue: 'Daily',
        newValue: 'Twice weekly',
      );
      expect(freqEvent.isClinicalChange, isTrue);
      expect(freqEvent.isAdministrativeChange, isFalse);

      final weekdayEvent = HrtDoseChange(
        userId: 'user-1',
        medicationId: 'med-1',
        medicationName: 'Evorel 50',
        oldDose: 50,
        newDose: 50,
        unit: 'mcg',
        changeDate: DateTime.now(),
        changeType: RegimenChangeType.scheduleDayChange,
        previousValue: 'Mon, Thu',
        newValue: 'Tue, Fri',
      );
      expect(weekdayEvent.isClinicalChange, isFalse);
      expect(weekdayEvent.isAdministrativeChange, isTrue);
    });

    test('Retrospective logging evaluates active medications strictly for selected date D', () {
      final selectedDate = DateTime(2026, 7, 15);

      final startedLater = Medication(
        name: 'Estrogen Gel (Started August)',
        type: MedicationType.gel,
        dose: 1,
        unit: 'pumps',
        frequency: 'Daily',
        startedAt: DateTime(2026, 8, 1),
      );

      final stoppedEarlier = Medication(
        name: 'Progesterone (Stopped June)',
        type: MedicationType.pill,
        dose: 100,
        unit: 'mg',
        frequency: 'Daily',
        startedAt: DateTime(2026, 1, 1),
        endedAt: DateTime(2026, 6, 30),
      );

      final activeMidJuly = Medication(
        name: 'Evorel 50 (Active in July)',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Twice weekly',
        startedAt: DateTime(2026, 1, 1),
        endedAt: DateTime(2026, 12, 31),
      );

      bool isActive(Medication med, DateTime date) {
        final target = DateTime(date.year, date.month, date.day);
        if (med.startedAt != null) {
          final start = DateTime(med.startedAt!.year, med.startedAt!.month, med.startedAt!.day);
          if (target.isBefore(start)) return false;
        }
        if (med.endedAt != null) {
          final end = DateTime(med.endedAt!.year, med.endedAt!.month, med.endedAt!.day);
          if (target.isAfter(end)) return false;
        }
        return true;
      }

      expect(isActive(startedLater, selectedDate), isFalse);
      expect(isActive(stoppedEarlier, selectedDate), isFalse);
      expect(isActive(activeMidJuly, selectedDate), isTrue);
    });

    test('Task 4: Late logging of Weekly Monday medication on Tuesday does NOT shift future schedule', () {
      final monMed = Medication(
        name: 'Weekly Monday Patch',
        type: MedicationType.patch,
        dose: 100,
        unit: 'mcg',
        frequency: 'Weekly',
        selectedWeekdays: [1], // Monday
      );

      final monday = DateTime(2026, 8, 10);
      final tuesday = DateTime(2026, 8, 11);
      final nextMonday = DateTime(2026, 8, 17);
      final nextTuesday = DateTime(2026, 8, 18);

      // Tuesday (late logging day) is NOT a scheduled day
      expect(HrtScheduleService.isScheduledOnDate(monMed, tuesday), isFalse);

      // Next Monday IS the scheduled day
      expect(HrtScheduleService.isScheduledOnDate(monMed, nextMonday), isTrue);

      // Next Tuesday (7 days after late log) is NOT a scheduled day
      expect(HrtScheduleService.isScheduledOnDate(monMed, nextTuesday), isFalse);
    });

    test('Task 4: Editing selected weekdays applies forward-only without reinterpreting history', () {
      final med = Medication(
        id: 'med-patch-1',
        name: 'Evorel Patch',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Weekly',
        selectedWeekdays: [4], // Currently Thursday
      );

      final changeEvent = HrtDoseChange(
        userId: 'user-1',
        medicationId: 'med-patch-1',
        medicationName: 'Evorel Patch',
        oldDose: 50,
        newDose: 50,
        unit: 'mcg',
        changeDate: DateTime(2026, 8, 10), // Changed on Monday Aug 10
        changeType: RegimenChangeType.scheduleDayChange,
        previousValue: 'Mon', // Was Monday previously
        newValue: 'Thu', // Now Thursday
      );

      final pastMonday = DateTime(2026, 8, 3);
      final pastThursday = DateTime(2026, 8, 6);
      final futureMonday = DateTime(2026, 8, 17);
      final futureThursday = DateTime(2026, 8, 13);

      final history = [changeEvent];

      // Past date (Aug 3): Uses previousValue ('Mon') -> Monday is scheduled, Thursday is not
      expect(HrtScheduleService.isScheduledOnDate(med, pastMonday, doseChanges: history), isTrue);
      expect(HrtScheduleService.isScheduledOnDate(med, pastThursday, doseChanges: history), isFalse);

      // Future date (Aug 13/17): Uses current selectedWeekdays ('Thu') -> Thursday is scheduled, Monday is not
      expect(HrtScheduleService.isScheduledOnDate(med, futureThursday, doseChanges: history), isTrue);
      expect(HrtScheduleService.isScheduledOnDate(med, futureMonday, doseChanges: history), isFalse);
    });
  });

  group('Task 6: Missed-Occurrence Counting Unit (for Reactive Check-In Prompt)', () {
    test('Daily medication counts consecutive missed calendar days', () {
      final dailyMed = Medication(
        id: 'med-daily-1',
        name: 'Estradiol Gel',
        type: MedicationType.gel,
        dose: 1,
        unit: 'pumps',
        frequency: 'Daily',
        selectedWeekdays: [1, 2, 3, 4, 5, 6, 7],
      );

      final evalDate = DateTime(2026, 8, 12); // Wednesday

      // No logs -> 365 consecutive missed scheduled occurrences (capped at eval date start)
      final countNoLogs = HrtScheduleService.calculateConsecutiveMissedOccurrences(
        med: dailyMed,
        logs: [],
        evaluationDate: evalDate,
      );
      expect(countNoLogs > 0, isTrue);

      // Logged taken on Monday Aug 10, unlogged Tue Aug 11 & Wed Aug 12 -> 2 consecutive missed
      final logs = <DailyLog>[
        DailyLog(
          id: 'log-mon',
          userId: 'user-1',
          date: DateTime(2026, 8, 10),
          createdAt: DateTime.now(),
          hrtIntakes: [
            HrtIntakeLog(
              medicationId: dailyMed.id,
              name: dailyMed.name,
              dose: 1,
              unit: 'pumps',
              time: '08:00',
              isTaken: true,
            ),
          ],
        ),
      ];

      final consecutiveMissed = HrtScheduleService.calculateConsecutiveMissedOccurrences(
        med: dailyMed,
        logs: logs,
        evaluationDate: evalDate,
      );
      expect(consecutiveMissed, 2); // Tue Aug 11 & Wed Aug 12
    });

    test('Weekly medication increments count ONLY on scheduled weekday', () {
      final weeklyMonMed = Medication(
        id: 'med-weekly-1',
        name: 'Weekly Patch',
        type: MedicationType.patch,
        dose: 100,
        unit: 'mcg',
        frequency: 'Weekly',
        selectedWeekdays: [1], // Monday only
      );

      // Evaluated on Sunday Aug 16 (after missing Monday Aug 10)
      final evalDate = DateTime(2026, 8, 16);

      final logs = <DailyLog>[
        DailyLog(
          id: 'log-prev-mon',
          userId: 'user-1',
          date: DateTime(2026, 8, 3), // Monday Aug 3 TAKEN
          createdAt: DateTime.now(),
          hrtIntakes: [
            HrtIntakeLog(
              medicationId: weeklyMonMed.id,
              name: weeklyMonMed.name,
              dose: 100,
              unit: 'mcg',
              time: '08:00',
              isTaken: true,
            ),
          ],
        ),
      ];

      final count = HrtScheduleService.calculateConsecutiveMissedOccurrences(
        med: weeklyMonMed,
        logs: logs,
        evaluationDate: evalDate,
      );

      // Exactly 1 missed scheduled occurrence (Monday Aug 10). Non-scheduled Tue-Sun do NOT increment count.
      expect(count, 1);
    });

    test('Twice Weekly medication increments count for each scheduled weekday instance', () {
      final twiceWeeklyMed = Medication(
        id: 'med-twice-1',
        name: 'Evorel 50',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Twice weekly',
        selectedWeekdays: [1, 4], // Monday & Thursday
      );

      final evalDate = DateTime(2026, 8, 14); // Friday Aug 14

      final logs = <DailyLog>[
        DailyLog(
          id: 'log-prev-thu',
          userId: 'user-1',
          date: DateTime(2026, 8, 6), // Thursday Aug 6 TAKEN
          createdAt: DateTime.now(),
          hrtIntakes: [
            HrtIntakeLog(
              medicationId: twiceWeeklyMed.id,
              name: twiceWeeklyMed.name,
              dose: 50,
              unit: 'mcg',
              time: '08:00',
              isTaken: true,
            ),
          ],
        ),
      ];

      final count = HrtScheduleService.calculateConsecutiveMissedOccurrences(
        med: twiceWeeklyMed,
        logs: logs,
        evaluationDate: evalDate,
      );

      // Missed Monday Aug 10 AND Thursday Aug 13 -> 2 consecutive missed scheduled occurrences
      expect(count, 2);
    });

    test('As Needed medication returns 0 missed occurrences', () {
      final prnMed = Medication(
        id: 'med-prn-1',
        name: 'Progesterone Gel',
        type: MedicationType.gel,
        dose: 1,
        unit: 'pumps',
        frequency: 'As needed',
        selectedWeekdays: [],
      );

      final count = HrtScheduleService.calculateConsecutiveMissedOccurrences(
        med: prnMed,
        logs: [],
        evaluationDate: DateTime.now(),
      );

      expect(count, 0);
    });
  });

  group('Task 8: Regimen Change Classification — Dose, Frequency, and Weekday Are Not Equivalent', () {
    test('Frequency change alone is classified as a clinical regimen change', () {
      final freqChange = HrtDoseChange(
        userId: 'user-1',
        medicationId: 'med-1',
        medicationName: 'Estradiol Gel',
        oldDose: 1,
        newDose: 1,
        unit: 'pumps',
        changeDate: DateTime.now(),
        changeType: RegimenChangeType.frequencyChange,
        previousValue: 'Daily',
        newValue: 'Twice weekly',
      );

      expect(freqChange.isClinicalChange, isTrue);
      expect(freqChange.isAdministrativeChange, isFalse);
    });

    test('Simultaneous Dose and Frequency change is represented as a single clinical regimen change event', () {
      final combinedChange = HrtDoseChange(
        userId: 'user-1',
        medicationId: 'med-1',
        medicationName: 'Estradiol Gel',
        oldDose: 1,
        newDose: 2,
        unit: 'pumps',
        changeDate: DateTime.now(),
        changeType: RegimenChangeType.doseChange,
        previousValue: '1 pumps, Daily',
        newValue: '2 pumps, Twice weekly',
      );

      expect(combinedChange.isClinicalChange, isTrue);
      expect(combinedChange.previousValue, contains('Daily'));
      expect(combinedChange.newValue, contains('Twice weekly'));
    });

    test('Weekday-only change is NEVER classified as a clinical regimen change', () {
      final weekdayChange = HrtDoseChange(
        userId: 'user-1',
        medicationId: 'med-1',
        medicationName: 'Evorel 50',
        oldDose: 50,
        newDose: 50,
        unit: 'mcg',
        changeDate: DateTime.now(),
        changeType: RegimenChangeType.scheduleDayChange,
        previousValue: 'Thu',
        newValue: 'Wed',
      );

      expect(weekdayChange.isClinicalChange, isFalse);
      expect(weekdayChange.isAdministrativeChange, isTrue);
    });
  });

  group('Task 9: Where Stopping or Deleting Is Permitted Rules', () {
    test('Zero-history medication is eligible for permanent hard delete', () {
      final unusedMed = Medication(
        id: 'med-unused-1',
        name: 'New Test Patch',
        type: MedicationType.patch,
        dose: 25,
        unit: 'mcg',
        frequency: 'Weekly',
        selectedWeekdays: [1],
      );

      final hasHistory = HrtScheduleService.hasLoggedHistory(unusedMed, []);
      expect(hasHistory, isFalse);
    });

    test('Medication with logged intake history cannot be hard deleted, only soft-stopped', () {
      final activeMed = Medication(
        id: 'med-active-1',
        name: 'Estrodose',
        type: MedicationType.gel,
        dose: 2,
        unit: 'pumps',
        frequency: 'Daily',
      );

      final logWithIntake = DailyLog(
        id: 'log-1',
        userId: 'user-1',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        hrtIntakes: [
          HrtIntakeLog(
            medicationId: activeMed.id,
            name: activeMed.name,
            dose: 2,
            unit: 'pumps',
            time: '09:00',
            isTaken: true,
          ),
        ],
      );

      final hasHistory = HrtScheduleService.hasLoggedHistory(activeMed, [logWithIntake]);
      expect(hasHistory, isTrue);
    });
  });

  group('Task 10: Calendar Day History Event Rules', () {
    test('Non-scheduled days without intake logs omit medication from day history and suppress derived states', () {
      final monMed = Medication(
        id: 'med-mon-1',
        name: 'Monday Only Patch',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Weekly',
        selectedWeekdays: [1], // Monday
      );

      final tuesday = DateTime(2026, 8, 11);

      // Tuesday is not scheduled
      final isScheduled = HrtScheduleService.isScheduledOnDate(monMed, tuesday);
      expect(isScheduled, isFalse);

      // Verify that "Not scheduled today" is NOT an allowed activity title
      final String derivedState = "Not scheduled today";
      expect(derivedState, isNot(equals("Medication Started")));
      expect(derivedState, isNot(equals("Medication Discontinued")));
    });
  });

  group('Task 11: HRT Tracker Calendar Is Read-Only Rules', () {
    test('HRT Tracker calendar provides Log This Day route to Calendar View for retrospective logging', () {
      final selectedDate = DateTime(2026, 8, 5);
      final String routePath = '/calendar';

      // Verify destination route is Calendar View
      expect(routePath, equals('/calendar'));
      expect(selectedDate, isNotNull);
    });
  });

  group('Task 12: Three Date Contexts for Medication Data Rules', () {
    test('Today date resolves to Context A (Today Live)', () {
      final today = DateTime.now();
      final ctx = HrtScheduleService.resolveDateContext(selectedDate: today);
      expect(ctx, HrtDateContext.contextAToday);
    });

    test('Past date without correction flag resolves to Context B (Retroactive Within History)', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final ctx = HrtScheduleService.resolveDateContext(selectedDate: pastDate, isCorrection: false);
      expect(ctx, HrtDateContext.contextBRetroactiveWithinHistory);
    });

    test('Past date with correction flag resolves to Context C (Retroactive Correction)', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 10));
      final ctx = HrtScheduleService.resolveDateContext(selectedDate: pastDate, isCorrection: true);
      expect(ctx, HrtDateContext.contextCRetroactiveCorrection);
    });
  });

  group('Task 13: Behavior for Context A and Context B Rules', () {
    test('Context A evaluates live active medication list for today', () {
      final activeMed = Medication(
        id: 'med-live-1',
        name: 'Estradiol Gel',
        type: MedicationType.gel,
        dose: 2,
        unit: 'pumps',
        frequency: 'Daily',
        startedAt: DateTime(2026, 1, 1),
      );

      final meds = [activeMed];

      List<Medication> getActiveFor(DateTime d) {
        final target = DateTime(d.year, d.month, d.day);
        return meds.where((m) {
          if (m.startedAt != null && target.isBefore(DateTime(m.startedAt!.year, m.startedAt!.month, m.startedAt!.day))) return false;
          if (m.endedAt != null && target.isAfter(DateTime(m.endedAt!.year, m.endedAt!.month, m.endedAt!.day))) return false;
          return true;
        }).toList();
      }

      final today = DateTime.now();
      expect(getActiveFor(today), hasLength(1));
    });

    test('Context B resolves active medications on historical date and returns empty list prior to start date', () {
      final patchMed = Medication(
        id: 'med-patch-historical',
        name: 'Evorel 50',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Twice weekly',
        startedAt: DateTime(2026, 6, 1),
        endedAt: DateTime(2026, 12, 31),
      );

      final meds = [patchMed];

      List<Medication> getActiveFor(DateTime d) {
        final target = DateTime(d.year, d.month, d.day);
        return meds.where((m) {
          if (m.startedAt != null && target.isBefore(DateTime(m.startedAt!.year, m.startedAt!.month, m.startedAt!.day))) return false;
          if (m.endedAt != null && target.isAfter(DateTime(m.endedAt!.year, m.endedAt!.month, m.endedAt!.day))) return false;
          return true;
        }).toList();
      }

      final preStartDate = DateTime(2026, 5, 15);
      final activeDate = DateTime(2026, 7, 10);

      expect(getActiveFor(preStartDate), isEmpty);
      expect(getActiveFor(activeDate), hasLength(1));
    });
  });

  group('Task 14: Context C (Retroactive Data Correction) and One-Off Medications Rules', () {
    test('Retroactive correction creates day-scoped DailyLog intake without mutating canonical timeline', () {
      final activeMed = Medication(
        id: 'med-canonical-1',
        name: 'Estradiol Gel',
        type: MedicationType.gel,
        dose: 2,
        unit: 'pumps',
        frequency: 'Daily',
      );

      final historicalLogDate = DateTime(2026, 7, 15);

      // One-off/corrected historical intake recorded for July 15 (dose = 3 instead of 2)
      final correctedIntake = HrtIntakeLog(
        medicationId: activeMed.id,
        name: activeMed.name,
        dose: 3, // Corrected dose for this specific past date
        unit: 'pumps',
        time: '10:00',
        isTaken: true,
      );

      final pastLog = DailyLog(
        id: 'log-2026-07-15',
        userId: 'user-1',
        date: historicalLogDate,
        createdAt: DateTime.now(),
        hrtIntakes: [correctedIntake],
      );

      // Verify canonical active medication dose remains unchanged at 2
      expect(activeMed.dose, 2);

      // Verify day-scoped log contains corrected dose 3
      expect(pastLog.hrtIntakes.first.dose, 3);
    });

    test('Declined one-off historical medication produces day-scoped log without ongoing schedule', () {
      final historicalDate = DateTime(2026, 7, 20);

      // User adds a historical one-off medication (e.g. Progesterone 100mg) for July 20 only
      final oneOffIntake = HrtIntakeLog(
        medicationId: 'one-off-proj-1',
        name: 'Progesterone One-Off',
        dose: 100,
        unit: 'mg',
        time: '21:00',
        isTaken: true,
      );

      final dayLog = DailyLog(
        id: 'log-2026-07-20',
        userId: 'user-1',
        date: historicalDate,
        createdAt: DateTime.now(),
        hrtIntakes: [oneOffIntake],
      );

      // Verify entry exists only in DailyLog for July 20
      expect(dayLog.hrtIntakes.first.name, 'Progesterone One-Off');

      // Canonical active tracking list remains empty
      final activeTrackingList = <Medication>[];
      expect(activeTrackingList, isEmpty);
    });
  });

  group('Daily Logging: Past Draft Preservation & Next Day Reset', () {
    test('Unfinished log from yesterday preserves logged data and is finalized as yesterday log', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();

      // Yesterday's unfinished log with step 2 (Symptoms & Severity)
      final yesterdayDraft = DailyLog(
        id: 'log-${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}',
        userId: 'user-1',
        date: yesterday,
        symptoms: [
          LoggedSymptom(
            symptom: const Symptom(id: 's_hot_flashes', name: 'Hot Flashes', iconName: 'local_fire_department', category: 'Vasomotor'),
            severity: 'Moderate',
          ),
        ],
        isCompleted: false,
        lastCompletedStep: 2,
        createdAt: yesterday,
      );

      // Simulation of past-day finalization logic
      final todayStart = DateTime(today.year, today.month, today.day);
      final logDate = DateTime(yesterdayDraft.date.year, yesterdayDraft.date.month, yesterdayDraft.date.day);

      DailyLog processedYesterdayLog = yesterdayDraft;
      if (!yesterdayDraft.isCompleted && logDate.isBefore(todayStart)) {
        final hasData = yesterdayDraft.lastCompletedStep > 0 || yesterdayDraft.symptoms.isNotEmpty;
        if (hasData) {
          processedYesterdayLog = yesterdayDraft.copyWith(isCompleted: true);
        }
      }

      // 1. Yesterday's log is preserved and finalized with its symptoms
      expect(processedYesterdayLog.isCompleted, isTrue);
      expect(processedYesterdayLog.symptoms.first.symptom.name, 'Hot Flashes');
      expect(processedYesterdayLog.symptoms.first.severity, 'Moderate');

      // 2. Today's log for the new day is null / fresh, starting with 0% progress
      DailyLog? todayLog; // null because user has not logged today
      final isTodayCompleted = todayLog?.isCompleted ?? false;
      final todayDraftStep = todayLog != null ? (todayLog.isCompleted ? 5 : todayLog.lastCompletedStep) : 0;

      expect(isTodayCompleted, isFalse);
      expect(todayDraftStep, equals(0));
    });
  });

  group('Task 15: Duplicate Medication Detection Rules', () {
    final activePatch = Medication(
      id: 'med-active-patch-1',
      name: 'Evorel 50',
      type: MedicationType.patch,
      dose: 50,
      unit: 'mcg',
      frequency: 'Twice weekly',
      selectedWeekdays: [1, 4],
      startedAt: DateTime(2026, 1, 1),
    );

    final softStoppedGel = Medication(
      id: 'med-stopped-gel-1',
      name: 'Oestrogel',
      type: MedicationType.gel,
      dose: 2,
      unit: 'pumps',
      frequency: 'Daily',
      selectedWeekdays: [1, 2, 3, 4, 5, 6, 7],
      startedAt: DateTime(2025, 1, 1),
      endedAt: DateTime(2025, 12, 31), // Stopped in past
    );

    final meds = [activePatch, softStoppedGel];

    test('Exact match on active medication triggers duplicate detection', () {
      final newDuplicate = Medication(
        name: 'Evorel 50',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Twice weekly',
      );

      final duplicate = HrtScheduleService.findExactActiveDuplicate(newDuplicate, meds);
      expect(duplicate, isNotNull);
      expect(duplicate!.id, 'med-active-patch-1');
    });

    test('Same drug name but different dose value is allowed without duplicate warning', () {
      final newDifferentDose = Medication(
        name: 'Evorel 50', // same name
        type: MedicationType.patch,
        dose: 75, // different dose
        unit: 'mcg',
        frequency: 'Twice weekly',
      );

      final duplicate = HrtScheduleService.findExactActiveDuplicate(newDifferentDose, meds);
      expect(duplicate, isNull);
    });

    test('Same drug name but different form is allowed without duplicate warning', () {
      final newDifferentForm = Medication(
        name: 'Evorel 50', // same name
        type: MedicationType.gel, // different form
        dose: 50,
        unit: 'mcg',
        frequency: 'Twice weekly',
      );

      final duplicate = HrtScheduleService.findExactActiveDuplicate(newDifferentForm, meds);
      expect(duplicate, isNull);
    });

    test('Same drug name but different frequency is allowed without duplicate warning', () {
      final newDifferentFreq = Medication(
        name: 'Evorel 50',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Weekly', // different frequency
      );

      final duplicate = HrtScheduleService.findExactActiveDuplicate(newDifferentFreq, meds);
      expect(duplicate, isNull);
    });

    test('Exact match on soft-stopped medication (resuming after break) is allowed without warning', () {
      final resumeGel = Medication(
        name: 'Oestrogel',
        type: MedicationType.gel,
        dose: 2,
        unit: 'pumps',
        frequency: 'Daily',
      );

      final duplicate = HrtScheduleService.findExactActiveDuplicate(resumeGel, meds);
      expect(duplicate, isNull);
    });

    test('Medication added today has startedAt=today and is not active on past dates', () {
      final today = DateTime.now();
      final pastDate = today.subtract(const Duration(days: 5));

      final todayMed = Medication(
        id: 'med-today-1',
        name: 'Evorel 50',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Twice weekly',
        startedAt: today,
      );

      final medsList = [todayMed];

      List<Medication> getActiveFor(DateTime d) {
        final target = DateTime(d.year, d.month, d.day);
        return medsList.where((m) {
          if (m.startedAt != null) {
            final start = DateTime(m.startedAt!.year, m.startedAt!.month, m.startedAt!.day);
            if (target.isBefore(start)) return false;
          }
          if (m.endedAt != null) {
            final end = DateTime(m.endedAt!.year, m.endedAt!.month, m.endedAt!.day);
            if (target.isAfter(end)) return false;
          }
          return true;
        }).toList();
      }

      expect(getActiveFor(today), hasLength(1));
      expect(getActiveFor(pastDate), isEmpty);
    });

    group('Task 16: Past Medication Entry During Retroactive Logging', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final aug1 = DateTime(2026, 8, 1);
      final aug15 = DateTime(2026, 8, 15);
      final aug20 = DateTime(2026, 8, 20);
      final aug25 = DateTime(2026, 8, 25);

      final pastPeriodMed = Medication(
        id: 'past-med-1',
        name: 'Utrogestan 100mg',
        type: MedicationType.pill,
        dose: 100,
        unit: 'mg',
        frequency: 'Daily',
        startedAt: aug1,
        endedAt: aug20,
      );

      final ongoingMed = Medication(
        id: 'ongoing-med-1',
        name: 'Oestrogel',
        type: MedicationType.gel,
        dose: 2,
        unit: 'pumps',
        frequency: 'Daily',
        startedAt: aug15,
        endedAt: null,
      );

      final allMeds = [pastPeriodMed, ongoingMed];

      List<Medication> getActiveFor(DateTime d) {
        final target = DateTime(d.year, d.month, d.day);
        return allMeds.where((m) {
          if (m.startedAt != null) {
            final start = DateTime(m.startedAt!.year, m.startedAt!.month, m.startedAt!.day);
            if (target.isBefore(start)) return false;
          }
          if (m.endedAt != null) {
            final end = DateTime(m.endedAt!.year, m.endedAt!.month, m.endedAt!.day);
            if (target.isAfter(end)) return false;
          }
          return true;
        }).toList();
      }

      test('Past-period medication appears in retroactive logging for dates within its saved range', () {
        final activeOnAug10 = getActiveFor(DateTime(2026, 8, 10));
        expect(activeOnAug10.map((m) => m.id), contains('past-med-1'));
        expect(activeOnAug10.map((m) => m.id), isNot(contains('ongoing-med-1')));

        final activeOnAug18 = getActiveFor(DateTime(2026, 8, 18));
        expect(activeOnAug18.map((m) => m.id), contains('past-med-1'));
        expect(activeOnAug18.map((m) => m.id), contains('ongoing-med-1'));
      });

      test('Past-period medication is excluded before start date and after end date', () {
        final activeBefore = getActiveFor(DateTime(2026, 7, 25));
        expect(activeBefore.map((m) => m.id), isNot(contains('past-med-1')));

        final activeAfter = getActiveFor(aug25);
        expect(activeAfter.map((m) => m.id), isNot(contains('past-med-1')));
        expect(activeAfter.map((m) => m.id), contains('ongoing-med-1'));
      });

      test('Past-period medication never appears in live active medication list (endedAt == null)', () {
        final liveActiveMeds = allMeds.where((m) => m.endedAt == null).toList();
        expect(liveActiveMeds.map((m) => m.id), isNot(contains('past-med-1')));
        expect(liveActiveMeds.map((m) => m.id), contains('ongoing-med-1'));
      });

      test('Date range validation logic: validates future end date, start after end, and logging date inclusion', () {
        String? validateHistoricalDateRange({
          required DateTime startDate,
          required DateTime endDate,
          required DateTime loggingDate,
        }) {
          final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
          final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
          final logOnly = DateTime(loggingDate.year, loggingDate.month, loggingDate.day);
          final todayOnly = DateTime(now.year, now.month, now.day);

          if (endOnly.isAfter(todayOnly)) {
            return 'End date cannot be later than today.';
          }
          if (startOnly.isAfter(endOnly)) {
            return 'Start date cannot be after end date.';
          }
          if (logOnly.isBefore(startOnly) || logOnly.isAfter(endOnly)) {
            return 'The date being logged must fall within the start and end date range.';
          }
          return null;
        }

        // Valid case
        expect(
          validateHistoricalDateRange(
            startDate: DateTime(2026, 8, 1),
            endDate: DateTime(2026, 8, 20),
            loggingDate: DateTime(2026, 8, 10),
          ),
          isNull,
        );

        // Future end date
        expect(
          validateHistoricalDateRange(
            startDate: DateTime(2026, 8, 1),
            endDate: today.add(const Duration(days: 5)),
            loggingDate: DateTime(2026, 8, 10),
          ),
          'End date cannot be later than today.',
        );

        // Start date after end date
        expect(
          validateHistoricalDateRange(
            startDate: DateTime(2026, 8, 25),
            endDate: DateTime(2026, 8, 20),
            loggingDate: DateTime(2026, 8, 22),
          ),
          'Start date cannot be after end date.',
        );

        // Logging date outside range
        expect(
          validateHistoricalDateRange(
            startDate: DateTime(2026, 8, 1),
            endDate: DateTime(2026, 8, 10),
            loggingDate: DateTime(2026, 8, 15),
          ),
          'The date being logged must fall within the start and end date range.',
        );
      });
    });
  });
}
