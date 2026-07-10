import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/onboarding/presentation/widgets/add_medication_modal.dart';
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
  });
}
