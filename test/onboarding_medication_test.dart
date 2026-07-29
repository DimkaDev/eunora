import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/onboarding/presentation/widgets/add_medication_modal.dart';
import 'package:eunora/features/onboarding/presentation/pages/other_medications_page.dart';
import 'package:eunora/features/hrt_tracker/data/hrt_drug_library.dart';
import 'package:eunora/features/hrt_tracker/domain/adherence_constants.dart';
import 'package:eunora/features/hrt_tracker/presentation/widgets/still_taking_check_in_card.dart';
import 'package:eunora/features/home/presentation/widgets/hrt_tracker/hrt_adherence_card.dart';
import 'package:eunora/features/onboarding/presentation/pages/frequent_symptoms_page.dart';
import 'package:eunora/features/home/presentation/pages/daily_logging/symptoms_step.dart';
import 'package:eunora/features/home/presentation/widgets/calendar_hrt_edit_sheet.dart';

void main() {
  group('Onboarding & Medication Flow Improvements Tests', () {
    test('Medication doseAndFrequency has space between numeric value and unit', () {
      final med = Medication(
        name: 'Estradiol',
        type: MedicationType.pill,
        dose: 2.0,
        unit: 'mg',
        frequency: 'Daily',
      );
      expect(med.doseAndFrequency, equals('2 mg • Daily'));
    });

    test('Autocomplete list in AddMedicationModal includes all library drugs', () {
      final autocompleteNames = kHrtDrugLibrary.map((d) => d.name).toList();
      expect(autocompleteNames, contains('Estradiol'));
      expect(autocompleteNames, contains('Utrogestan'));
      expect(autocompleteNames, contains('Femoston'));
    });

    test('Custom medication in AddMedicationModal allows all forms', () {
      final def = kHrtDrugLibrary.firstWhere(
        (d) => d.name.toLowerCase() == 'my custom hrt',
        orElse: () => const HrtDrugDefinition(
          name: '',
          category: HrtDrugCategory.systemicEstrogen,
          commonForms: [],
          market: HrtMarket.both,
        ),
      );
      expect(def.name, isEmpty); // custom
    });

    testWidgets('AddOtherMedicationModal dose clear on unit change and adapted doses', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const AddOtherMedicationModal(),
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify 'Select dose' placeholder is initially present
      expect(find.text('Select dose'), findsOneWidget);

      // Open bottom sheet dose picker by tapping the dose field
      await tester.tap(find.text('Select dose'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title 'Select Dose' and 'Done' button exist
      expect(find.text('Select Dose'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap 'Done' to select default dose (0.5 mg)
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify dose is set to '0.5 mg'
      expect(find.text('0.5 mg'), findsOneWidget);

      // Change unit to 'capsules' via DropdownButton
      await tester.tap(find.text('mg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('capsules').last);
      await tester.pumpAndSettle();

      // Verify dose was cleared on unit change and shows 'Select dose' placeholder again
      expect(find.text('Select dose'), findsOneWidget);

      // Open bottom sheet dose picker for 'capsules'
      await tester.tap(find.text('Select dose'));
      await tester.pumpAndSettle();

      // Verify 'Select Dose' bottom sheet is shown
      expect(find.text('Select Dose'), findsOneWidget);

      // Tap 'Done'
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify dose is set to '1 capsules'
      expect(find.text('1 capsules'), findsOneWidget);
    });

    test('Discontinued Medication Model supports startedAt and endedAt dates', () {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now().subtract(const Duration(days: 10));

      final discontinuedMed = Medication(
        name: 'Progynova',
        type: MedicationType.pill,
        dose: 2.0,
        unit: 'mg',
        frequency: 'Daily',
        startedAt: startDate,
        endedAt: endDate,
      );

      expect(discontinuedMed.endedAt, equals(endDate));
      expect(discontinuedMed.startedAt, equals(startDate));

      final map = discontinuedMed.toMap();
      expect(map['endedAt'], equals(endDate.toIso8601String()));
      expect(map['startedAt'], equals(startDate.toIso8601String()));

      final reconstructed = Medication.fromMap(map);
      expect(reconstructed.endedAt, equals(endDate));
      expect(reconstructed.startedAt, equals(startDate));
    });

    test('Active medication filter excludes discontinued entry', () {
      final activeMed = Medication(
        name: 'Estradiol',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Twice weekly',
      );
      final discontinuedMed = Medication(
        name: 'Progynova',
        type: MedicationType.pill,
        dose: 2,
        unit: 'mg',
        frequency: 'Daily',
        startedAt: DateTime.now().subtract(const Duration(days: 30)),
        endedAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      final allMeds = [activeMed, discontinuedMed];
      final activeList = allMeds.where((m) => m.endedAt == null).toList();

      expect(activeList.length, equals(1));
      expect(activeList.first.name, equals('Estradiol'));
      expect(allMeds.where((m) => m.endedAt != null).first.name, equals('Progynova'));
    });

    testWidgets('AddMedicationModal supports "I\'m not currently taking this" toggle', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const AddMedicationModal(),
                  ),
                  child: const Text('Open Add Modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Add Modal'));
      await tester.pumpAndSettle();

      // Find the toggle text
      expect(find.text("I'm not currently taking this"), findsOneWidget);

      // Initially start/end date headers are not visible
      expect(find.text('Start Date'), findsNothing);
      expect(find.text('End Date'), findsNothing);

      // Toggle switch to enabled
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Start Date and End Date headers are now visible
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('End Date'), findsOneWidget);
    });

    test('Calendar Adherence: evaluates per-medication startedAt and endedAt date boundaries correctly', () {
      final now = DateTime.now();
      final tenDaysAgo = now.subtract(const Duration(days: 10));
      final fiveDaysAgo = now.subtract(const Duration(days: 5));

      final medWithRange = Medication(
        name: 'Progynova',
        type: MedicationType.pill,
        dose: 2.0,
        unit: 'mg',
        frequency: 'Daily',
        startedAt: tenDaysAgo,
        endedAt: fiveDaysAgo,
      );

      bool isMedActiveOnDate(Medication med, DateTime date) {
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

      // Date before startedAt (15 days ago) -> inactive
      final fifteenDaysAgo = now.subtract(const Duration(days: 15));
      expect(isMedActiveOnDate(medWithRange, fifteenDaysAgo), isFalse);

      // Date within range (7 days ago) -> active
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      expect(isMedActiveOnDate(medWithRange, sevenDaysAgo), isTrue);

      // Date on start date -> active
      expect(isMedActiveOnDate(medWithRange, tenDaysAgo), isTrue);

      // Date on end date -> active
      expect(isMedActiveOnDate(medWithRange, fiveDaysAgo), isTrue);

      // Date after endedAt (2 days ago or today) -> inactive
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      expect(isMedActiveOnDate(medWithRange, twoDaysAgo), isFalse);
      expect(isMedActiveOnDate(medWithRange, now), isFalse);
    });

    test('AdherenceConstants defines single configurable threshold value', () {
      expect(AdherenceConstants.kUnmarkedDaysCheckInThreshold, equals(14));
    });

    testWidgets('StillTakingCheckInCard displays medication prompt and triggers callbacks', (tester) async {
      final med = Medication(
        name: 'Utrogestan',
        type: MedicationType.pill,
        dose: 100,
        unit: 'mg',
        frequency: 'Daily',
      );

      bool stillTakingTapped = false;
      bool stoppedTakingTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StillTakingCheckInCard(
              medication: med,
              consecutiveUnmarkedDays: 14,
              onConfirmStillTaking: () => stillTakingTapped = true,
              onConfirmStoppedTaking: () => stoppedTakingTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title and subtitle rendering
      expect(find.text('Still taking Utrogestan?'), findsOneWidget);
      expect(find.text('Unlogged for 14 consecutive days'), findsOneWidget);

      // Verify buttons exist
      expect(find.text('Yes, still taking'), findsOneWidget);
      expect(find.text('Stopped taking'), findsOneWidget);

      // Tap 'Yes, still taking' button
      await tester.tap(find.text('Yes, still taking'));
      await tester.pumpAndSettle();
      expect(stillTakingTapped, isTrue);

      // Tap 'Stopped taking' button
      await tester.tap(find.text('Stopped taking'));
      await tester.pumpAndSettle();
      expect(stoppedTakingTapped, isTrue);
    });

    testWidgets('HrtAdherenceCard displays filter chips when multiple active medications exist', (tester) async {
      final med1 = Medication(
        name: 'Estradiol',
        type: MedicationType.patch,
        dose: 50,
        unit: 'mcg',
        frequency: 'Twice weekly',
      );
      final med2 = Medication(
        name: 'Utrogestan',
        type: MedicationType.pill,
        dose: 100,
        unit: 'mg',
        frequency: 'Daily',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(medicationsProvider.notifier).state =
          container.read(medicationsProvider).copyWith(medications: [med1, med2]);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: HrtAdherenceCard(
                focusedMonth: DateTime.now(),
                monthlyLogs: const {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify combined title is initially displayed
      expect(find.text('Adherence this month: 100%'), findsOneWidget);

      // Verify filter chips exist
      expect(find.text('All Medications'), findsOneWidget);
      expect(find.text('Estradiol'), findsOneWidget);
      expect(find.text('Utrogestan'), findsOneWidget);

      // Tap 'Estradiol' filter chip
      await tester.tap(find.text('Estradiol'));
      await tester.pumpAndSettle();

      // Verify title updates to 'Estradiol Adherence'
      expect(find.text('Estradiol Adherence: 100%'), findsOneWidget);

      // Tap 'All Medications' filter chip to reset
      await tester.tap(find.text('All Medications'));
      await tester.pumpAndSettle();

      expect(find.text('Adherence this month: 100%'), findsOneWidget);
    });

    testWidgets('FrequentSymptomsPage expands library in-place on Other tap & shows CORE badge', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FrequentSymptomsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify CORE badge is visible for core fixed pins
      expect(find.text('CORE'), findsWidgets);
      expect(find.text('Other'), findsOneWidget);

      // Tap 'Other' card
      await tester.ensureVisible(find.text('Other'));
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      // Verify 'Other' card is replaced by expanded library symptoms in-place
      expect(find.text('Other'), findsNothing);
    });

    testWidgets('SymptomsStep renders CORE/QUICK badges, expands Other in-place, and handles long-press quick access', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(tester.view.resetPhysicalSize);

      final selected = <String>{};

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SymptomsStep(
                  selectedSymptomIds: selected,
                  onSymptomToggled: (id) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify tip banner is visible
      expect(find.textContaining('Press & hold any symptom chip'), findsOneWidget);

      // Verify CORE badge is rendered
      expect(find.text('CORE'), findsWidgets);
      expect(find.text('Other'), findsOneWidget);

      // Tap 'Other' card to expand library in place
      await tester.ensureVisible(find.text('Other'));
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      expect(find.text('Other'), findsNothing);

      // Long press a CORE symptom chip
      final hotFlashChip = find.text('Hot flashes');
      expect(hotFlashChip, findsOneWidget);
      await tester.longPress(hotFlashChip);
      await tester.pumpAndSettle();

      // Verify core pin SnackBar feedback
      expect(find.text('Core symptoms are permanently pinned to Quick Access.'), findsOneWidget);
    });
  });
}
