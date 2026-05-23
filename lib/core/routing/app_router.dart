import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/privacy_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/terms_page.dart';

import 'package:eunora/features/onboarding/presentation/pages/privacy_policy_page.dart';
import 'package:eunora/features/auth/presentation/pages/signup_page.dart';
import 'package:eunora/features/auth/presentation/pages/sign_in_page.dart';
import 'package:eunora/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:eunora/features/auth/presentation/pages/forgot_password_email_sent_page.dart';
import 'package:eunora/features/auth/presentation/pages/forgot_password_otp_page.dart';
import 'package:eunora/features/auth/presentation/pages/reset_password_page.dart';
import 'package:eunora/features/auth/presentation/pages/reset_password_success_page.dart';
import 'package:eunora/features/auth/presentation/pages/verify_email_page.dart';
import 'package:eunora/features/auth/presentation/pages/account_confirmed_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/menopause_stage_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/perimenopause_profile_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/menopause_stage_profile_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/postmenopause_profile_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/surgical_menopause_profile_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/pcos_profile_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/your_medications_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/add_medication_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/frequent_symptoms_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/symptom_library_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/other_medications_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/health_conditions_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/contraception_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/weight_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/lifestyle_habits_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/active_setup_page.dart';
import 'package:eunora/features/home/presentation/pages/home_page.dart';
import 'package:eunora/features/home/presentation/pages/daily_logging_page.dart';
import 'package:eunora/features/home/presentation/pages/hrt_tracker_page.dart';
import 'package:eunora/features/profile/presentation/pages/profile_page.dart';
import 'package:eunora/features/profile/presentation/pages/help_center_page.dart';
import 'package:eunora/features/profile/presentation/pages/notification_preferences_page.dart';
import 'package:eunora/features/profile/presentation/pages/premium_upgrade_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingPage();
      },
    ),
    GoRoute(
      path: '/privacy',
      builder: (BuildContext context, GoRouterState state) {
        return const PrivacyPage();
      },
    ),
    GoRoute(
      path: '/terms',
      builder: (BuildContext context, GoRouterState state) {
        return const TermsPage();
      },
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (BuildContext context, GoRouterState state) {
        return const PrivacyPolicyPage();
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) {
        return const SignUpPage();
      },
    ),
    GoRoute(
      path: '/signin',
      builder: (BuildContext context, GoRouterState state) {
        return const SignInPage();
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (BuildContext context, GoRouterState state) {
        return const ForgotPasswordPage();
      },
    ),
    GoRoute(
      path: '/forgot-password-success',
      builder: (BuildContext context, GoRouterState state) {
        final email = state.extra as String? ?? 'your email';
        return ForgotPasswordEmailSentPage(email: email);
      },
    ),
    GoRoute(
      path: '/forgot-password-otp',
      builder: (BuildContext context, GoRouterState state) {
        return const ForgotPasswordOTPPage();
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (BuildContext context, GoRouterState state) {
        return const ResetPasswordPage();
      },
    ),
    GoRoute(
      path: '/reset-password-success',
      builder: (BuildContext context, GoRouterState state) {
        return const ResetPasswordSuccessPage();
      },
    ),
    GoRoute(
      path: '/verify-email',
      builder: (BuildContext context, GoRouterState state) {
        return const VerifyEmailPage();
      },
    ),
    GoRoute(
      path: '/account-confirmed',
      builder: (BuildContext context, GoRouterState state) {
        return const AccountConfirmedPage();
      },
    ),
    GoRoute(
      path: '/menopause-stage',
      builder: (BuildContext context, GoRouterState state) {
        return const MenopauseStagePage();
      },
    ),
    GoRoute(
      path: '/perimenopause-profile',
      builder: (BuildContext context, GoRouterState state) {
        return const PerimenopauseProfilePage();
      },
    ),
    GoRoute(
      path: '/menopause-stage-profile',
      builder: (BuildContext context, GoRouterState state) {
        return const MenopauseStageProfilePage();
      },
    ),
    GoRoute(
      path: '/postmenopause-profile',
      builder: (BuildContext context, GoRouterState state) {
        return const PostmenopauseProfilePage();
      },
    ),
    GoRoute(
      path: '/surgical-menopause-profile',
      builder: (BuildContext context, GoRouterState state) {
        return const SurgicalMenopauseProfilePage();
      },
    ),
    GoRoute(
      path: '/pcos-profile',
      builder: (BuildContext context, GoRouterState state) {
        return const PCOSProfilePage();
      },
    ),
    GoRoute(
      path: '/medications',
      builder: (BuildContext context, GoRouterState state) {
        return const YourMedicationsPage();
      },
    ),
    GoRoute(
      path: '/add-medication',
      builder: (BuildContext context, GoRouterState state) {
        return AddMedicationPage(initialData: state.extra);
      },
    ),
    GoRoute(
      path: '/symptom-logging',
      builder: (BuildContext context, GoRouterState state) {
        return const FrequentSymptomsPage();
      },
    ),
    GoRoute(
      path: '/symptom-library',
      builder: (BuildContext context, GoRouterState state) {
        return const SymptomLibraryPage();
      },
    ),
    GoRoute(
      path: '/other-medications',
      builder: (BuildContext context, GoRouterState state) {
        return const OtherMedicationsPage();
      },
    ),
    GoRoute(
      path: '/health-conditions',
      builder: (BuildContext context, GoRouterState state) {
        return const HealthConditionsPage();
      },
    ),
    GoRoute(
      path: '/contraception_screening',
      builder: (BuildContext context, GoRouterState state) {
        return const ContraceptionPage();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomePage();
      },
    ),
    GoRoute(
      path: '/daily-logging',
      builder: (BuildContext context, GoRouterState state) {
        return const DailyLoggingPage();
      },
    ),
    GoRoute(
      path: '/weight',
      builder: (context, state) => const WeightPage(),
    ),
    GoRoute(
      path: '/lifestyle-habits',
      builder: (context, state) => const LifestyleHabitsPage(),
    ),
    GoRoute(
      path: '/active-setup',
      builder: (context, state) => const ActiveSetupPage(),
    ),
    GoRoute(
      path: '/hrt-tracker',
      builder: (context, state) => const HrtTrackerPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/help-center',
      builder: (context, state) => const HelpCenterPage(),
    ),
    GoRoute(
      path: '/notification-preferences',
      builder: (context, state) => const NotificationPreferencesPage(),
    ),
    GoRoute(
      path: '/premium-upgrade',
      builder: (context, state) => const PremiumUpgradePage(),
    ),
  ],
);
