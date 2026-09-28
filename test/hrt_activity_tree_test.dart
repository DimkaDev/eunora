import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import 'package:eunora/features/home/presentation/pages/hrt_tracker_page.dart';

class FakeMedications extends Medications {
  final List<Medication> initialMeds;
  FakeMedications(this.initialMeds);

  @override
  MedicationsState build() {
    return MedicationsState(medications: initialMeds);
  }

  @override
  Future<void> loadFromFirestore() async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HRT Activity Tree Log UI & Toggle Modes', () {
    testWidgets('renders timeline tree by default and allows toggling to flow map tree', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final estroMed = Medication(
        id: 'med_estradiol',
        name: 'Estradiol Patch',
        dose: 100,
        unit: 'mcg',
        type: MedicationType.patch,
        frequency: 'Daily',
        startedAt: DateTime(now.year, now.month, now.day),
      );

      final progMed = Medication(
        id: 'med_progesterone',
        name: 'Utrogestan',
        dose: 100,
        unit: 'mg',
        type: MedicationType.pill,
        frequency: 'Daily',
        startedAt: DateTime(now.year, now.month, now.day),
      );

      final container = ProviderContainer(
        overrides: [
          medicationsProvider.overrideWith(() => FakeMedications([estroMed, progMed])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HrtTrackerPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Activity Log section
      await tester.scrollUntilVisible(
        find.text('ACTIVITY LOG'),
        500,
        scrollable: find.byType(Scrollable).first,
      );

      // Verify header & toggle buttons
      expect(find.text('ACTIVITY LOG'), findsOneWidget);
      expect(find.text('Timeline Tree'), findsOneWidget);
      expect(find.text('Flow Map'), findsOneWidget);
      expect(find.text('Modern Tree'), findsOneWidget);
      expect(find.text('Clean Text'), findsOneWidget);
      expect(find.text('Non-Tree'), findsOneWidget);
      expect(find.text('AI Journey'), findsOneWidget);

      // Verify that each medication appears in Version 1 (Timeline Tree)
      expect(find.text('Estradiol Patch'), findsWidgets);
      expect(find.text('Utrogestan'), findsWidgets);
      expect(find.text('Transdermal Patch • 100 mcg • Daily'), findsOneWidget);
      expect(find.text('Oral Tablet • 100 mg • Daily'), findsOneWidget);

      // Toggle to Version 2 (Flow Map)
      await tester.tap(find.byKey(const ValueKey('tree_mode_flow')));
      await tester.pumpAndSettle();

      // Verify Flow Map elements (ROOT badges, category tags)
      expect(find.text('ROOT'), findsWidgets);
      expect(find.text('MILESTONE'), findsWidgets);

      // Verify SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_hrt_activity_tree_mode'), 'flowTree');

      // Toggle to Version 3 (Modern Tree)
      await tester.tap(find.byKey(const ValueKey('tree_mode_modern')));
      await tester.pumpAndSettle();

      expect(find.text('MILESTONE'), findsWidgets);
      expect(prefs.getString('pref_hrt_activity_tree_mode'), 'modernTree');

      // Toggle to Version 4 (Clean Text)
      await tester.tap(find.byKey(const ValueKey('tree_mode_minimal')));
      await tester.pumpAndSettle();

      expect(find.text('Estradiol Patch'), findsWidgets);
      expect(find.text('• Transdermal Patch (100 mcg • Daily)'), findsOneWidget);
      expect(prefs.getString('pref_hrt_activity_tree_mode'), 'minimalTextTree');

      // Toggle to Version 5 (Non-Tree Cards)
      await tester.tap(find.byKey(const ValueKey('tree_mode_nontree')));
      await tester.pumpAndSettle();

      expect(find.text('Estradiol Patch'), findsWidgets);
      expect(prefs.getString('pref_hrt_activity_tree_mode'), 'nonTreeCards');

      // Toggle to Version 6 (AI Journey)
      await tester.tap(find.byKey(const ValueKey('tree_mode_smart')));
      await tester.pumpAndSettle();

      expect(find.text('TREATMENT TIMELINE & TODAY'), findsWidgets);
      expect(find.text('Consistent hormone delivery fosters steady equilibrium and symptom relief.'), findsWidgets);
      expect(prefs.getString('pref_hrt_activity_tree_mode'), 'smartStory');

      // Toggle back to Timeline Tree
      await tester.tap(find.byKey(const ValueKey('tree_mode_timeline')));
      await tester.pumpAndSettle();

      expect(prefs.getString('pref_hrt_activity_tree_mode'), 'timelineTree');
    });

    testWidgets('shows full empty state when no medications are configured', (tester) async {
      final container = ProviderContainer(
        overrides: [
          medicationsProvider.overrideWith(() => FakeMedications([])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HrtTrackerPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your HRT journey starts here.'), findsOneWidget);
    });

    testWidgets('disables Log dose button for as-needed medications when past date is selected', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final asNeededMed = Medication(
        id: 'med_prn',
        name: 'Progesterone Spray',
        dose: 10,
        unit: 'mg',
        type: MedicationType.spray,
        frequency: 'As needed',
      );

      final container = ProviderContainer(
        overrides: [
          medicationsProvider.overrideWith(() => FakeMedications([asNeededMed])),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HrtTrackerPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('AS NEEDED MEDICATIONS'),
        500,
        scrollable: find.byType(Scrollable).first,
      );

      // Today is selected by default: Log dose button is enabled
      final logDoseBtnFinder = find.widgetWithText(ElevatedButton, 'Log dose');
      expect(logDoseBtnFinder, findsOneWidget);
      final todayButton = tester.widget<ElevatedButton>(logDoseBtnFinder);
      expect(todayButton.onPressed, isNotNull);

      // Tap on previous month button to select a past date
      await tester.scrollUntilVisible(
        find.byIcon(Icons.chevron_left),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Scroll back down to AS NEEDED MEDICATIONS
      await tester.scrollUntilVisible(
        find.text('AS NEEDED MEDICATIONS'),
        500,
        scrollable: find.byType(Scrollable).first,
      );

      // On a past date, the button should be disabled
      final pastButton = tester.widget<ElevatedButton>(logDoseBtnFinder);
      expect(pastButton.onPressed, isNull);
      expect(find.text('Not logged on this day'), findsOneWidget);
    });
  });
}
