import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/presentation/providers/privacy_provider.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: AppTheme.surface.withValues(alpha: 0.7),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Privacy Policy',
                    style: GoogleFonts.notoSerif(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'HOW WE PROTECT YOUR HEALTH DATA',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/privacy');
                  }
                },
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 110, // Space for AppBar
                left: 20,
                right: 20,
                bottom: 120, // Space for Footer
              ),
              child: Column(
                children: [
                  // Hero Editorial Text
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        Text(
                          'Your Trust, Our Priority',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSerif(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'At Eunora, we believe your health journey is personal. Our commitment is to ensure your sensitive information remains private, secure, and under your control.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // 1. Data We Collect
                  _buildWhiteSection(
                    icon: Icons.storage,
                    title: 'Data We Collect',
                    content: Column(
                      children: [
                        _buildBulletPoint('Symptoms and daily wellness logging'),
                        _buildBulletPoint('HRT information and medication schedules'),
                        _buildBulletPoint('App usage data to improve your experience'),
                        _buildBulletPoint('Basic device information and OS version'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. How We Use Your Data
                  _buildWhiteSection(
                    icon: Icons.insights,
                    title: 'How We Use Your Data',
                    content: Column(
                      children: [
                        _buildInfoCard(
                          title: 'Personalized Insights',
                          description: 'We analyze your logs to provide tailored symptom tracking trends.',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          title: 'Medical Reports',
                          description: 'Generating data summaries that you can choose to share with your doctor.',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          title: 'App Reliability',
                          description: 'Monitoring technical performance to ensure the app remains stable and secure.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. How We Protect Your Data (Highlight)
                  _buildHighlightedSection(
                    icon: Icons.verified_user,
                    title: 'How We Protect Your Data',
                    content: Column(
                      children: [
                        _buildSecurityItem(
                          icon: Icons.lock_outline,
                          title: 'End-to-End Encryption',
                          description: 'Your health data is encrypted both in transit and at rest.',
                        ),
                        const SizedBox(height: 16),
                        _buildSecurityItem(
                          icon: Icons.gavel_outlined,
                          title: 'GDPR & HIPAA Compliance',
                          description: 'We adhere to the highest global standards for medical data privacy.',
                        ),
                        const SizedBox(height: 16),
                        _buildSecurityItem(
                          icon: Icons.visibility_outlined,
                          title: 'Regular Security Audits',
                          description: 'Independent third-parties regularly review our security protocols.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Your Rights
                  _buildWhiteSection(
                    icon: Icons.person_pin_circle_outlined,
                    title: 'Your Rights',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRightItem(
                          label: 'Data Access & Export',
                          badge: 'Settings > Privacy',
                        ),
                        const SizedBox(height: 12),
                        _buildRightItem(
                          label: 'Account Deletion',
                          trailing: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You can opt-out of non-essential communications at any time through the preferences menu.',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. Third-Party Sharing (Highlight)
                  _buildHighlightedSection(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Third-Party Sharing',
                    content: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'WE NEVER SELL YOUR DATA',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: const Color(0xFF2E4D2E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCheckItem('Service providers (AWS/Firebase) for storage only.'),
                        const SizedBox(height: 12),
                        _buildCheckItem('Doctor sharing only with your explicit consent.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6. Cookies & Tracking
                  _buildWhiteSection(
                    icon: Icons.cookie_outlined,
                    title: 'Cookies & Tracking',
                    content: Text(
                      'We do not use advertising or tracking cookies. We only collect anonymized feature usage analytics to understand how we can make the app more helpful for you.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 7. Changes to Policy
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.outlineVariant,
                        style: BorderStyle.none,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Policy Updates',
                              style: GoogleFonts.notoSerif(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              'Last updated: Jan 2024',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We will notify you within the app if any material changes are made to this policy. Continued use of Eunora after updates constitutes acceptance.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom Action Footer
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Bounceable(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/privacy');
                            }
                          },
                          child: IgnorePointer(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF9B8B7E)),
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'DECLINE',
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Bounceable(
                          onTap: () {
                            ref.read(privacyControllerProvider.notifier).acceptPrivacyPolicyPage();
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/privacy');
                            }
                          },
                          child: IgnorePointer(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              child: Text(
                                'ACCEPT POLICY',
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteSection({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildHighlightedSection({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E8), // Light green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0E2D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2E4D2E), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E4D2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryContainer)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String description}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2E4D2E), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E4D2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF2E4D2E).withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightItem({required String label, String? badge, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('✓', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4D2E))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: const Color(0xFF2E4D2E),
            ),
          ),
        ),
      ],
    );
  }
}
