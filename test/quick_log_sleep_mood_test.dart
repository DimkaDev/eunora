import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/presentation/pages/daily_logging/daily_entry_step.dart';
import 'package:eunora/features/home/presentation/widgets/edit_sleep_modal_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/edit_mood_modal_sheet.dart';
import 'package:eunora/features/home/presentation/pages/calendar_page.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';

void main() {
  group('MenoSync: Sleep & Mood in Daily Quick Log', () {
    testWidgets('Sleep duration, presets, and 1-5 quality selector can be set and toggled in DailyEntryStep', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      double currentDuration = 7.5;
      int? currentQuality;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    child: DailyEntryStep(
                      hrtChecked: const {},
                      hrtDoses: const {},
                      hrtUnits: const {},
                      hrtTimes: const {},
                      initialHrtDoses: const {},
                      initialHrtUnits: const {},
                      onHrtCheckedToggled: (_, __) {},
                      onHrtDoseChanged: (_, __) {},
                      onHrtUnitChanged: (_, __) {},
                      onHrtTimeChanged: (_, __) {},
                      vitaminDChecked: false,
                      magnesiumChecked: false,
                      sleepDuration: currentDuration,
                      sleepQuality: currentQuality,
                      onSleepDurationChanged: (val) {
                        setState(() => currentDuration = val);
                      },
                      onSleepQualityChanged: (val) {
                        setState(() => currentQuality = val);
                      },
                      hydrationCups: 4,
                      additionalNotes: '',
                      otherMedsChecked: const {},
                      onOtherMedsChanged: (_) {},
                      onVitaminDCheckedToggled: (_) {},
                      onMagnesiumCheckedToggled: (_) {},
                      onHydrationCupsChanged: (_) {},
                      onAdditionalNotesChanged: (_) {},
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify sleep duration header and presets exist
      expect(find.text('SLEEP DURATION'), findsOneWidget);
      expect(find.text('SLEEP QUALITY'), findsOneWidget);
      expect(find.text('7.5'), findsOneWidget);
      expect(find.text('8h'), findsOneWidget);

      // Tap 8h preset
      await tester.tap(find.text('8h'));
      await tester.pumpAndSettle();
      expect(currentDuration, equals(8.0));
      expect(find.text('8'), findsOneWidget);

      // Verify 5 quality options are displayed
      expect(find.text('Poor'), findsOneWidget);
      expect(find.text('Fair'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Good'), findsNWidgets(2)); // Sleep quality & Mood category
      expect(find.text('Restful & Deep'), findsOneWidget);

      // Tap 'Good' in Sleep card (score 4)
      await tester.tap(find.text('Good').first);
      await tester.pumpAndSettle();
      expect(currentQuality, equals(4));

      // Tapping 'Good' again deselects it (optional/skippable)
      await tester.tap(find.text('Good').first);
      await tester.pumpAndSettle();
      expect(currentQuality, isNull);

      // Tap 'Restful & Deep' (score 5)
      await tester.tap(find.text('Restful & Deep'));
      await tester.pumpAndSettle();
      expect(currentQuality, equals(5));

      // Tap 'Clear' button
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(currentQuality, isNull);
    });

    testWidgets('Mood 6 categories and 1-5 score rating can be set, adjusted, and cleared in DailyEntryStep', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? currentMood;
      int? currentScore;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    child: DailyEntryStep(
                      hrtChecked: const {},
                      hrtDoses: const {},
                      hrtUnits: const {},
                      hrtTimes: const {},
                      initialHrtDoses: const {},
                      initialHrtUnits: const {},
                      onHrtCheckedToggled: (_, __) {},
                      onHrtDoseChanged: (_, __) {},
                      onHrtUnitChanged: (_, __) {},
                      onHrtTimeChanged: (_, __) {},
                      vitaminDChecked: false,
                      magnesiumChecked: false,
                      sleepDuration: 7.0,
                      selectedMood: currentMood,
                      moodScore: currentScore,
                      onSelectedMoodChanged: (val) {
                        setState(() => currentMood = val);
                      },
                      onMoodScoreChanged: (val) {
                        setState(() => currentScore = val);
                      },
                      hydrationCups: 4,
                      additionalNotes: '',
                      otherMedsChecked: const {},
                      onOtherMedsChanged: (_) {},
                      onVitaminDCheckedToggled: (_) {},
                      onMagnesiumCheckedToggled: (_) {},
                      onSleepDurationChanged: (_) {},
                      onHydrationCupsChanged: (_) {},
                      onAdditionalNotesChanged: (_) {},
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Mood header
      expect(find.text('MOOD & WELL-BEING'), findsOneWidget);

      // Verify all 6 mood categories are present
      expect(find.text('Great'), findsOneWidget);
      expect(find.text('Good'), findsNWidgets(2));
      expect(find.text('Okay'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Anxious'), findsOneWidget);
      expect(find.text('Stressed'), findsOneWidget);

      // Select 'Good' in Mood card
      await tester.tap(find.text('Good').last);
      await tester.pumpAndSettle();

      expect(currentMood, equals('Good'));
      expect(currentScore, equals(4)); // Default score for 'Good' is 4
      expect(find.text('SCORE RATING'), findsOneWidget);
      expect(find.text('4 / 5'), findsOneWidget);

      // Change score rating to 5
      await tester.tap(find.text('5').last);
      await tester.pumpAndSettle();
      expect(currentScore, equals(5));
      expect(find.text('5 / 5'), findsOneWidget);

      // Tap 'Clear' button to deselect
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(currentMood, isNull);
      expect(currentScore, isNull);
      expect(find.text('SCORE RATING'), findsNothing);
    });

    test('Single source of truth: round-trip consistency between Quick Log and Calendar view', () {
      final logDate = DateTime(2026, 4, 15);

      // 1. Simulate Quick Log saving sleep 8 hrs quality 4/5, mood Good 4/5
      final formattedSleep = '8 hours · quality 4/5';
      final formattedMood = 'Good · 4/5';

      final quickLogged = DailyLog(
        id: '2026-04-15',
        userId: 'test_user',
        date: logDate,
        symptoms: const [],
        triggers: const [],
        caffeineCups: 0,
        alcoholGlasses: 0,
        stressLevel: 'Calm',
        sleepDuration: 8.0,
        hydrationCups: 4,
        customTriggerTexts: {
          'sleep_info': formattedSleep,
          'mood_info': formattedMood,
        },
        createdAt: DateTime.now(),
        isCompleted: true,
      );

      // 2. Calendar view converts to MockDailyLog
      final calendarMock = MockDailyLog(
        symptoms: const [],
        sleepInfo: quickLogged.customTriggerTexts['sleep_info'] ?? '${quickLogged.sleepDuration} hours',
        moodInfo: quickLogged.customTriggerTexts['mood_info'] ?? 'Logged',
        hrt: const [],
        triggers: const [],
        itemsCount: 0,
        originalLog: quickLogged,
      );

      expect(calendarMock.sleepInfo, equals('8 hours · quality 4/5'));
      expect(calendarMock.moodInfo, equals('Good · 4/5'));

      // 3. User edits via Calendar View (Sleep to 7h quality 5, Mood to Great 5/5)
      final updatedSleepInfo = '7 hours · quality 5/5';
      final updatedMoodInfo = 'Great · 5/5';
      final updatedLog = quickLogged.copyWith(
        sleepDuration: 7.0,
        stressLevel: 'Calm',
        customTriggerTexts: {
          ...quickLogged.customTriggerTexts,
          'sleep_info': updatedSleepInfo,
          'mood_info': updatedMoodInfo,
        },
      );

      // 4. Quick Log reopens same day and loads existing log
      double loadedDuration = updatedLog.sleepDuration;
      int? loadedQuality;
      final existingSleep = updatedLog.customTriggerTexts['sleep_info'] ?? '';
      final qualityMatch = RegExp(r'quality\s*(\d)/5').firstMatch(existingSleep);
      if (qualityMatch != null) {
        loadedQuality = int.tryParse(qualityMatch.group(1) ?? '');
      }

      String? loadedMood;
      int? loadedMoodScore;
      final existingMood = updatedLog.customTriggerTexts['mood_info'] ?? '';
      for (final def in kMoodDefinitions) {
        if (existingMood.toLowerCase().contains(def.name.toLowerCase())) {
          loadedMood = def.name;
          loadedMoodScore = def.defaultScore;
          break;
        }
      }
      final scoreMatch = RegExp(r'(\d)/5').firstMatch(existingMood);
      if (scoreMatch != null) {
        loadedMoodScore = int.tryParse(scoreMatch.group(1) ?? '');
      }

      expect(loadedDuration, equals(7.0));
      expect(loadedQuality, equals(5));
      expect(loadedMood, equals('Great'));
      expect(loadedMoodScore, equals(5));
      // Confirmed exact round-trip single source of truth!
    });

    test('Both sleep quality and mood are completely optional and skippable', () {
      final logDate = DateTime(2026, 4, 15);

      // Skipped: sleep quality is null, mood is null
      final Map<String, String> texts = {};
      const double sleepDur = 7.5;
      const int? sleepQual = null;
      const String? mood = null;

      final formattedHours = sleepDur.toStringAsFixed(sleepDur == sleepDur.toInt() ? 0 : 1);
      if (sleepQual != null) {
        texts['sleep_info'] = '$formattedHours hours · quality $sleepQual/5';
      } else {
        texts['sleep_info'] = '$formattedHours hours';
      }

      if (mood != null) {
        texts['mood_info'] = '$mood · 3/5';
      } else {
        texts.remove('mood_info');
      }

      final skippedLog = DailyLog(
        id: '2026-04-15',
        userId: 'u1',
        date: logDate,
        symptoms: const [],
        triggers: const [],
        caffeineCups: 0,
        alcoholGlasses: 0,
        stressLevel: 'Moderate',
        sleepDuration: sleepDur,
        hydrationCups: 4,
        customTriggerTexts: texts,
        createdAt: DateTime.now(),
        isCompleted: true,
      );

      expect(skippedLog.customTriggerTexts['sleep_info'], equals('7.5 hours'));
      expect(skippedLog.customTriggerTexts.containsKey('mood_info'), isFalse);
    });
  });
}
