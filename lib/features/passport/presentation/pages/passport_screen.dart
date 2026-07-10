import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/widgets/app_card.dart';
import 'package:eunora/core/services/premium_guard_provider.dart';
import 'package:eunora/features/passport/providers/passport_provider.dart';
import 'package:eunora/features/passport/providers/passport_screen_controller.dart';

class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key});

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends ConsumerState<PassportScreen> {
  int _selectedPeriodDays = 60; // 30, 60, or 90
  bool _isGenerating = false;
  String? _inlineError;

  // Track toggled sections
  final Map<String, bool> _sections = {
    'Patient profile': true,
    'Symptom statistics': true,
    'Trend charts': true,
    'AI patterns & triggers': true,
    'HRT history & impact': true,
    'Full log table': true,
  };

  @override
  Widget build(BuildContext context) {
    final eligibilityAsync = ref.watch(passportScreenControllerProvider);
    final isPremium = ref.watch(premiumGuardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6),
      appBar: AppBar(
        title: Text(
          'Menopause Passport',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: eligibilityAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          error: (err, stack) {
            debugPrint("Error loading passport eligibility: $err\n$stack");
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text("Something went wrong — your data is safe"),
              ),
            );
          },
          data: (eligibility) {
            if (!eligibility.hasMinimumData) {
              return _buildCountdownState(eligibility);
            }

            return _buildGenerationScreen(isPremium);
          },
        ),
      ),
    );
  }

  Widget _buildCountdownState(PassportEligibility eligibility) {
    final double progress = (eligibility.totalDays / 30).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Generate your clinical passport",
            style: GoogleFonts.notoSerif(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "A comprehensive record designed for your gynaecologist to optimize treatment and HRT adjustments.",
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 32),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${eligibility.daysRemaining} days to go",
                      style: GoogleFonts.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      "${eligibility.totalDays} / 30 logged",
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: const Color(0xFFF2EDEA),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA8D5BA)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Specialist teaser info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF2EDEA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF9B8B7E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Clinical guidelines recommend compiling at least 30 days of symptom logging to establish clear baseline trends before sharing with your gynaecologist.",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.onSurfaceVariant,
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

  Widget _buildGenerationScreen(bool isPremium) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Readiness Card
          AppCard(
            color: const Color(0xFFF1FDF5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFA8D5BA),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'READY TO GENERATE',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: const Color(0xFF2E5E4E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Baseline Established',
                      style: GoogleFonts.notoSerif(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.check_circle_outline, color: Color(0xFFA8D5BA), size: 36),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Period selector
          Text(
            'REPORT PERIOD',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF9B8B7E),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2EDEA),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                _buildPeriodButton(30, '30 Days'),
                _buildPeriodButton(60, '60 Days'),
                _buildPeriodButton(90, '90 Days'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Include sections toggles
          Text(
            'INCLUDE SECTIONS',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF9B8B7E),
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: _sections.keys.map((title) {
                final isEnabled = _sections[title] ?? false;
                final bool sectionIsPremium = title == 'AI patterns & triggers' || title == 'HRT history & impact';
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          if (sectionIsPremium) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAD6),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'PREMIUM',
                                style: GoogleFonts.manrope(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF6E3E3E),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Switch.adaptive(
                        value: isEnabled,
                        activeColor: AppTheme.primary,
                        onChanged: (val) {
                          setState(() {
                            _sections[title] = val;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),

          if (_inlineError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFBA1A1A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _inlineError!,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: const Color(0xFFBA1A1A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFFBA1A1A)),
                    onPressed: () => _handleGenerate(isPremium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Generate CTA Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : () => _handleGenerate(isPremium),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Preparing your report...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined),
                        const SizedBox(width: 8),
                        Text(
                          'Generate Passport PDF',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(int days, String label) {
    final isSelected = _selectedPeriodDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriodDays = days),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGenerate(bool isPremium) async {
    if (!isPremium) {
      // Gated to Paywall for Free users
      context.push('/premium-upgrade');
      return;
    }

    setState(() {
      _isGenerating = true;
      _inlineError = null;
    });

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: _selectedPeriodDays));

    final File? file = await ref.read(passportProvider.notifier).generatePassportFile(
      startDate: startDate,
      endDate: endDate,
    );

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });

      if (file != null) {
        context.push('/passport/preview', extra: file);
      } else {
        setState(() {
          _inlineError = "Report could not be generated — please try again.";
        });
      }
    }
  }
}
