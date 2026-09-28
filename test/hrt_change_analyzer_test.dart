import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/analysis/analysis.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';

void main() {
  const analyzer = HrtChangeAnalyzer();

  DailyLog createLog({
    required DateTime date,
    bool isCompleted = true,
    List<LoggedSymptom> symptoms = const [],
    List<HrtIntakeLog> hrtIntakes = const [],
  }) {
    return DailyLog(
      id: date.toIso8601String().substring(0, 10),
      userId: 'test_user',
      date: date,
      isCompleted: isCompleted,
      symptoms: symptoms,
      hrtIntakes: hrtIntakes,
      createdAt: date,
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

  group('Countdown & Elapsed Days', () {
    test('countdown equals 14 minus elapsed calendar days; never a constant 14', () {
      // Change made on Sep 13. Checked on Sep 19 (6 days elapsed -> 8 days to go)
      final changeDate = DateTime(2026, 9, 13);
      final checkDate = DateTime(2026, 9, 19);

      final change = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_1',
        medicationName: 'Estradiol patch',
        oldDose: 50,
        newDose: 75,
        unit: 'mcg',
        changeDate: changeDate,
      );

      // Provide 10 logged days in Before window (Sep 13 - 14 days = Aug 30 to Sep 12)
      final logs = List.generate(10, (i) {
        return createLog(
          date: DateTime(2026, 9, 2 + i),
          isCompleted: true,
        );
      });

      final result = analyzer.analyze(
        doseChanges: [change],
        medications: [],
        logs: logs,
        today: checkDate,
      );

      expect(result.groups.length, 1);
      final group = result.groups.first;
      expect(group.status, HrtChangeStatus.pending);
      expect(group.daysSinceChange, 6);
      expect(group.daysToGo, 8); // 14 - 6 = 8
      expect(group.statusMessage, 'Keep logging — 8 days to go until your before/after comparison.');
    });
  });

  group('Status Evaluation Hierarchy (Strict Order)', () {
    test('1. notEnoughBaseline checked first when < 7 logged days before change', () {
      final changeDate = DateTime(2026, 9, 13);
      final checkDate = DateTime(2026, 9, 16); // Only 3 days elapsed

      final change = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_1',
        medicationName: 'Estradiol',
        oldDose: 1.0,
        newDose: 2.0,
        unit: 'mg',
        changeDate: changeDate,
      );

      // Only 3 logged days in the Before window
      final logs = [
        createLog(date: DateTime(2026, 9, 10)),
        createLog(date: DateTime(2026, 9, 11)),
        createLog(date: DateTime(2026, 9, 12)),
      ];

      final result = analyzer.analyze(
        doseChanges: [change],
        medications: [],
        logs: logs,
        today: checkDate,
      );

      final group = result.groups.first;
      // Even though elapsed days < 14, notEnoughBaseline takes precedence!
      expect(group.status, HrtChangeStatus.notEnoughBaseline);
      expect(group.daysToGo, isNull); // No countdown
      expect(group.statusMessage, 'Not enough history before this change to compare');
    });

    test('2. pending when before >= 7 but elapsed < 14', () {
      final changeDate = DateTime(2026, 9, 13);
      final checkDate = DateTime(2026, 9, 20); // 7 days elapsed

      final change = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_1',
        medicationName: 'Estradiol',
        oldDose: 1.0,
        newDose: 2.0,
        unit: 'mg',
        changeDate: changeDate,
      );

      // 8 logged days before
      final logs = List.generate(8, (i) => createLog(date: DateTime(2026, 9, 1 + i)));

      final result = analyzer.analyze(
        doseChanges: [change],
        medications: [],
        logs: logs,
        today: checkDate,
      );

      final group = result.groups.first;
      expect(group.status, HrtChangeStatus.pending);
      expect(group.daysSinceChange, 7);
      expect(group.daysToGo, 7);
      expect(group.statusMessage, 'Keep logging — 7 days to go until your before/after comparison.');
    });

    test('3. notEnoughFollowUp when elapsed >= 14 but < 7 logged days after', () {
      final changeDate = DateTime(2026, 9, 1);
      final checkDate = DateTime(2026, 9, 20); // 19 days elapsed (>= 14)

      final change = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_1',
        medicationName: 'Estradiol',
        oldDose: 1.0,
        newDose: 2.0,
        unit: 'mg',
        changeDate: changeDate,
      );

      // 8 logged days before (Aug 20 to Aug 27)
      final beforeLogs = List.generate(8, (i) => createLog(date: DateTime(2026, 8, 20 + i)));
      // Only 4 logged days after (Sep 2 to Sep 5)
      final afterLogs = List.generate(4, (i) => createLog(date: DateTime(2026, 9, 2 + i)));

      final result = analyzer.analyze(
        doseChanges: [change],
        medications: [],
        logs: [...beforeLogs, ...afterLogs],
        today: checkDate,
      );

      final group = result.groups.first;
      expect(group.status, HrtChangeStatus.notEnoughFollowUp);
      expect(group.statusMessage, 'Not enough logs after this change to compare.');
    });

    test('4. ready when elapsed >= 14 and >= 7 logged days in both windows', () {
      final changeDate = DateTime(2026, 9, 1);
      final checkDate = DateTime(2026, 9, 20); // 19 days elapsed

      final change = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_1',
        medicationName: 'Estradiol',
        oldDose: 1.0,
        newDose: 2.0,
        unit: 'mg',
        changeDate: changeDate,
      );

      // 10 logged days before
      final beforeLogs = List.generate(10, (i) {
        return createLog(
          date: DateTime(2026, 8, 20 + i),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Severe')],
        );
      });

      // 10 logged days after
      final afterLogs = List.generate(10, (i) {
        return createLog(
          date: DateTime(2026, 9, 2 + i),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Mild')],
        );
      });

      final result = analyzer.analyze(
        doseChanges: [change],
        medications: [],
        logs: [...beforeLogs, ...afterLogs],
        today: checkDate,
      );

      final group = result.groups.first;
      expect(group.status, HrtChangeStatus.ready);
      expect(group.isReady, isTrue);
      expect(group.beforeWindowLoggedDays, 10);
      expect(group.afterWindowLoggedDays, 10);
    });
  });

  group('Events, Missing Medications & Schedule Exclusions', () {
    test('deleted/missing medication is still analyzed by date using stored name', () {
      final changeDate = DateTime(2026, 9, 1);
      final change = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'deleted_med_123',
        medicationName: 'Old Progesterone',
        oldDose: 100,
        newDose: 200,
        unit: 'mg',
        changeDate: changeDate,
      );

      final result = analyzer.analyze(
        doseChanges: [change],
        medications: [], // No matching medication in active medications!
        logs: [],
        today: DateTime(2026, 9, 5),
      );

      expect(result.groups.length, 1);
      final event = result.groups.first.events.first;
      expect(event.medicationName, 'Old Progesterone');
      expect(event.eventType, HrtRegimenEventType.doseIncreased);
    });

    test('weekday-only changes (scheduleDayChange) are ignored as administrative', () {
      final change = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_1',
        medicationName: 'Estradiol patch',
        oldDose: 50,
        newDose: 50,
        unit: 'mcg',
        changeDate: DateTime(2026, 9, 10),
        changeType: RegimenChangeType.scheduleDayChange,
      );

      final result = analyzer.analyze(
        doseChanges: [change],
        medications: [],
        logs: [],
        today: DateTime(2026, 9, 15),
      );

      expect(result.groups, isEmpty);
    });

    test('medication starts and stops produce events; first start is startedHrt', () {
      final med1 = Medication(
        id: 'med_1',
        name: 'Estradiol gel',
        type: MedicationType.gel,
        dose: 1.5,
        unit: 'mg',
        frequency: 'Daily',
        startedAt: DateTime(2026, 8, 1),
      );

      final med2 = Medication(
        id: 'med_2',
        name: 'Utrogestan',
        type: MedicationType.pill,
        dose: 100,
        unit: 'mg',
        frequency: 'Daily',
        startedAt: DateTime(2026, 8, 15),
        endedAt: DateTime(2026, 9, 1),
      );

      final result = analyzer.analyze(
        doseChanges: [],
        medications: [med1, med2],
        logs: [],
        today: DateTime(2026, 9, 5),
      );

      // Groups for Aug 1 (med1 start), Aug 15 (med2 start), Sep 1 (med2 stop)
      expect(result.groups.length, 3);

      final aug1Group = result.groups.firstWhere((g) => g.changeDate == DateTime(2026, 8, 1));
      expect(aug1Group.events.first.eventType, HrtRegimenEventType.startedHrt);

      final aug15Group = result.groups.firstWhere((g) => g.changeDate == DateTime(2026, 8, 15));
      expect(aug15Group.events.first.eventType, HrtRegimenEventType.medicationStarted);

      final sep1Group = result.groups.firstWhere((g) => g.changeDate == DateTime(2026, 9, 1));
      expect(sep1Group.events.first.eventType, HrtRegimenEventType.medicationStopped);
    });
  });

  group('Same-Day Grouping & Overlapping Warning Notes', () {
    test('same-day events form one group', () {
      final changeDate = DateTime(2026, 9, 10);
      final change1 = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_1',
        medicationName: 'Estradiol',
        oldDose: 50,
        newDose: 75,
        unit: 'mcg',
        changeDate: changeDate,
      );
      final change2 = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_2',
        medicationName: 'Progesterone',
        oldDose: 100,
        newDose: 200,
        unit: 'mg',
        changeDate: changeDate,
      );

      final result = analyzer.analyze(
        doseChanges: [change1, change2],
        medications: [],
        logs: [],
        today: DateTime(2026, 9, 12),
      );

      expect(result.groups.length, 1);
      final group = result.groups.first;
      expect(group.events.length, 2);
      expect(group.summaryTitle, contains('Regimen changed on Sep 10:'));
    });

    test('another change within 14 days sets overlapping note', () {
      // Change 1 on Sep 1, Change 2 on Sep 6 (5 days apart)
      final change1 = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_1',
        medicationName: 'Estradiol',
        oldDose: 50,
        newDose: 75,
        unit: 'mcg',
        changeDate: DateTime(2026, 9, 1),
      );
      final change2 = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_2',
        medicationName: 'Progesterone',
        oldDose: 100,
        newDose: 200,
        unit: 'mg',
        changeDate: DateTime(2026, 9, 6),
      );

      final result = analyzer.analyze(
        doseChanges: [change1, change2],
        medications: [],
        logs: [],
        today: DateTime(2026, 9, 15),
      );

      expect(result.groups.length, 2);
      final groupSep1 = result.groups.firstWhere((g) => g.changeDate == DateTime(2026, 9, 1));
      expect(groupSep1.overlappingNotes, isNotEmpty);
      expect(groupSep1.overlappingNotes.first, contains('Another change on Sep 6 falls within this comparison — read with caution.'));

      final groupSep6 = result.groups.firstWhere((g) => g.changeDate == DateTime(2026, 9, 6));
      expect(groupSep6.overlappingNotes, isNotEmpty);
      expect(groupSep6.overlappingNotes.first, contains('Another change on Sep 1 falls within this comparison — read with caution.'));
    });
  });

  group('Per-Symptom SD-4 Math & Copy Templates', () {
    test('evaluates burden, frequency, and produces SD-4 direction wording', () {
      final changeDate = DateTime(2026, 9, 1);
      final checkDate = DateTime(2026, 9, 20);

      final change = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_1',
        medicationName: 'Estradiol',
        oldDose: 50,
        newDose: 100,
        unit: 'mcg',
        changeDate: changeDate,
      );

      // Before window (10 logged days): Hot flashes present on 8 days with Severe (5.0), duration 15 min
      final beforeLogs = List.generate(10, (i) {
        return createLog(
          date: DateTime(2026, 8, 20 + i),
          symptoms: i < 8
              ? [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Severe', durationMinutes: 15)]
              : [],
        );
      });

      // After window (10 logged days): Hot flashes present on 4 days with Mild (1.0), duration 5 min
      final afterLogs = List.generate(10, (i) {
        return createLog(
          date: DateTime(2026, 9, 2 + i),
          symptoms: i < 4
              ? [createSymptom(id: 'hot_flash', name: 'Hot flashes', severity: 'Mild', durationMinutes: 5)]
              : [],
        );
      });

      final result = analyzer.analyze(
        doseChanges: [change],
        medications: [],
        logs: [...beforeLogs, ...afterLogs],
        today: checkDate,
      );

      final group = result.groups.first;
      expect(group.status, HrtChangeStatus.ready);
      expect(group.symptomResults, isNotEmpty);

      final hf = group.symptomResults.firstWhere((s) => s.symptomId == 'hot_flash');
      // Frequency before: 8 / 10 = 0.8
      expect(hf.daysPresentBefore, 8);
      expect(hf.frequencyBefore, 0.8);
      // Frequency after: 4 / 10 = 0.4
      expect(hf.daysPresentAfter, 4);
      expect(hf.frequencyAfter, 0.4);

      // Burden before: 8 * 5.0 / 10 = 4.0
      expect(hf.burdenBefore, 4.0);
      // Burden after: 4 * 1.0 / 10 = 0.4
      expect(hf.burdenAfter, 0.4);

      // Duration
      expect(hf.averageDurationMinutesBefore, 15.0);
      expect(hf.averageDurationMinutesAfter, 5.0);

      // Direction wording
      expect(hf.directionWording, 'milder');
      expect(hf.comparison.changeType, MaterialChangeType.improved);

      // Headline
      expect(group.headlineText, contains('Since your Estradiol dose increased 19 days ago, Hot flashes was logged on 8 of 10 days before and 4 of 10 days after'));
      expect(group.summaryCountsText, '1 improved · 0 steady · 0 worsened');

      // Verbatim Section E2 disclaimer
      expect(group.disclaimer, equals(kApprovedHrtDisclaimer));
    });
  });

  group('Adherence Calculation', () {
    test('counts scheduled doses only; shows gentle note when adherence < 70%', () {
      final changeDate = DateTime(2026, 9, 1);
      final checkDate = DateTime(2026, 9, 20);

      final change = HrtDoseChange(
        userId: 'test_user',
        medicationId: 'med_1',
        medicationName: 'Estradiol pill',
        oldDose: 1,
        newDose: 2,
        unit: 'mg',
        changeDate: changeDate,
      );

      final med = Medication(
        id: 'med_1',
        name: 'Estradiol pill',
        type: MedicationType.pill,
        dose: 2,
        unit: 'mg',
        frequency: 'Daily', // 1 dose per day
      );

      // 10 logged days before
      final beforeLogs = List.generate(10, (i) => createLog(date: DateTime(2026, 8, 20 + i)));

      // 14 calendar days after (Sep 2 to Sep 15) -> 14 scheduled doses.
      // User only logged intakes on 6 days! (6 / 14 = 43% < 70%)
      final afterLogs = List.generate(14, (i) {
        final date = DateTime(2026, 9, 2 + i);
        final tookMed = i < 6;
        return createLog(
          date: date,
          hrtIntakes: tookMed
              ? [HrtIntakeLog(medicationId: 'med_1', name: 'Estradiol pill', dose: 2, unit: 'mg', time: '08:00', isTaken: true)]
              : [],
        );
      });

      final result = analyzer.analyze(
        doseChanges: [change],
        medications: [med],
        logs: [...beforeLogs, ...afterLogs],
        today: checkDate,
      );

      final group = result.groups.first;
      expect(group.adherence, isNotNull);
      final adh = group.adherence!;
      expect(adh.scheduledDoses, 14);
      expect(adh.takenDoses, 6);
      expect(adh.adherencePercent, 43);
      expect(adh.adherenceText, 'You took 6 of 14 scheduled doses after this change.');
      expect(adh.needsGentleNote, isTrue);
      expect(adh.gentleNote, contains('Taking your medication consistently'));
    });
  });
}
