import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'privacy_provider.g.dart';

class PrivacyState {
  final bool agreedToTerms;
  final bool consentToAI;
  final bool shareAnonymousData;
  final bool sendProductUpdates;
  final bool isSubmitting;

  const PrivacyState({
    this.agreedToTerms = false,
    this.consentToAI = false,
    this.shareAnonymousData = false,
    this.sendProductUpdates = false,
    this.isSubmitting = false,
  });

  bool get canSubmit => agreedToTerms && consentToAI;

  PrivacyState copyWith({
    bool? agreedToTerms,
    bool? consentToAI,
    bool? shareAnonymousData,
    bool? sendProductUpdates,
    bool? isSubmitting,
  }) {
    return PrivacyState(
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      consentToAI: consentToAI ?? this.consentToAI,
      shareAnonymousData: shareAnonymousData ?? this.shareAnonymousData,
      sendProductUpdates: sendProductUpdates ?? this.sendProductUpdates,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

@riverpod
class PrivacyController extends _$PrivacyController {
  @override
  PrivacyState build() {
    return const PrivacyState();
  }

  void toggleTerms() {
    state = state.copyWith(agreedToTerms: !state.agreedToTerms);
  }

  void toggleAIConsent() {
    state = state.copyWith(consentToAI: !state.consentToAI);
  }

  void toggleAnonymousData() {
    state = state.copyWith(shareAnonymousData: !state.shareAnonymousData);
  }

  void toggleProductUpdates() {
    state = state.copyWith(sendProductUpdates: !state.sendProductUpdates);
  }

  Future<bool> submitConsent() async {
    if (!state.canSubmit) return false;
    
    state = state.copyWith(isSubmitting: true);
    
    // Mock API call
    await Future.delayed(const Duration(seconds: 1));
    
    state = state.copyWith(isSubmitting: false);
    return true;
  }
}
