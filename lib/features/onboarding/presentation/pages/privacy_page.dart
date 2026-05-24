import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import '../providers/privacy_provider.dart';

class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(privacyControllerProvider);
    final controller = ref.read(privacyControllerProvider.notifier);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: AppTheme.surface.withOpacity(0.7),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              title: Text(
                'Privacy & Consent',
                style: GoogleFonts.notoSerif(
                  color: const Color(0xFF9B8B7E),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF9B8B7E)),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/onboarding');
                  }
                },
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 140, // Space for AppBar
                left: 24,
                right: 24,
                bottom: 140, // Space for Footer
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header Branding Section
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Color(0xFF9B8B7E),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Privacy Matters',
                    style: GoogleFonts.notoSerif(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We need your permission to securely store and analyze your health data',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF4D453F), // on-surface-variant
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section 1: Required Consents
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'WHAT WE NEED',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: const Color(0xFF4D453F),
                              ),
                            ),
                            Text(
                              '*Required',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildCheckboxItem(
                          value: state.agreedToTerms,
                          onChanged: (val) => controller.toggleTerms(),
                          title: RichText(
                            text: TextSpan(
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurface,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => context.push('/terms'),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => context.push('/privacy-policy'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildCheckboxItem(
                          value: state.consentToAI,
                          onChanged: (val) => controller.toggleAIConsent(),
                          title: const Text('I consent to AI analysis of my symptom data to provide personalized insights'),
                          subtitle: 'This helps us identify patterns unique to you',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Optional Consents
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDDDF5).withOpacity(0.4), // secondary-container / 40
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HELP US IMPROVE (OPTIONAL)',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: const Color(0xFF6C6074), // on-secondary-container
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildCheckboxItem(
                          value: state.shareAnonymousData,
                          onChanged: (val) => controller.toggleAnonymousData(),
                          title: const Text('Share anonymous usage data to help improve Eunora'),
                          subtitle: 'No personal health info is shared',
                        ),
                        const SizedBox(height: 24),
                        _buildCheckboxItem(
                          value: state.sendProductUpdates,
                          onChanged: (val) => controller.toggleProductUpdates(),
                          title: const Text('Send me product updates and health tips'),
                          subtitle: 'Weekly newsletter, unsubscribe anytime',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 3: Critical Statement
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0E8).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: Color(0xFF9B8B7E),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Your data will NEVER be sold to third parties. We're GDPR and HIPAA compliant.",
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Editorial Visual Element
                  Container(
                    height: 192,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBudBvLWgFGRjAKsQui1td7N83kKzq77t2Qku_u0eUBZtU68fOHY7Gmf5tF6Sw40tXR7-Yt9petY-2VeutkfbdB3ell_zH49WDX-hACN3WTftTbIs3uau5hOM820BFo25Vz9Dwyj1JkjJ8QkcgmJjnDzo9UAs41snWuEVi48tpHx9OdG9j36J9udMeHCEC1j8JJXaEnIo3W4mshDMCO79uYAyapuSlGYbgSEuuTVveNE9HTvsM-3wbxkBHLm8PbOab-538V3y0NL9M'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppTheme.surface.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Text(
                            '"Privacy is not an option, it is a prerequisite."',
                            style: GoogleFonts.notoSerif(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D1B1A).withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Bounceable(
                              onTap: state.isSubmitting || !state.canSubmit
                                  ? null
                                  : () async {
                                      final success = await controller.submitConsent();
                                      if (success && context.mounted) {
                                        context.push('/signup');
                                      }
                                    },
                              child: IgnorePointer(
                                child: ElevatedButton(
                                  onPressed: state.isSubmitting || !state.canSubmit ? null : () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                  ),
                                  child: state.isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Text(
                                          'CONTINUE',
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'YOU CAN UPDATE THESE PREFERENCES ANYTIME IN SETTINGS',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: const Color(0xFF4D453F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxItem({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget title,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCheckbox(
          value: value,
          onChanged: (val) => onChanged(val),
          activeColor: AppTheme.primary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle(
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurface,
                ),
                child: title,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF4D453F),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
