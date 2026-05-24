import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountConfirmedPage extends StatelessWidget {
  const AccountConfirmedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildCelebrationIcon(),
                    const SizedBox(height: 32),
                    Text(
                      'Account Confirmed! ✓',
                      style: GoogleFonts.notoSerif(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your account is all set up and secure.',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.outline,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildNextStepCard(),
                    const SizedBox(height: 40),
                    _buildActionButtons(context),
                    const SizedBox(height: 48),
                    _buildSecurityFooter(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationIcon() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blur background
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEDDDF5).withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
          // Rotating card
          Transform.rotate(
            angle: 12 * (3.14159 / 180),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEDDDF5), Color(0xFFFFDAD3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle,
                  color: AppTheme.primary,
                  size: 40,
                ),
              ),
            ),
          ),
          // Floating blobs
          Positioned(
            top: 0,
            right: 10,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFFFDAD3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 5,
            left: 10,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFEDDDF5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Now let's set up your health profile. This takes about 3 minutes and helps us personalize your experience.",
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          _buildCheckItem('Get personalized symptom insights'),
          const SizedBox(height: 16),
          _buildCheckItem('Generate reports for your doctor'),
          const SizedBox(height: 16),
          _buildCheckItem('Track your unique patterns'),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        const Icon(Icons.task_alt, color: AppTheme.primary, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF817266)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Bounceable(
            onTap: () => context.push('/menopause-stage'),
            child: IgnorePointer(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue to Health Setup',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: Bounceable(
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboarding_completed_${user.uid}', true);
              }
              if (context.mounted) {
                context.go('/home');
              }
            },
            child: IgnorePointer(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF817266), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "I'll Do This Later",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF817266),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 14, color: AppTheme.outline),
        const SizedBox(width: 8),
        Text(
          'Your data is encrypted and never shared',
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.outline,
          ),
        ),
      ],
    );
  }
}
