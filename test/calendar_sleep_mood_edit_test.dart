import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/home/presentation/pages/calendar_page.dart';
import 'package:eunora/features/home/presentation/widgets/edit_sleep_modal_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/edit_mood_modal_sheet.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';

class MockMedicationsNotifier extends Medications {
  @override
  MedicationsState build() => MedicationsState(medications: []);
}

void main() {
  group('Calendar Sleep and Mood Editing Tests', () {
    testWidgets('EditSleepModalSheet parses initial values and returns updated sleep on save', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      double? savedDuration;
      int? savedQuality;
      String? savedFormatted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => EditSleepModalSheet(
                    initialSleepInfo: '6 hours · quality 2/5',
                    initialDuration: 6.0,
                    selectedDate: DateTime(2026, 4, 10),
                    onSave: (duration, quality, formatted) {
                      savedDuration = duration;
                      savedQuality = quality;
                      savedFormatted = formatted;
                    },
                  ),
                ),
                child: const Text('Open Sleep Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sleep Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Sleep'), findsOneWidget);
      expect(find.text('SLEEP DURATION'), findsOneWidget);
      expect(find.text('SLEEP QUALITY'), findsOneWidget);

      // Tap 8h preset
      await tester.tap(find.text('8h'));
      await tester.pumpAndSettle();

      // Tap 'Good' quality option
      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save Sleep'));
      await tester.pumpAndSettle();

      expect(savedDuration, equals(8.0));
      expect(savedQuality, equals(4));
      expect(savedFormatted, equals('8 hours · quality 4/5'));
    });

    testWidgets('EditMoodModalSheet parses initial values and returns updated mood on save', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? savedMood;
      int? savedScore;
      String? savedFormatted;
      String? savedStress;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => EditMoodModalSheet(
                    initialMoodInfo: 'Okay · 3/5',
                    initialStressLevel: 'Moderate',
                    selectedDate: DateTime(2026, 4, 10),
                    onSave: (mood, score, formatted, stress) {
                      savedMood = mood;
                      savedScore = score;
                      savedFormatted = formatted;
                      savedStress = stress;
                    },
                  ),
                ),
                child: const Text('Open Mood Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Mood Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Mood & Well-being'), findsOneWidget);
      expect(find.text('Great'), findsOneWidget);
      expect(find.text('Anxious'), findsOneWidget);

      // Select 'Great' mood
      await tester.tap(find.text('Great'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save Mood'));
      await tester.pumpAndSettle();

      expect(savedMood, equals('Great'));
      expect(savedScore, equals(5));
      expect(savedFormatted, equals('Great · 5/5'));
      expect(savedStress, equals('Calm'));
    });

    testWidgets('CalendarPage opens EditSleepModalSheet when Sleep row is tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicationsProvider.overrideWith(() => MockMedicationsNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CalendarPage(
                initialSelectedDate: DateTime(2026, 4, 7),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure Symptoms / Sleep card is visible
      final sleepFinder = find.text('Sleep');
      expect(sleepFinder, findsWidgets);

      await tester.ensureVisible(sleepFinder.first);
      await tester.pumpAndSettle();

      // Tap the Sleep row
      await tester.tap(sleepFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(EditSleepModalSheet), findsOneWidget);
      expect(find.text('Save Sleep'), findsOneWidget);
    });

    testWidgets('CalendarPage opens EditMoodModalSheet when Mood row is tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicationsProvider.overrideWith(() => MockMedicationsNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CalendarPage(
                initialSelectedDate: DateTime(2026, 4, 7),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure Symptoms / Mood card is visible
      final moodFinder = find.text('Mood');
      expect(moodFinder, findsWidgets);

      await tester.ensureVisible(moodFinder.first);
      await tester.pumpAndSettle();

      // Tap the Mood row
      await tester.tap(moodFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(EditMoodModalSheet), findsOneWidget);
      expect(find.text('Save Mood'), findsOneWidget);
    });
  });
}
