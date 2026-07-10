import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:eunora/features/onboarding/presentation/widgets/profile_radio_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';

class MenopauseStageProfilePage extends ConsumerStatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const MenopauseStageProfilePage({super.key, this.onNext, this.onBack});

  @override
  ConsumerState<MenopauseStageProfilePage> createState() => _MenopauseStageProfilePageState();
}

class _MenopauseStageProfilePageState extends ConsumerState<MenopauseStageProfilePage> {
  String? _hrtStatus;
  String? _hrtType;
  String? _lastPeriodDuration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(onboardingProfileProvider);
      if (profile != null && profile.menopauseStage == MenopauseStage.noPeriod12Months) {
        setState(() {
          _hrtStatus = profile.hrtStatus;
          _hrtType = profile.hrtType;
          _lastPeriodDuration = profile.lastPeriodDuration;
        });
      }
    });
  }

  void _showInfoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFEF8F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menopause Stage Info',
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D1B1A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF9B8B7E)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Menopause represents a permanent cessation of ovulation. Collecting details about your HRT treatment status (patch, tablet, gel, nasal spray) and timeframe since your last cycle helps Eunora structure your personal symptom relief recommendations.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D453F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                OnboardingHeader(
                  currentStep: 1,
                  title: 'Health Profile',
                  subtitle: 'MENOPAUSE STAGE',
                  onBack: widget.onBack,
                  onSkip: _showInfoDialog,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleSection(),
                        const SizedBox(height: 32),
                        _buildHRTSection(),
                        const SizedBox(height: 24),
                        _buildLastPeriodSection(),
                        const SizedBox(height: 160), // Space for footer
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildStickyFooter(context),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Menopause Profile',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '12 months without a period is the clinical marker. Let\'s understand your experience.',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildHRTSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you currently on Hormone Replacement Therapy (HRT)?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 20),
          ProfileRadioCard(
            title: "Yes - I'm on HRT",
            isSelected: _hrtStatus == 'yes',
            onTap: () => setState(() => _hrtStatus = 'yes'),
          ),
          ProfileRadioCard(
            title: "No - I'm not taking hormones",
            isSelected: _hrtStatus == 'no',
            onTap: () => setState(() => _hrtStatus = 'no'),
          ),
          ProfileRadioCard(
            title: "I'm starting HRT soon",
            isSelected: _hrtStatus == 'soon',
            onTap: () => setState(() => _hrtStatus = 'soon'),
          ),
        ],
      ),
    );
  }

  Widget _buildLastPeriodSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How long ago was your last period?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildDurationCard('Around 1 year ago', '1_year'),
          _buildDurationCard('1-2 years ago', '1_2_years'),
          _buildDurationCard('2-5 years ago', '2_5_years'),
          _buildDurationCard('More than 5 years ago', 'over_5_years'),
        ],
      ),
    );
  }

  Widget _buildDurationCard(String title, String value) {
    final bool isSelected = _lastPeriodDuration == value;
    return GestureDetector(
      onTap: () => setState(() => _lastPeriodDuration = value),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBF7F4) : const Color(0xFFFFFBFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: const Color(0xFF1D1B1A),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
    final bool isReady = _hrtStatus != null && _lastPeriodDuration != null;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFEF8F6).withOpacity(0),
                  const Color(0xFFFEF8F6),
                ],
              ),
            ),
          ),
          Container(
            color: const Color(0xFFFEF8F6),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: isReady
                      ? () {
                          ref.read(onboardingProfileProvider.notifier).updateProfile((p) => p.copyWith(
                            hrtStatus: _hrtStatus,
                            hrtType: _hrtType,
                            lastPeriodDuration: _lastPeriodDuration,
                          ));
                          if (widget.onNext != null) {
                            widget.onNext!();
                          } else {
                            context.push('/medications');
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67594E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
