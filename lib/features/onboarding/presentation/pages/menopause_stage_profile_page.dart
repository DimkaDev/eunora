import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:eunora/features/onboarding/presentation/widgets/profile_radio_card.dart';

class MenopauseStageProfilePage extends StatefulWidget {
  const MenopauseStageProfilePage({super.key});

  @override
  State<MenopauseStageProfilePage> createState() => _MenopauseStageProfilePageState();
}

class _MenopauseStageProfilePageState extends State<MenopauseStageProfilePage> {
  String? _hrtStatus;
  String? _hrtType;
  String? _lastPeriodDuration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(
              currentStep: 1,
              title: 'Health Profile',
              subtitle: 'MENOPAUSE STAGE',
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
                    const SizedBox(height: 40),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          if (_hrtStatus == 'yes') ...[
            Container(
              margin: const EdgeInsets.only(left: 12, bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF7FF),
                borderRadius: BorderRadius.circular(16),
                border: const Border(
                  left: BorderSide(color: Color(0xFF6C6074), width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECT HRT TYPE',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF6C6074),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSubRadioOption('Patch (transdermal)', 'patch'),
                  _buildSubRadioOption('Tablet', 'tablet'),
                  _buildSubRadioOption('Gel (topical)', 'gel'),
                  _buildSubRadioOption('Spray/Nasal', 'spray'),
                  _buildSubRadioOption('Not sure', 'unsure'),
                ],
              ),
            ),
          ],
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

  Widget _buildSubRadioOption(String title, String value) {
    final bool isSelected = _hrtType == value;
    return GestureDetector(
      onTap: () => setState(() => _hrtType = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF6C6074) : const Color(0xFFD0C4BC),
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6C6074),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF1D1B1A),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
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

  Widget _buildFooter() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: (_hrtStatus != null && _lastPeriodDuration != null) ? () => context.go('/medications') : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            'Continue',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/medications'),
          child: Text(
            'SKIP FOR NOW',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF1D1B1A).withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}
