import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/services/premium_guard_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';
import 'package:eunora/features/home/presentation/widgets/passport/passport_specialist_card.dart';
import 'package:eunora/features/passport/providers/passport_provider.dart';
import 'package:eunora/features/passport/providers/passport_screen_controller.dart';

class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key});

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends ConsumerState<PassportScreen> {
  int _selectedPeriodDays = 30; // default 30 days
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
    final profile = ref.watch(onboardingProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // bg-surface
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
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menopause Passport',
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Generate a PDF summary of your health data.",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildReadinessCard(eligibility),
                  const SizedBox(height: 32),
                  _buildReportPeriodSection(),
                  const SizedBox(height: 32),
                  _buildIncludeSections(isPremium),
                  const SizedBox(height: 32),
                  _buildPreviewSection(profile),
                  const SizedBox(height: 32),
                  if (_inlineError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(16),
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
                  _buildGenerateButtonSection(eligibility, isPremium),
                  const SizedBox(height: 32),
                  const PassportSpecialistCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReadinessCard(PassportEligibility eligibility) {
    final int targetDays = _selectedPeriodDays;
    final bool isReady = eligibility.totalDays >= targetDays;
    final int daysRemaining = max(0, targetDays - eligibility.totalDays);
    final double progress = (eligibility.totalDays / targetDays.toDouble()).clamp(0.0, 1.0);
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: targetDays));
    final dateRangeStr = "${DateFormat('d MMM').format(startDate)} – ${DateFormat('d MMM yyyy').format(now)}";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest, // white
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isReady ? const Color(0xFFA8D5BA) : const Color(0xFFE89A58),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isReady ? 'READY TO GENERATE' : 'DATA COLLECTION IN PROGRESS',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: isReady ? const Color(0xFF436E52) : const Color(0xFF9A5820),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isReady
                          ? '$targetDays days of data'
                          : '$daysRemaining days to go',
                      style: GoogleFonts.notoSerif(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isReady
                          ? dateRangeStr
                          : '${eligibility.totalDays} / $targetDays logged',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4.5,
                      backgroundColor: AppTheme.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isReady ? const Color(0xFFA8D5BA) : const Color(0xFFE89A58),
                      ),
                    ),
                  ),
                  Text(
                    '${min(eligibility.totalDays, targetDays)}/$targetDays',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isReady) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFF2EDEA),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA8D5BA)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REPORT PERIOD',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: const Color(0xFF9B8B7E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              _buildPeriodButton(30, '30 days'),
              _buildPeriodButton(60, '60 days'),
              _buildPeriodButton(90, '90 days'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(int days, String label) {
    final isSelected = _selectedPeriodDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriodDays = days),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Text(
                  '✓',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncludeSections(bool isPremium) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INCLUDE SECTIONS',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: const Color(0xFF9B8B7E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              _buildSectionToggleRow('Patient profile', const Color(0xFFD8C9E0)),
              const SizedBox(height: 2),
              _buildSectionToggleRow('Symptom statistics', const Color(0xFFA8D5BA)),
              const SizedBox(height: 2),
              _buildSectionToggleRow('Trend charts', const Color(0xFF814F45)),
              const SizedBox(height: 2),
              _buildSectionToggleRow('AI patterns & triggers', const Color(0xFF655A6E), isPremium: true),
              const SizedBox(height: 2),
              _buildSectionToggleRow('HRT history & impact', const Color(0xFF7F756E), isPremium: true),
              const SizedBox(height: 2),
              _buildSectionToggleRow('Full log table', const Color(0xFFDED9D7)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionToggleRow(String title, Color bulletColor, {bool isPremium = false}) {
    final isEnabled = _sections[title] ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest, // white row
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: bulletColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              if (isPremium) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryFixed, // #ffdad3 peachy rose
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: GoogleFonts.manrope(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF683A31),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _sections[title] = !isEnabled;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: isEnabled ? AppTheme.primary : const Color(0xFFE2DDD9),
              ),
              padding: const EdgeInsets.all(2),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(dynamic profile) {
    String displayName = 'Sarah Thompson';
    if (profile != null) {
      final String email = profile.email?.toString() ?? '';
      if (email.isNotEmpty) {
        final name = email.split('@').first;
        if (name.isNotEmpty) {
          displayName = name[0].toUpperCase() + name.substring(1);
        }
      }
    }

    final String dateString = DateFormat('MMM d, yyyy').format(DateTime.now()).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREVIEW',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: const Color(0xFF9B8B7E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 380,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E1DE), // soft stone background
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header band
                Container(
                  height: 24,
                  width: double.infinity,
                  color: AppTheme.primary,
                  alignment: Alignment.center,
                  child: Text(
                    'MENOPAUSE PASSPORT · EUNORA',
                    style: GoogleFonts.manrope(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Eunora Health',
                                  style: GoogleFonts.manrope(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayName,
                                  style: GoogleFonts.notoSerif(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Patient Record: #MS-9921',
                                  style: GoogleFonts.manrope(
                                    fontSize: 7,
                                    color: AppTheme.onSurfaceVariant,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'GENERATED\n$dateString',
                              style: GoogleFonts.manrope(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Statistics Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: CircularProgressIndicator(
                                        value: 0.88,
                                        strokeWidth: 3.5,
                                        backgroundColor: AppTheme.surfaceContainer,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA8D5BA)),
                                      ),
                                    ),
                                    Text(
                                      '88%',
                                      style: GoogleFonts.manrope(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 72,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 4,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 4,
                                      width: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 4,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Weekly trend simulation
                        Container(
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildPreviewBar(8, false),
                              _buildPreviewBar(14, false),
                              _buildPreviewBar(24, true),
                              _buildPreviewBar(18, false),
                              _buildPreviewBar(10, false),
                              _buildPreviewBar(16, true),
                              _buildPreviewBar(30, true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Simulated lines
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 3,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 3,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 3,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ],
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
      ],
    );
  }

  Widget _buildPreviewBar(double height, bool isDark) {
    return Container(
      width: 6,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }

  Widget _buildGenerateButtonSection(PassportEligibility eligibility, bool isPremium) {
    final int targetDays = _selectedPeriodDays;
    final bool isReady = eligibility.totalDays >= targetDays;
    final int daysRemaining = max(0, targetDays - eligibility.totalDays);

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: isReady
                ? const LinearGradient(
                    colors: [Color(0xFF67594E), Color(0xFF817266)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isReady ? null : const Color(0xFFE5E1DE),
            borderRadius: BorderRadius.circular(24),
            boxShadow: isReady
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: _isGenerating
                ? null
                : () {
                    if (!isReady) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Log at least $targetDays days of data to generate this passport ($daysRemaining days remaining).',
                            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppTheme.primary,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    _handleGenerate(isPremium);
                  },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: isReady ? Colors.white : const Color(0xFF8C827A),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
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
                      Icon(
                        isReady ? Icons.description_outlined : Icons.lock_outline,
                        size: 20,
                        color: isReady ? Colors.white : const Color(0xFF8C827A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Generate Passport PDF',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isReady ? Colors.white : const Color(0xFF8C827A),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isReady
              ? 'Last generated: ${DateFormat('d MMM yyyy').format(DateTime.now().subtract(const Duration(days: 6)))}'
              : 'Complete $targetDays days of logging to unlock ($daysRemaining days remaining)',
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _showPreviousReportsBottomSheet,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'View previous ›',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showPreviousReportsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F5F0),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Previous Passports',
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a previously generated report to view or share.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _buildPreviousReportItem('Passport - March 2026', 'Generated on Apr 2, 2026'),
              const Divider(color: Color(0xFFE7E1DF), height: 1),
              _buildPreviousReportItem('Passport - February 2026', 'Generated on Mar 1, 2026'),
              const Divider(color: Color(0xFFE7E1DF), height: 1),
              _buildPreviousReportItem('Passport - January 2026', 'Generated on Feb 1, 2026'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviousReportItem(String title, String subtitle) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        final isPremium = ref.read(premiumGuardProvider);
        if (!isPremium) {
          context.push('/paywall');
          return;
        }
        await _handleGenerate(isPremium);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.share_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGenerate(bool isPremium) async {
    if (!isPremium) {
      context.push('/paywall');
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

