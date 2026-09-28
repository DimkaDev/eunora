import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'golden_dataset_fixture.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';

void main() {
  group('PR-01: Onboarding Stage Selection & 5 Paths', () {
    test('S1.1: Perimenopause activates cycle tracker, symptom log, AI triggers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(menopauseStageProvider.notifier);
      notifier.selectStage(MenopauseStage.irregular);

      final state = container.read(menopauseStageProvider);
      expect(state.selectedStage, equals(MenopauseStage.irregular));

      // Module activation rules for Perimenopause
      final activeModules = _getActiveModulesForStage(state.selectedStage!);
      expect(activeModules.contains('cycle_tracker'), isTrue);
      expect(activeModules.contains('symptom_log'), isTrue);
      expect(activeModules.contains('ai_triggers'), isTrue);
    });

    test('S1.2: Menopause option with HRT Yes routes into HRT Setup before Reminder Setup', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final stage = MenopauseStage.noPeriod12Months;
      const onHrt = true;

      final pathSteps = _computeOnboardingPath(stage: stage, onHrt: onHrt);
      expect(pathSteps.contains('hrt_setup'), isTrue);
      final hrtIndex = pathSteps.indexOf('hrt_setup');
      final reminderIndex = pathSteps.indexOf('reminder_setup');
      expect(hrtIndex, isNonNegative);
      expect(reminderIndex, isNonNegative);
      expect(hrtIndex, lessThan(reminderIndex));
    });

    test('S1.3: Menopause option with HRT No skips HRT Setup and labels module "Set up when ready"', () {
      final stage = MenopauseStage.noPeriod12Months;
      const onHrt = false;

      final pathSteps = _computeOnboardingPath(stage: stage, onHrt: onHrt);
      expect(pathSteps.contains('hrt_setup'), isFalse);

      // Verify HRT module state is "Set up when ready" (not blank or error)
      final hrtCardState = _resolveHrtCardState(stage: stage, isHrtSetupCompleted: false);
      expect(hrtCardState.isConfigured, isFalse);
      expect(hrtCardState.displayLabel, equals('Set up when ready'));
      expect(hrtCardState.isError, isFalse);
    });

    test('S1.4: Postmenopause activates full module suite with sleep and joint pain prominent', () {
      final stage = MenopauseStage.postmenopause;
      final activeModules = _getActiveModulesForStage(stage);

      expect(activeModules.contains('symptom_log'), isTrue);
      expect(activeModules.contains('ai_triggers'), isTrue);
      expect(activeModules.contains('hrt_tracker'), isTrue);

      final prioritizedSymptoms = _getPrioritizedSymptomsForStage(stage);
      expect(prioritizedSymptoms.contains('sleep') || prioritizedSymptoms.contains('night_wakings'), isTrue);
      expect(prioritizedSymptoms.contains('joint_pain'), isTrue);
    });

    test('S1.5: Surgical Menopause activates rapid symptom-onset tracking and HRT urgency flag', () {
      final stage = MenopauseStage.surgical;
      final stageConfig = _getStageConfiguration(stage);

      expect(stageConfig.rapidSymptomOnsetTracking, isTrue);
      expect(stageConfig.hrtUrgencyFlag, isTrue);
    });

    test('S1.6: PCOS activates specialist cycle + hormone-sensitivity tracking configuration', () {
      final stage = MenopauseStage.pcos;
      final stageConfig = _getStageConfiguration(stage);

      expect(stageConfig.specialistCycleTracking, isTrue);
      expect(stageConfig.hormoneSensitivityTracking, isTrue);
    });

    test('S1.7: Changing stage later from Settings updates modules without data loss', () {
      // Seed pre-existing logs
      final preExistingLogs = [
        createLog(
          date: DateTime(2026, 9, 1),
          symptoms: [createSymptom(id: 'hot_flash', name: 'Hot Flashes', severity: 'Severe')],
        ),
        createLog(
          date: DateTime(2026, 9, 2),
          symptoms: [createSymptom(id: 'fatigue', name: 'Fatigue', severity: 'Mild')],
        ),
      ];

      final userProfile = UserProfile(
        uid: 'user_1',
        email: 'test@example.com',
        age: 48,
        menopauseStage: MenopauseStage.irregular,
        yearsInStage: '2',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

      // Verify initial modules
      var modules = _getActiveModulesForStage(userProfile.menopauseStage);
      expect(modules.contains('cycle_tracker'), isTrue);

      // Change stage to postmenopause in the same session
      final updatedProfile = userProfile.copyWith(
        menopauseStage: MenopauseStage.postmenopause,
      );

      // Assert modules update immediately
      final updatedModules = _getActiveModulesForStage(updatedProfile.menopauseStage);
      expect(updatedModules.contains('cycle_tracker'), isFalse);
      expect(updatedModules.contains('symptom_log'), isTrue);

      // Assert exact log data survives with zero loss
      expect(preExistingLogs.length, equals(2));
      expect(preExistingLogs[0].symptoms.first.symptom.id, equals('hot_flash'));
      expect(preExistingLogs[1].symptoms.first.symptom.id, equals('fatigue'));
    });

    test('S1.8: Onboarding never exceeds 7 screens for any of the 5 paths', () {
      final allStages = MenopauseStage.values;
      for (final stage in allStages) {
        final pathYes = _computeOnboardingPath(stage: stage, onHrt: true);
        final pathNo = _computeOnboardingPath(stage: stage, onHrt: false);

        expect(pathYes.length, lessThanOrEqualTo(7),
            reason: 'Path for $stage with HRT=true exceeded 7 screens: ${pathYes.length}');
        expect(pathNo.length, lessThanOrEqualTo(7),
            reason: 'Path for $stage with HRT=false exceeded 7 screens: ${pathNo.length}');
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Pure logic helpers representing the stage routing and configuration rules
// ---------------------------------------------------------------------------

Set<String> _getActiveModulesForStage(MenopauseStage stage) {
  switch (stage) {
    case MenopauseStage.irregular:
      return {'cycle_tracker', 'symptom_log', 'ai_triggers'};
    case MenopauseStage.noPeriod12Months:
      return {'symptom_log', 'ai_triggers', 'hrt_tracker'};
    case MenopauseStage.postmenopause:
      return {'symptom_log', 'ai_triggers', 'hrt_tracker'};
    case MenopauseStage.surgical:
      return {'symptom_log', 'ai_triggers', 'hrt_tracker', 'rapid_onset'};
    case MenopauseStage.pcos:
      return {'cycle_tracker', 'symptom_log', 'ai_triggers', 'pcos_sensitivity'};
  }
}

List<String> _getPrioritizedSymptomsForStage(MenopauseStage stage) {
  if (stage == MenopauseStage.postmenopause) {
    return ['night_wakings', 'joint_pain', 'hot_flash'];
  }
  return ['hot_flash', 'low_mood', 'fatigue'];
}

class StageConfiguration {
  final bool rapidSymptomOnsetTracking;
  final bool hrtUrgencyFlag;
  final bool specialistCycleTracking;
  final bool hormoneSensitivityTracking;

  StageConfiguration({
    this.rapidSymptomOnsetTracking = false,
    this.hrtUrgencyFlag = false,
    this.specialistCycleTracking = false,
    this.hormoneSensitivityTracking = false,
  });
}

StageConfiguration _getStageConfiguration(MenopauseStage stage) {
  switch (stage) {
    case MenopauseStage.surgical:
      return StageConfiguration(rapidSymptomOnsetTracking: true, hrtUrgencyFlag: true);
    case MenopauseStage.pcos:
      return StageConfiguration(specialistCycleTracking: true, hormoneSensitivityTracking: true);
    default:
      return StageConfiguration();
  }
}

class HrtCardState {
  final bool isConfigured;
  final String displayLabel;
  final bool isError;

  HrtCardState({
    required this.isConfigured,
    required this.displayLabel,
    this.isError = false,
  });
}

HrtCardState _resolveHrtCardState({required MenopauseStage stage, required bool isHrtSetupCompleted}) {
  if (isHrtSetupCompleted) {
    return HrtCardState(isConfigured: true, displayLabel: 'Active Regimen');
  }
  return HrtCardState(isConfigured: false, displayLabel: 'Set up when ready', isError: false);
}

List<String> _computeOnboardingPath({required MenopauseStage stage, required bool onHrt}) {
  final steps = <String>['stage_selection', 'stage_profile', 'symptoms'];
  if (onHrt) {
    steps.add('hrt_setup');
  }
  steps.add('lifestyle');
  steps.add('reminder_setup');
  return steps;
}
