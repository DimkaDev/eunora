import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_provider.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  bool build() {
    // Initial state represents if onboarding is currently submitting
    return false;
  }

  Future<void> submitOnboarding() async {
    // Set state to loading
    state = true;
    
    // Mock network request or local DB save
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real app we would save a flag to shared_preferences here
    
    // Set state to finished loading
    state = false;
  }
}
