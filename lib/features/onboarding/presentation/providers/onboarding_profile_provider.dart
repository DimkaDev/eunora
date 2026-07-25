import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptom_quick_access_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/triggers_provider.dart';

import 'package:eunora/features/onboarding/presentation/providers/other_medications_provider.dart';

class OnboardingProfileNotifier extends StateNotifier<UserProfile?> {
  final Ref ref;

  OnboardingProfileNotifier(this.ref) : super(null);

  Future<void> loadOrCreate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = _createDefaultProfile('anonymous');
      return;
    }
    
    try {
      final profile = await ref.read(firestoreServiceProvider).getUserProfile(user.uid);
      if (profile != null) {
        state = profile;
        
        // Sync other providers with values from the loaded profile
        ref.read(menopauseStageProvider.notifier).selectStage(profile.menopauseStage);
        
        // Populate medications
        ref.read(medicationsProvider.notifier).state = ref.read(medicationsProvider.notifier).state.copyWith(
          medications: profile.medications,
        );

        // Populate other medications
        ref.read(otherMedicationsProvider.notifier).state = ref.read(otherMedicationsProvider.notifier).state.copyWith(
          medications: profile.otherMedications,
        );

        // Populate symptoms
        ref.read(symptomsProvider.notifier).state = ref.read(symptomsProvider.notifier).state.copyWith(
          frequentSymptomIds: profile.selectedStageSymptoms.isNotEmpty 
              ? profile.selectedStageSymptoms 
              : ['s_hot_flashes', 's_mood', 's_sleep', 's_dryness', 's_joint_pain'],
        );

        // Seed quick-access ranking from persisted profile data.
        ref.read(symptomQuickAccessProvider.notifier).loadFromProfile(profile);

        // Populate triggers
        ref.read(triggersProvider.notifier).state = ref.read(triggersProvider.notifier).state.copyWith(
          activeTriggerIds: [
            't_coffee',
            't_alcohol',
            't_stress',
            't_exercise',
            't_weather',
            't_spicy_food',
            't_sugar_processed_food',
            't_hot_drinks_food',
            't_skipped_meals',
            't_smoking',
            't_tight_clothing',
            't_warm_bedroom',
          ],
        );
      } else {
        final defaultProfile = _createDefaultProfile(user.uid, email: user.email ?? '');
        state = defaultProfile;
        ref.read(symptomQuickAccessProvider.notifier).loadFromProfile(defaultProfile);
      }
    } catch (e) {
      debugPrint("Error loading/creating onboarding user profile: $e");
      state = _createDefaultProfile(user.uid, email: user.email ?? '');
    }
  }

  UserProfile _createDefaultProfile(String uid, {String email = ''}) {
    return UserProfile(
      uid: uid,
      email: email,
      age: 50,
      menopauseStage: MenopauseStage.irregular,
      yearsInStage: '1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void updateProfile(UserProfile Function(UserProfile) updateFn) {
    if (state != null) {
      state = updateFn(state!).copyWith(updatedAt: DateTime.now());
    }
  }

  Future<void> saveToFirestore() async {
    if (state == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Gather active medications, symptoms, triggers from their respective providers to save
      final medications = ref.read(medicationsProvider).medications;
      final otherMedications = ref.read(otherMedicationsProvider).medications;
      final symptoms = ref.read(symptomsProvider).loggedSymptoms.map((l) => l.symptom.id).toList();
      final triggers = ref.read(triggersProvider).activeTriggerIds;

      final updatedProfile = state!.copyWith(
        medications: medications,
        otherMedications: otherMedications,
        selectedStageSymptoms: symptoms,
        selectedTriggers: triggers,
        isOnboardingCompleted: true,
        updatedAt: DateTime.now(),
      );
      state = updatedProfile;

      await ref.read(firestoreServiceProvider).saveUserProfile(updatedProfile);
    }
  }
}

final onboardingProfileProvider = StateNotifierProvider<OnboardingProfileNotifier, UserProfile?>((ref) {
  return OnboardingProfileNotifier(ref);
});
