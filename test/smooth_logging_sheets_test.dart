import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/home/presentation/widgets/symptom_logging_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/trigger_logging_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smooth SymptomLoggingSheet Transition Tests', () {
    testWidgets('Opens on Step 0 (Add Symptom), smoothly transitions to Step 1 (Rate Symptom) on tap, and back', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? savedName;
      String? savedSeverity;
      int? savedDuration;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SymptomLoggingSheet(
                loggedSymptoms: const [],
                onSave: (name, severity, duration) {
                  savedName = name;
                  savedSeverity = severity;
                  savedDuration = duration;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Step 0: Header says "Add Symptom"
      expect(find.text('Add Symptom'), findsOneWidget);
      expect(find.text('Rate Symptom'), findsNothing);
      expect(find.text('Search symptoms...'), findsOneWidget);

      // Find and tap "Fatigue" or "Hot flashes"
      final symptomFinder = find.text('Hot flashes');
      expect(symptomFinder, findsWidgets);

      await tester.tap(symptomFinder.first);
      // Pump past tap and micro-delay
      await tester.pump(const Duration(milliseconds: 180));
      // Pump animation
      await tester.pumpAndSettle();

      // Now on Step 1: Header says "Rate Symptom", back arrow is visible, save button is visible
      expect(find.text('Rate Symptom'), findsOneWidget);
      expect(find.text('Add Symptom'), findsNothing);
      expect(find.text('Save Symptom'), findsOneWidget);
      expect(find.text('INTENSITY'), findsOneWidget);
      expect(find.text('DURATION'), findsOneWidget);

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Returns to Step 0 smoothly
      expect(find.text('Add Symptom'), findsOneWidget);
      expect(find.text('Rate Symptom'), findsNothing);

      // Tap Hot flashes again and Save
      await tester.tap(symptomFinder.first);
      await tester.pump(const Duration(milliseconds: 180));
      await tester.pumpAndSettle();

      expect(find.text('Save Symptom'), findsOneWidget);
      await tester.tap(find.text('Save Symptom'));
      await tester.pumpAndSettle();

      expect(savedName, equals('Hot flashes'));
      expect(savedSeverity, isNotNull);
      expect(savedDuration, isNotNull);
    });
  });

  group('Smooth TriggerLoggingSheet Transition Tests', () {
    testWidgets('Opens on Step 0 (Add Daily Trigger), smoothly transitions to Step 1 (Configure Trigger), and back', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? savedName;
      String? savedValue;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TriggerLoggingSheet(
                loggedTriggers: const [],
                onSave: (name, value, icon) {
                  savedName = name;
                  savedValue = value;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Step 0: Header says "Add Daily Trigger"
      expect(find.text('Add Daily Trigger'), findsOneWidget);
      expect(find.text('Configure Trigger'), findsNothing);
      expect(find.text('Search triggers...'), findsOneWidget);

      // Find and tap "Coffee / caffeine" or "Alcohol"
      final triggerFinder = find.text('Coffee / caffeine');
      expect(triggerFinder, findsWidgets);

      await tester.tap(triggerFinder.first);
      // Pump past tap and micro-delay
      await tester.pump(const Duration(milliseconds: 180));
      // Pump animation
      await tester.pumpAndSettle();

      // Now on Step 1: Header says "Configure Trigger", save button is visible
      expect(find.text('Configure Trigger'), findsOneWidget);
      expect(find.text('Add Daily Trigger'), findsNothing);
      expect(find.text('Save Trigger'), findsOneWidget);

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Returns to Step 0 smoothly
      expect(find.text('Add Daily Trigger'), findsOneWidget);
      expect(find.text('Configure Trigger'), findsNothing);

      // Tap trigger again and Save
      await tester.tap(triggerFinder.first);
      await tester.pump(const Duration(milliseconds: 180));
      await tester.pumpAndSettle();

      expect(find.text('Save Trigger'), findsOneWidget);
      await tester.tap(find.text('Save Trigger'));
      await tester.pumpAndSettle();

      expect(savedName, equals('Coffee / caffeine'));
      expect(savedValue, isNotNull);
    });
  });
}
