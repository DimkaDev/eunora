import 'package:flutter_test/flutter_test.dart';
import 'package:eunora/core/utils/logging_helpers.dart';
import 'package:eunora/features/symptom_log/data/symptom_library.dart';
import 'package:eunora/features/symptom_log/data/trigger_library.dart';

void main() {
  group('Task 17a: Schema and Library Duration Definitions', () {
    test('Hot flashes and Night sweats are defined with inputMethod: intensity_duration', () {
      final hotFlash = kSymptomLibrary.firstWhere((s) => s.id == 'hot_flash');
      final nightSweats = kSymptomLibrary.firstWhere((s) => s.id == 'night_sweats');

      expect(hotFlash.inputMethod, equals('intensity_duration'));
      expect(nightSweats.inputMethod, equals('intensity_duration'));
    });

    test('No other symptom in kSymptomLibrary has inputMethod: intensity_duration', () {
      final otherSymptoms = kSymptomLibrary
          .where((s) => s.id != 'hot_flash' && s.id != 'night_sweats')
          .toList();

      for (final s in otherSymptoms) {
        expect(s.inputMethod, isNot(equals('intensity_duration')),
            reason: 'Symptom ${s.id} should not have intensity_duration');
      }
    });

    test('Exercise trigger is defined with presenceQuantity and quantityUnit: min', () {
      final exercise = kTriggerLibrary.firstWhere((t) => t.id == 'exercise');

      expect(exercise.inputMethod, equals(TriggerInputMethod.presenceQuantity));
      expect(exercise.quantityUnit, equals('min'));
    });

    test('All other 11 core and extended triggers do not use duration quantityUnit: min', () {
      final otherTriggers = kTriggerLibrary.where((t) => t.id != 'exercise').toList();

      for (final t in otherTriggers) {
        expect(t.quantityUnit, isNot(equals('min')),
            reason: 'Trigger ${t.id} should not have duration unit');
      }
    });
  });

  group('Task 17b: Non-Blocking Duration & Unset State Formatting', () {
    test('Exercise formatting with duration > 0 formats as "Exercise: X min"', () {
      final formatted = formatTriggerString(
        't_exercise',
        customTriggerCounters: {'t_exercise': 30},
      );
      expect(formatted, equals('Exercise: 30 min'));
    });

    test('Exercise formatting with 0 or unset duration returns "Exercise" without "0 min"', () {
      final withZero = formatTriggerString(
        't_exercise',
        customTriggerCounters: {'t_exercise': 0},
      );
      expect(withZero, equals('Exercise'));
      expect(withZero, isNot(contains('0 min')));

      final withUnset = formatTriggerString(
        't_exercise',
        customTriggerCounters: {},
      );
      expect(withUnset, equals('Exercise'));
      expect(withUnset, isNot(contains('0 min')));
    });

    test('parseTriggerString cleans legacy "0 min" or "0" back to null (unlogged duration)', () {
      final parsedZero = parseTriggerString('Exercise: 0 min');
      expect(parsedZero.id, equals('exercise'));
      expect(parsedZero.label, equals('Exercise'));
      expect(parsedZero.value, isNull);

      final parsedEmpty = parseTriggerString('Exercise');
      expect(parsedEmpty.id, equals('exercise'));
      expect(parsedEmpty.label, equals('Exercise'));
      expect(parsedEmpty.value, isNull);

      final parsedValid = parseTriggerString('Exercise: 45 min');
      expect(parsedValid.id, equals('exercise'));
      expect(parsedValid.label, equals('Exercise'));
      expect(parsedValid.value, equals('45 min'));
    });
  });
}
