import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/presentation/providers/privacy_provider.dart';

class TermsPage extends ConsumerWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: AppTheme.surface.withValues(alpha: 0.7),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              title: Text(
                'Terms & Conditions',
                style: GoogleFonts.notoSerif(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF67594E)),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/privacy');
                  }
                },
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: Center(
                    child: Text(
                      'UPDATED 10/23',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: const Color(0xFF9B8B7E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background text anchor ornament
          Positioned(
            right: -60,
            top: MediaQuery.of(context).size.height / 2 - 100,
            child: RotatedBox(
              quarterTurns: 1,
              child: Opacity(
                opacity: 0.1,
                child: Text(
                  'EUNORA WELLNESS',
                  style: GoogleFonts.notoSerif(
                    fontSize: 72,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 120, // Space for AppBar
                left: 28,
                right: 28,
                bottom: 140, // Space for Footer
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agreement to Terms',
                    style: GoogleFonts.notoSerif(
                      fontSize: 28,
                      height: 1.2,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Eunora. Before you begin your journey toward holistic wellness balance, please review our usage guidelines.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF4D453F),
                    ),
                  ),
                  const SizedBox(height: 48),

                  _buildSection(
                    number: '01',
                    title: 'USER AGREEMENT',
                    content: 'By accessing Eunora, you agree to be bound by these Terms of Service and all applicable laws and regulations. This app is designed for symptom tracking and wellness education for women transitioning through menopause. You must provide accurate registration information and maintain the security of your account credentials. Your use of the service constitutes your full acceptance of these legally binding terms.',
                    isAltBg: true,
                  ),
                  const SizedBox(height: 48),

                  _buildSection(
                    number: '02',
                    title: 'ACCEPTABLE USE',
                    content: 'Eunora is a space for personal wellness reflection. You agree not to: (a) Use the tracker for any unlawful purposes; (b) Attempt to decompile or reverse engineer any software contained in the app; (c) Harvest data or personal information from other users; (d) Input false or misleading health data with the intent to manipulate system insights. We reserve the right to terminate access for behavior that compromises our serene community standards.',
                    isAltBg: false,
                  ),
                  const SizedBox(height: 48),

                  _buildSection(
                    number: '03',
                    title: 'LIMITATION OF LIABILITY',
                    content: 'Eunora is a supportive tool, not a medical provider. The insights, tracking, and content provided are for informational purposes only. We do not guarantee the accuracy of symptom correlations. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition. In no event shall Eunora be liable for any damages arising out of the use or inability to use the materials on our platform.',
                    isAltBg: true,
                    highlight: 'NOT MEDICAL ADVICE',
                  ),
                  const SizedBox(height: 48),

                  _buildSection(
                    number: '04',
                    title: 'CHANGES TO TERMS',
                    content: 'As Eunora evolves to better serve your needs, we may update these terms. Any changes will be posted here with an updated "Effective Date." Continued use of the app after such changes constitutes your acceptance of the new Terms & Conditions. We recommend periodic review to stay informed about your rights and obligations.',
                    isAltBg: false,
                  ),
                  const SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 32, bottom: 48),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0x33D0C4BC)),
                      ),
                    ),
                    child: Text(
                      '(14) Please review carefully',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF7F756E),
                      ),
                    ),
                  ),
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
                            ref.read(privacyControllerProvider.notifier).acceptTermsPage();
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
                                'ACCEPT TERMS',
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

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
    required bool isAltBg,
    String? highlight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              number,
              style: GoogleFonts.notoSerif(
                fontSize: 24,
                color: const Color(0xFF9D675C).withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isAltBg ? AppTheme.surfaceContainerLow : AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: isAltBg ? null : Border.all(color: const Color(0xFFD0C4BC).withValues(alpha: 0.1)),
            boxShadow: isAltBg
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: highlight != null
              ? Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppTheme.primaryContainer, width: 2),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        highlight,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          height: 1.6,
                          color: const Color(0xFF4D453F),
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  content,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    height: 1.6,
                    color: const Color(0xFF4D453F),
                  ),
                ),
        ),
      ],
    );
  }
}
