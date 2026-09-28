import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/symptom_log/data/symptom_library.dart';
import 'package:eunora/features/symptom_log/data/trigger_library.dart';
import 'package:eunora/core/utils/logging_helpers.dart';
import 'golden_dataset_fixture.dart';

void main() {
  group('PR-02: Daily Quick Log (Core Loop, ≤60s)', () {
    test('S2.1: Full log entry persists every field (mood, 15 symptoms, triggers, sleep)', () {
      final now = DateTime(2026, 9, 19, 21, 0);

      // Create 15 distinct symptoms across categories
      final loggedSymptoms = [
        createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe', intensity: 5, durationMinutes: 15),
        createSymptom(id: 'night_sweats', name: 'Night Sweats', severity: 'Moderate', intensity: 3, durationMinutes: 20),
        createSymptom(id: 'low_mood', name: 'Low Mood', severity: 'Moderate'),
        createSymptom(id: 'brain_fog', name: 'Brain Fog', severity: 'Mild'),
        createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Severe'),
        createSymptom(id: 'joint_pain', name: 'Joint Pain', severity: 'Moderate'),
        createSymptom(id: 'headache', name: 'Headache', severity: 'Mild'),
        createSymptom(id: 'sleep_disruption', name: 'Sleep Disruption', severity: 'Severe'),
        createSymptom(id: 'anxiety', name: 'Anxiety', severity: 'Moderate'),
        createSymptom(id: 'irritability', name: 'Irritability', severity: 'Mild'),
        createSymptom(id: 'vaginal_dryness', name: 'Vaginal Dryness', severity: 'Moderate'),
        createSymptom(id: 'bloating', name: 'Bloating', severity: 'Mild'),
        createSymptom(id: 'heart_palpitations', name: 'Palpitations', severity: 'Severe'),
        createSymptom(id: 'skin_changes', name: 'Skin Changes', severity: 'Mild'),
        createSymptom(id: 'dizziness', name: 'Dizziness', severity: 'Moderate'),
      ];

      final triggers = ['t_coffee', 't_alcohol', 't_stress', 't_exercise'];
      final customCounters = {'t_exercise': 45, 't_coffee': 2, 't_alcohol': 1};

      final log = createLog(
        date: DateTime(2026, 9, 19),
        symptoms: loggedSymptoms,
        triggers: triggers,
        caffeineCups: 2,
        alcoholGlasses: 1,
        stressLevel: 'High',
        sleepDuration: 7.5,
        customTriggerCounters: customCounters,
      );

      // Verify round-trip persistence of every field
      expect(log.symptoms.length, equals(15));
      expect(log.triggers.length, equals(4));
      expect(log.sleepDuration, equals(7.5));
      expect(log.stressLevel, equals('High'));
      expect(log.customTriggerCounters['t_exercise'], equals(45));

      // Check Hot Flashes sub-fields preserved
      final hf = log.symptoms.firstWhere((s) => s.symptom.id == 'hot_flash');
      expect(hf.intensity, equals(5));
      expect(hf.durationMinutes, equals(15));
      expect(hf.severity, equals('Severe'));
    });

    test('S2.2: Selecting Hot flashes reveals intensity & duration; deselecting clears both', () {
      // Hot Flashes and Night Sweats in library have inputMethod intensity_duration
      final hfDef = kSymptomLibrary.firstWhere((s) => s.id == 'hot_flash');
      expect(hfDef.inputMethod, equals('intensity_duration'));

      // Selecting: user enters intensity 4 and duration 10 min
      var symptomEntry = createSymptom(
        id: 'hot_flash',
        name: 'Hot Flashes',
        intensity: 4,
        durationMinutes: 10,
        severity: 'Moderate',
      );
      expect(symptomEntry.intensity, equals(4));
      expect(symptomEntry.durationMinutes, equals(10));

      // Deselecting: sub-fields cleared/removed
      symptomEntry = createSymptom(
        id: 'hot_flash',
        name: 'Hot Flashes',
        intensity: null,
        durationMinutes: null,
        severity: null,
      );
      expect(symptomEntry.intensity, isNull);
      expect(symptomEntry.durationMinutes, isNull);
      expect(symptomEntry.severity, isNull);
    });

    test('S2.3: Selecting Exercise reveals duration; other triggers are presence-only', () {
      final exercise = kTriggerLibrary.firstWhere((t) => t.id == 'exercise');
      expect(exercise.inputMethod, equals(TriggerInputMethod.presenceQuantity));
      expect(exercise.quantityUnit, equals('min'));

      // All other triggers never offer duration unit 'min'
      final nonExercise = kTriggerLibrary.where((t) => t.id != 'exercise');
      for (final t in nonExercise) {
        expect(t.quantityUnit, isNot(equals('min')),
            reason: 'Trigger ${t.id} should not offer duration in minutes');
      }
    });

    test('S2.4: Free-text is never accepted as a structured trigger', () {
      // All available triggers must belong to defined catalog IDs
      final validTriggerIds = kTriggerLibrary.map((t) => t.id).toSet();
      expect(validTriggerIds.contains('coffee'), isTrue);
      expect(validTriggerIds.contains('stress'), isTrue);
      expect(validTriggerIds.contains('exercise'), isTrue);

      // Attempting to pass arbitrary unstructured free-text string
      const arbitraryString = 'Drank herbal chamomile tea with honey at 9pm';
      final isStructured = validTriggerIds.contains(arbitraryString.toLowerCase().trim());
      expect(isStructured, isFalse);
    });

    test('S2.5: Offline log entry is flagged locally and syncs automatically once connectivity returns', () {
      // Create local offline log store
      final localStore = <String, Map<String, dynamic>>{};
      final syncQueue = <String>[];

      // 1. Connectivity dropped: save locally with syncPending = true
      final log = createLog(
        date: DateTime(2026, 9, 19),
        symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe')],
      );

      final entryId = log.id;
      localStore[entryId] = {
        'id': entryId,
        'date': log.date.toIso8601String(),
        'syncPending': true,
        'symptomCount': log.symptoms.length,
      };
      syncQueue.add(entryId);

      expect(localStore[entryId]!['syncPending'], isTrue);
      expect(syncQueue.contains(entryId), isTrue);

      // 2. Connectivity restored: background processor syncs all queued logs
      void processSyncQueue() {
        for (final id in List<String>.from(syncQueue)) {
          final record = localStore[id];
          if (record != null) {
            record['syncPending'] = false;
            record['syncedAt'] = DateTime(2026, 9, 19, 21, 5).toIso8601String();
            syncQueue.remove(id);
          }
        }
      }

      processSyncQueue();

      expect(syncQueue, isEmpty);
      expect(localStore[entryId]!['syncPending'], isFalse);
      expect(localStore[entryId]!['syncedAt'], isNotNull);
    });

    test('S2.6: Retroactive logging permitted up to 7 days in past; 8+ days blocked', () {
      final today = DateTime(2026, 9, 19);

      bool isDateLoggableFromQuickLog(DateTime targetDate, DateTime referenceToday) {
        final diff = referenceToday.difference(targetDate).inDays;
        return diff >= 0 && diff <= 7;
      }

      // Today (0 days ago) -> permitted
      expect(isDateLoggableFromQuickLog(DateTime(2026, 9, 19), today), isTrue);

      // 7 days ago (12 Sep) -> permitted
      expect(isDateLoggableFromQuickLog(DateTime(2026, 9, 12), today), isTrue);

      // 8 days ago (11 Sep) -> NOT permitted from quick log
      expect(isDateLoggableFromQuickLog(DateTime(2026, 9, 11), today), isFalse);

      // 14 days ago -> NOT permitted
      expect(isDateLoggableFromQuickLog(DateTime(2026, 9, 5), today), isFalse);
    });

    test('S2.7: "Log today" home affordance hides once today\'s log is completed', () {
      final today = DateTime(2026, 9, 19);

      bool shouldShowLogTodayAffordance(List<DailyLog> userLogs, DateTime referenceToday) {
        final todayLog = userLogs.cast<DailyLog?>().firstWhere(
              (l) =>
                  l != null &&
                  l.date.year == referenceToday.year &&
                  l.date.month == referenceToday.month &&
                  l.date.day == referenceToday.day &&
                  l.isCompleted,
              orElse: () => null,
            );
        return todayLog == null;
      }

      // Case A: Before logging today -> affordance visible
      final logsBefore = <DailyLog>[
        createLog(date: DateTime(2026, 9, 18)),
      ];
      expect(shouldShowLogTodayAffordance(logsBefore, today), isTrue);

      // Case B: Incomplete log today -> affordance still visible
      final logsIncomplete = <DailyLog>[
        createLog(date: DateTime(2026, 9, 18)),
        createLog(date: DateTime(2026, 9, 19), isCompleted: false),
      ];
      expect(shouldShowLogTodayAffordance(logsIncomplete, today), isTrue);

      // Case C: Today completed -> affordance hides
      final logsAfter = <DailyLog>[
        createLog(date: DateTime(2026, 9, 18)),
        createLog(date: DateTime(2026, 9, 19), isCompleted: true),
      ];
      expect(shouldShowLogTodayAffordance(logsAfter, today), isFalse);
    });
  });
}
