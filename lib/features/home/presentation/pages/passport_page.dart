import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class PassportPage extends StatefulWidget {
  const PassportPage({super.key});

  @override
  State<PassportPage> createState() => _PassportPageState();
}

class _PassportPageState extends State<PassportPage> {
  int _selectedPeriodDays = 60; // default is 60 days active in stitch design

  // Map to track toggled sections
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
    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6), // bg-surface
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReadinessCard(),
                  const SizedBox(height: 32),
                  _buildReportPeriodSection(),
                  const SizedBox(height: 32),
                  _buildIncludeSections(),
                  const SizedBox(height: 32),
                  _buildPreviewSection(),
                  const SizedBox(height: 32),
                  _buildGenerateButtonSection(),
                  const SizedBox(height: 32),
                  _buildSpecialistInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF8F6).withOpacity(0.85),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFE7E1DF), // outline-variant / 15
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Menopause Passport',
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {},
                icon: const Icon(
                  Icons.history,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {},
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest, // white
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Row(
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFA8D5BA), // success-soft
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'READY TO GENERATE',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: const Color(0xFF436E52),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '30 days of data',
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '13 Mar – 13 Apr 2026',
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
                  value: 1.0,
                  strokeWidth: 4.5,
                  backgroundColor: AppTheme.surfaceContainer,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA8D5BA)),
                ),
              ),
              Text(
                '30/30',
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
                      color: Colors.black.withOpacity(0.08),
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

  Widget _buildIncludeSections() {
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
                      color: const Color(0xFF683A31), // #683a31
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

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            GestureDetector(
              onTap: () {},
              child: Text(
                'Full screen ›',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
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
                  color: Colors.black.withOpacity(0.12),
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
                                  'Claire Thompson',
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
                              'GENERATED\nAPR 13, 2026',
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
                                    color: AppTheme.outlineVariant.withOpacity(0.3),
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
                                    color: AppTheme.outlineVariant.withOpacity(0.3),
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
                                  color: AppTheme.outlineVariant.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 3,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.outlineVariant.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 3,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.outlineVariant.withOpacity(0.5),
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
        color: isDark ? AppTheme.primary : AppTheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }

  Widget _buildGenerateButtonSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF67594E), Color(0xFF817266)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.description, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Generate Passport PDF',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Last generated: 2 Apr 2026',
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () {},
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

  Widget _buildSpecialistInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryFixed, // #f2dfd0 warm sand
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.medical_services_outlined,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Designed for your gynaecologist',
                  style: GoogleFonts.notoSerif(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This comprehensive report formats your data into clinical standards used by specialists to accelerate diagnosis and adjust HRT dosages precisely.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.onSurfaceVariant,
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
