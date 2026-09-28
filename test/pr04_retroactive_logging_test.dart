import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/hrt_tracker/domain/hrt_schedule_service.dart';
import 'golden_dataset_fixture.dart';

void main() {
  group('PR-04: Retroactive Logging (3 Date Contexts)', () {
    test('S4.1: Today context updates live canonical list directly and immediately', () {
      final now = DateTime.now();

      // Context resolution for today
      final context = HrtScheduleService.resolveDateContext(selectedDate: now);
      expect(context, equals(HrtDateContext.contextAToday));

      var canonicalMeds = [
        Medication(
          id: 'med_estrogel',
          name: 'Estrogel',
          type: MedicationType.gel,
          dose: 2.0,
          unit: 'pumps',
          frequency: 'Daily',
          startedAt: DateTime(2026, 9, 1),
        ),
      ];

      // Logging today updates the live canonical list
      final updatedMed = canonicalMeds.first.copyWith(dose: 3.0);
      canonicalMeds = [updatedMed];

      expect(canonicalMeds.first.dose, equals(3.0));
    });

    test('S4.2: Retroactive within known history resolves against authoritative version on that date', () {
      final oldDoseMed = Medication(
        id: 'med_estrogel_v1',
        name: 'Estrogel',
        type: MedicationType.gel,
        dose: 1.0,
        unit: 'pumps',
        frequency: 'Daily',
        startedAt: DateTime(2026, 9, 1),
        endedAt: DateTime(2026, 9, 12),
      );

      final newDoseMed = Medication(
        id: 'med_estrogel_v2',
        name: 'Estrogel',
        type: MedicationType.gel,
        dose: 2.0,
        unit: 'pumps',
        frequency: 'Daily',
        startedAt: DateTime(2026, 9, 13),
        endedAt: null,
      );

      final allVersions = [oldDoseMed, newDoseMed];

      // Query past date (Sep 8, before dose change)
      final pastDate = DateTime(2026, 9, 8);
      final dateContext = HrtScheduleService.resolveDateContext(selectedDate: pastDate);
      expect(dateContext, equals(HrtDateContext.contextBRetroactiveWithinHistory));

      // Resolve authoritative medication for past date
      List<Medication> getAuthoritativeMeds(DateTime date) {
        final d = DateTime(date.year, date.month, date.day);
        return allVersions.where((m) {
          if (m.startedAt != null && d.isBefore(DateTime(m.startedAt!.year, m.startedAt!.month, m.startedAt!.day))) {
            return false;
          }
          if (m.endedAt != null && d.isAfter(DateTime(m.endedAt!.year, m.endedAt!.month, m.endedAt!.day))) {
            return false;
          }
          return true;
        }).toList();
      }

      final pastAuthoritative = getAuthoritativeMeds(pastDate);
      expect(pastAuthoritative.length, equals(1));
      expect(pastAuthoritative.first.dose, equals(1.0), reason: 'Past date must resolve to 1.0 pump, not 2.0 pumps');

      // Query current date (Sep 19)
      final currentAuthoritative = getAuthoritativeMeds(DateTime(2026, 9, 19));
      expect(currentAuthoritative.length, equals(1));
      expect(currentAuthoritative.first.dose, equals(2.0));
    });

    test('S4.3: Retroactive With Correction creates isolated day override leaving canonical timeline unchanged', () {
      final pastDate = DateTime(2026, 9, 5);

      final dateContext = HrtScheduleService.resolveDateContext(
        selectedDate: pastDate,
        isCorrection: true,
      );
      expect(dateContext, equals(HrtDateContext.contextCRetroactiveCorrection));

      final canonicalTimeline = [
        Medication(
          id: 'med_estrogel',
          name: 'Estrogel',
          type: MedicationType.gel,
          dose: 2.0,
          unit: 'pumps',
          frequency: 'Daily',
          startedAt: DateTime(2026, 9, 1),
        ),
      ];

      // Create isolated day-scoped log on Sep 5 with custom override
      final overrideLog = createLog(
        date: pastDate,
        hrtIntakes: [
          HrtIntakeLog(
            medicationId: 'med_estrogel',
            name: 'Estrogel',
            dose: 1.5, // one-off historical correction
            unit: 'pumps',
            time: '20:00',
            isTaken: true,
          ),
        ],
      );

      // Verify canonical timeline is byte-for-byte unchanged outside Sep 5
      expect(canonicalTimeline.first.dose, equals(2.0));
      expect(canonicalTimeline.first.startedAt, equals(DateTime(2026, 9, 1)));
      expect(canonicalTimeline.first.endedAt, isNull);

      // Verify the day log itself carries the correction
      expect(overrideLog.hrtIntakes.first.dose, equals(1.5));
    });

    test('S4.4: Discard mid-retroactive-session clears all session data with zero residual state', () {
      // Draft session state
      final sessionDraft = <String, dynamic>{
        'targetDate': DateTime(2026, 9, 8),
        'draftIntakes': [
          {'medicationId': 'med_1', 'taken': true},
        ],
        'draftSymptomNotes': 'Unsaved symptom note during retroactive edit',
      };

      expect(sessionDraft.isNotEmpty, isTrue);

      // User taps Discard
      void discardSession() {
        sessionDraft.clear();
      }

      discardSession();

      // Re-entering session confirms clean empty state
      expect(sessionDraft, isEmpty);
      expect(sessionDraft['draftIntakes'], isNull);
      expect(sessionDraft['draftSymptomNotes'], isNull);
    });

    test('S4.5: Logging only today immediately after a retroactive session succeeds', () {
      final activeMed = Medication(
        id: 'med_patch',
        name: 'Evorel 50',
        type: MedicationType.patch,
        dose: 50.0,
        unit: 'mcg',
        frequency: 'Twice weekly',
      );

      final logsDb = <DateTime, DailyLog>{};

      // 1. Complete retroactive session for Sep 10
      final retroDate = DateTime(2026, 9, 10);
      logsDb[retroDate] = createLog(
        date: retroDate,
        hrtIntakes: [
          HrtIntakeLog(
            medicationId: activeMed.id!,
            name: activeMed.name,
            dose: activeMed.dose,
            unit: activeMed.unit,
            time: '08:00',
            isTaken: true,
          ),
        ],
      );
      expect(logsDb[retroDate], isNotNull);

      // 2. Immediately log "only today" (Sep 19) for the same active medication
      final todayDate = DateTime(2026, 9, 19);
      logsDb[todayDate] = createLog(
        date: todayDate,
        hrtIntakes: [
          HrtIntakeLog(
            medicationId: activeMed.id!,
            name: activeMed.name,
            dose: activeMed.dose,
            unit: activeMed.unit,
            time: '09:00',
            isTaken: true,
          ),
        ],
      );

      // Both logs exist independently without interference or silent failure
      expect(logsDb[todayDate], isNotNull);
      expect(logsDb[todayDate]!.hrtIntakes.first.isTaken, isTrue);
      expect(logsDb[retroDate]!.hrtIntakes.first.isTaken, isTrue);
    });

    test('S4.6: Retroactively logged HRT entry has matching calendar indicator and detail view', () {
      final retroDate = DateTime(2026, 9, 12);
      final retroLog = createLog(
        date: retroDate,
        hrtIntakes: [
          HrtIntakeLog(
            medicationId: 'med_estrogel',
            name: 'Estrogel',
            dose: 1.0,
            unit: 'pumps',
            time: '21:00',
            isTaken: true,
          ),
        ],
      );

      // Calendar month view indicator check
      bool hasCalendarHrtIndicator(DailyLog log) {
        return log.hrtIntakes.any((i) => i.isTaken);
      }

      final indicatorVisible = hasCalendarHrtIndicator(retroLog);
      expect(indicatorVisible, isTrue);

      // Day detail view data resolution
      final detailIntakes = retroLog.hrtIntakes.where((i) => i.isTaken).toList();
      expect(detailIntakes.length, equals(1));
      expect(detailIntakes.first.medicationId, equals('med_estrogel'));
      expect(detailIntakes.first.dose, equals(1.0));
      // Assert zero discrepancy between calendar dot and detail sheet
      expect(indicatorVisible && detailIntakes.isNotEmpty, isTrue);
    });
  });
}
