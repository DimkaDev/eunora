import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/routing/route_transitions.dart';
import 'package:eunora/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/splash_screen.dart';
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

import 'package:eunora/features/onboarding/presentation/pages/frequent_symptoms_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/symptom_library_page.dart';
import 'package:eunora/features/onboarding/presentation/pages/trigger_library_page.dart';
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
import 'package:eunora/features/home/presentation/pages/notification_center_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const OnboardingPage(),
      ),
    ),
    GoRoute(
      path: '/privacy',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const PrivacyPage(),
      ),
    ),
    GoRoute(
      path: '/terms',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const TermsPage(),
      ),
    ),
    GoRoute(
      path: '/privacy-policy',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const PrivacyPolicyPage(),
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const SignUpPage(),
      ),
    ),
    GoRoute(
      path: '/signin',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const SignInPage(),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const ForgotPasswordPage(),
      ),
    ),
    GoRoute(
      path: '/forgot-password-success',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final email = state.extra as String? ?? 'your email';
        return buildSmoothPageTransition(
          context: context,
          state: state,
          child: ForgotPasswordEmailSentPage(email: email),
        );
      },
    ),
    GoRoute(
      path: '/forgot-password-otp',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const ForgotPasswordOTPPage(),
      ),
    ),
    GoRoute(
      path: '/reset-password',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const ResetPasswordPage(),
      ),
    ),
    GoRoute(
      path: '/reset-password-success',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const ResetPasswordSuccessPage(),
      ),
    ),
    GoRoute(
      path: '/verify-email',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const VerifyEmailPage(),
      ),
    ),
    GoRoute(
      path: '/account-confirmed',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const AccountConfirmedPage(),
      ),
    ),
    GoRoute(
      path: '/menopause-stage',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const MenopauseStagePage(),
      ),
    ),
    GoRoute(
      path: '/perimenopause-profile',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const PerimenopauseProfilePage(),
      ),
    ),
    GoRoute(
      path: '/menopause-stage-profile',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const MenopauseStageProfilePage(),
      ),
    ),
    GoRoute(
      path: '/postmenopause-profile',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const PostmenopauseProfilePage(),
      ),
    ),
    GoRoute(
      path: '/surgical-menopause-profile',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const SurgicalMenopauseProfilePage(),
      ),
    ),
    GoRoute(
      path: '/pcos-profile',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const PCOSProfilePage(),
      ),
    ),
    GoRoute(
      path: '/medications',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const YourMedicationsPage(),
      ),
    ),

    GoRoute(
      path: '/symptom-logging',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const FrequentSymptomsPage(),
      ),
    ),
    GoRoute(
      path: '/symptom-library',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const SymptomLibraryPage(),
      ),
    ),
    GoRoute(
      path: '/trigger-library',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const TriggerLibraryPage(),
      ),
    ),
    GoRoute(
      path: '/other-medications',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const OtherMedicationsPage(),
      ),
    ),
    GoRoute(
      path: '/health-conditions',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const HealthConditionsPage(),
      ),
    ),
    GoRoute(
      path: '/contraception_screening',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const ContraceptionPage(),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const HomePage(),
      ),
    ),
    GoRoute(
      path: '/daily-logging',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const DailyLoggingPage(),
      ),
    ),
    GoRoute(
      path: '/weight',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const WeightPage(),
      ),
    ),
    GoRoute(
      path: '/lifestyle-habits',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const LifestyleHabitsPage(),
      ),
    ),
    GoRoute(
      path: '/active-setup',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const ActiveSetupPage(),
      ),
    ),
    GoRoute(
      path: '/hrt-tracker',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const HrtTrackerPage(),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const ProfilePage(),
      ),
    ),
    GoRoute(
      path: '/help-center',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const HelpCenterPage(),
      ),
    ),
    GoRoute(
      path: '/notification-preferences',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const NotificationPreferencesPage(),
      ),
    ),
    GoRoute(
      path: '/notification-center',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const NotificationCenterPage(),
      ),
    ),
    GoRoute(
      path: '/premium-upgrade',
      pageBuilder: (BuildContext context, GoRouterState state) => buildSmoothPageTransition(
        context: context,
        state: state,
        child: const PremiumUpgradePage(),
      ),
    ),
  ],
);
