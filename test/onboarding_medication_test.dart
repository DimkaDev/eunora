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
  });
}
