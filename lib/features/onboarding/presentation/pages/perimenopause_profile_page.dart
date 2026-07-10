import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:eunora/features/onboarding/presentation/widgets/profile_radio_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';

class PerimenopauseProfilePage extends ConsumerStatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const PerimenopauseProfilePage({super.key, this.onNext, this.onBack});

  @override
  ConsumerState<PerimenopauseProfilePage> createState() => _PerimenopauseProfilePageState();
}

class _PerimenopauseProfilePageState extends ConsumerState<PerimenopauseProfilePage> {
  String? _irregularDuration;
  String? _hormoneTreatment;
  String? _medicationName;
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(onboardingProfileProvider);
      if (profile != null && profile.menopauseStage == MenopauseStage.irregular) {
        setState(() {
          _irregularDuration = profile.irregularDuration;
          _hormoneTreatment = profile.hormoneTreatment;
          _medicationName = profile.medicationName;
          _startDate = profile.startDate;
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
                  'Perimenopause Profile Info',
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
              'Perimenopause is the transitional phase before menopause. Tracking your cycle irregularity length and hormone treatments helps Eunora tailor symptoms logging and prediction models for your specific journey.',
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
                  subtitle: 'PERIMENOPAUSE',
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
                        _buildIrregularPeriodsSection(),
                        const SizedBox(height: 24),
                        _buildHormoneTreatmentSection(),
                        const SizedBox(height: 24),
                        _buildTimelineSection(),
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
          'Your Perimenopause Profile',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Help us understand your cycle patterns',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildIrregularPeriodsSection() {
    return _buildSectionCard(
      title: 'Irregular Periods',
      icon: Icons.history,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How long have your periods been irregular?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: const Color(0xFF1D1B1A).withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ProfileRadioCard(
            title: 'Less than 6 months',
            subtitle: 'Just starting to notice changes',
            isSelected: _irregularDuration == 'less_than_6',
            onTap: () => setState(() => _irregularDuration = 'less_than_6'),
          ),
          ProfileRadioCard(
            title: '6 months to 1 year',
            isSelected: _irregularDuration == '6_to_12',
            onTap: () => setState(() => _irregularDuration = '6_to_12'),
          ),
          ProfileRadioCard(
            title: 'Over 1 year',
            isSelected: _irregularDuration == 'over_1_year',
            onTap: () => setState(() => _irregularDuration = 'over_1_year'),
          ),
          ProfileRadioCard(
            title: "I'm not sure",
            isSelected: _irregularDuration == 'unsure',
            onTap: () => setState(() => _irregularDuration = 'unsure'),
          ),
        ],
      ),
    );
  }

  Widget _buildHormoneTreatmentSection() {
    return _buildSectionCard(
      title: 'Hormone Treatment',
      icon: Icons.link,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you currently on any hormone treatment?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: const Color(0xFF1D1B1A).withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ProfileRadioCard(
            title: "Yes - I'm on HRT or other hormones",
            isSelected: _hormoneTreatment == 'yes',
            onTap: () => setState(() => _hormoneTreatment = 'yes'),
          ),
          ProfileRadioCard(
            title: "No - I'm managing naturally",
            isSelected: _hormoneTreatment == 'no',
            onTap: () => setState(() => _hormoneTreatment = 'no'),
          ),
          ProfileRadioCard(
            title: "I'm not sure",
            isSelected: _hormoneTreatment == 'unsure',
            onTap: () => setState(() => _hormoneTreatment = 'unsure'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return _buildSectionCard(
      title: 'Timeline',
      icon: Icons.calendar_today_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When did your irregular periods start?',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: const Color(0xFF1D1B1A).withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF2EDEA)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _startDate == null 
                      ? 'Select date' 
                      : '${_getMonthName(_startDate!.month)} ${_startDate!.year}',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: _startDate == null ? Colors.grey : const Color(0xFF1D1B1A),
                    ),
                  ),
                  const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                title,
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1D1B1A),
                ),
              ),
              Icon(icon, color: const Color(0xFFD0C4BC), size: 20),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
    final bool isReady = _irregularDuration != null && _hormoneTreatment != null;
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
                            irregularDuration: _irregularDuration,
                            hormoneTreatment: _hormoneTreatment,
                            medicationName: _medicationName,
                            startDate: _startDate,
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

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
