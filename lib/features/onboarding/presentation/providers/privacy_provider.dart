import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'privacy_provider.g.dart';

class PrivacyState {
  final bool agreedToTerms;
  final bool consentToAI;
  final bool shareAnonymousData;
  final bool sendProductUpdates;
  final bool isSubmitting;
  final bool acceptedTermsPage;
  final bool acceptedPrivacyPolicyPage;

  const PrivacyState({
    this.agreedToTerms = false,
    this.consentToAI = false,
    this.shareAnonymousData = true,
    this.sendProductUpdates = true,
    this.isSubmitting = false,
    this.acceptedTermsPage = false,
    this.acceptedPrivacyPolicyPage = false,
  });

  bool get canSubmit => agreedToTerms && consentToAI;

  PrivacyState copyWith({
    bool? agreedToTerms,
    bool? consentToAI,
    bool? shareAnonymousData,
    bool? sendProductUpdates,
    bool? isSubmitting,
    bool? acceptedTermsPage,
    bool? acceptedPrivacyPolicyPage,
  }) {
    return PrivacyState(
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      consentToAI: consentToAI ?? this.consentToAI,
      shareAnonymousData: shareAnonymousData ?? this.shareAnonymousData,
      sendProductUpdates: sendProductUpdates ?? this.sendProductUpdates,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      acceptedTermsPage: acceptedTermsPage ?? this.acceptedTermsPage,
      acceptedPrivacyPolicyPage: acceptedPrivacyPolicyPage ?? this.acceptedPrivacyPolicyPage,
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

  void acceptTermsPage() {
    final nextAcceptedTerms = true;
    final nextAcceptedPrivacy = state.acceptedPrivacyPolicyPage;
    state = state.copyWith(
      acceptedTermsPage: nextAcceptedTerms,
      agreedToTerms: nextAcceptedTerms && nextAcceptedPrivacy,
    );
  }

  void acceptPrivacyPolicyPage() {
    final nextAcceptedTerms = state.acceptedTermsPage;
    final nextAcceptedPrivacy = true;
    state = state.copyWith(
      acceptedPrivacyPolicyPage: nextAcceptedPrivacy,
      agreedToTerms: nextAcceptedTerms && nextAcceptedPrivacy,
    );
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
