import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/theme/widgets/primary_gradient_button.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_provider.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(onboardingControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Decorative blur circle
          Positioned(
            bottom: -64,
            right: -64,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                color: AppTheme.tertiaryFixed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.tertiaryFixed.withValues(alpha: 0.2),
                    blurRadius: 48,
                    spreadRadius: 48,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top 40%: Illustrative Area
                Expanded(
                  flex: 40,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32.0),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(48),
                            color: AppTheme.surfaceContainer,
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuBtal90IzOgHWFTozog_Z33vE4WL8G-Z65dVHRHMlJRWS5GLkVPmyX2GyoWhWL3OnjCOd_CVADsB4PUspYdT34y6YN9M1K4TSouLoXqQkT2C2FGyC_IKgQ0aMwwed02VgTVH4-ew0qAPK_wK5vdCvt5LXw9dNHI3cRq0WxtDYthNHxs9NBNyUWTvF2BP6RsovkpdNtieT23ZZRj1TMzXTYY86mEH62q6MSWcKaQeperWOVOnbZF2e4fQ4ApRKAH1Paj7GWvHN_QoSM',
                              ),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black26, // simulate the sepia/grayscale opacity from tailwind
                                BlendMode.darken,
                              ),
                            ),
                          ),
                        ),
                        // Glassmorphism overlay
                        Positioned(
                          top: 24,
                          left: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.spa_rounded,
                                  color: AppTheme.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'EUNORA',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Middle 30%: Hero Text Area
                Expanded(
                  flex: 30,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Eunora',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Track your symptoms, understand your body, reclaim your life',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryContainer,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'A private, supportive space to log daily symptoms and discover patterns that matter to you.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom 30%: Call-to-action Buttons
                Expanded(
                  flex: 30,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40.0, right: 40.0, bottom: 48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        isLoading
                            ? const CircularProgressIndicator(color: AppTheme.primary)
                            : PrimaryGradientButton(
                                text: 'Create Account',
                                onPressed: () async {
                                  await ref.read(onboardingControllerProvider.notifier).submitOnboarding();
                                  if (context.mounted) context.go('/privacy');
                                },
                              ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => context.push('/signin'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primary, width: 2),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text(
                            'Sign In',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
