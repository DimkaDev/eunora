import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'package:eunora/core/theme/app_theme.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool _isSufficient = false; // Insufficient Data by default
  int _selectedPeriodIndex = 1; // 30 days selected by default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // State Switcher (Sticky/Interactive for review)
            _buildStateSwitcher(),
            const SizedBox(height: 24),

            // Header Section
            Text(
              'Your Insights',
              style: GoogleFonts.notoSerif(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Understanding your body's rhythm.",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Time Period Selector
            _buildPeriodSelector(),
            const SizedBox(height: 24),

            // Section 1: Symptom Frequency
            _buildSymptomFrequencyCard(),
            const SizedBox(height: 24),

            // Section 2: Most Frequent Symptoms
            _buildMostFrequentSymptomsCard(),
            const SizedBox(height: 24),

            // Section 3: Severity Trend
            _buildSeverityTrendCard(),
            const SizedBox(height: 24),

            // Section 4: What Affects Your Symptoms / AI Insights
            _buildAiInsightsSection(),
            const SizedBox(height: 24),

            // Section 5: Recommendations (Only shown when sufficient data)
            if (_isSufficient) ...[
              _buildRecommendationsSection(),
              const SizedBox(height: 24),
            ],

            // Section 5b: AI Correlations (Only shown when sufficient data)
            if (_isSufficient) ...[
              _buildAiCapabilityBanner(),
              const SizedBox(height: 12),
              _buildDisclaimerBar(),
              const SizedBox(height: 20),
              _buildCorrelationsSection(),
              const SizedBox(height: 24),
            ],

            // Section 6: Menopause Passport / PDF Report
            _buildPdfReportSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget Builders
  // ---------------------------------------------------------------------------

  Widget _buildStateSwitcher() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DASHBOARD STATE',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isSufficient
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isSufficient ? 'SUFFICIENT DATA' : 'INSUFFICIENT DATA',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _isSufficient
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFBA1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isSufficient = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isSufficient ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Insufficient (Empty)',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: !_isSufficient ? FontWeight.bold : FontWeight.normal,
                          color: !_isSufficient ? Colors.white : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isSufficient = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isSufficient ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Sufficient (Active)',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: _isSufficient ? FontWeight.bold : FontWeight.normal,
                          color: _isSufficient ? Colors.white : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['7 days', '30 days', '90 days'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(periods.length, (index) {
          final isSelected = _selectedPeriodIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriodIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    periods[index],
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSymptomFrequencyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SYMPTOM FREQUENCY',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last 30 Days',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '18/30',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    'DAYS LOGGED',
                    style: GoogleFonts.manrope(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Heatmap grid simulation (4 rows x 7 cols)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 28,
            itemBuilder: (context, index) {
              // Custom heatmap color distribution
              Color color = AppTheme.surfaceContainerHighest;
              if (index % 4 == 0) {
                color = AppTheme.primary;
              } else if (index % 5 == 1) {
                color = AppTheme.primaryContainer;
              } else if (index % 3 == 2) {
                color = AppTheme.surfaceContainer;
              } else if (index % 6 == 3) {
                color = const Color(0xFFEDDDF5); // secondary-fixed
              }
              return Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Legend Bar
          Row(
            children: [
              Text(
                'FEW',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.surfaceContainerHighest,
                        Color(0xFFEDDDF5),
                        AppTheme.primary,
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MANY',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMostFrequentSymptomsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            'MOST FREQUENT SYMPTOMS',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // Symptom Row 1
          _buildSymptomBar('Hot Flashes', '18 days', 0.60, AppTheme.primary),
          const SizedBox(height: 16),
          // Symptom Row 2
          _buildSymptomBar('Sleep Issues', '12 days', 0.40, const Color(0xFF814F45)),
          const SizedBox(height: 16),
          // Symptom Row 3
          _buildSymptomBar('Mood Changes', '10 days', 0.33, const Color(0xFFD0C1D8)),
        ],
      ),
    );
  }

  Widget _buildSymptomBar(String label, String value, double factor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: factor,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityTrendCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
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
                'SEVERITY TREND',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppTheme.onSurface,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.trending_down, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '21% improvement',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom trend painter
          SizedBox(
            height: 112,
            width: double.infinity,
            child: CustomPaint(
              painter: TrendChartPainter(),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '14 days ago',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline,
                ),
              ),
              Text(
                'Today',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightsSection() {
    if (!_isSufficient) {
      // Insufficient Data state: building insights empty state card
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Glowing pulsing stars icon
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8C9E0).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primary,
                      size: 48,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8C9E0),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Your insights are building',
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Log your symptoms for 7 days and Eunora will start finding patterns. You're on day 3.",
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF7F756E),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '3 of 7 days',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryContainer,
                  ),
                ),
                Text(
                  '43%',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: 0.43,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceContainer,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryContainer),
              ),
            ),
            const SizedBox(height: 24),

            // Log Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Log today',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Sufficient Data state: active list of insights with descriptive sentences
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
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
            Text(
              'WHAT AFFECTS YOU?',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Row 1: Sleep
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDDDF5), // bg-secondary-fixed
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bedtime,
                    color: Color(0xFF211828), // on-secondary-fixed
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'On days with ',
                      children: [
                        TextSpan(
                          text: '<6h sleep',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ', severity increases by '),
                        TextSpan(
                          text: '35%',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 2: Caffeine
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.coffee,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: 'Hot flashes peak 2-4 hours after ',
                          children: [
                            TextSpan(
                              text: 'caffeine',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          height: 1.5,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 10,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'High confidence',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 3: Exercise
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDDDF5), // bg-secondary-fixed
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center, // or exercise
                    color: Color(0xFF211828),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Symptoms improve on days with ',
                      children: [
                        TextSpan(
                          text: '30+ min activity',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRecommendationsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0ECE0).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECOMMENDED FOR YOU',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem('Try evening exercises'),
          const SizedBox(height: 8),
          _buildRecommendationItem('Track water intake'),
          const SizedBox(height: 8),
          _buildRecommendationItem('Stress management tips'),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const Icon(
            Icons.north_east,
            size: 14,
            color: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPdfReportSection() {
    if (!_isSufficient) {
      // Passport needs 30 days of data card (replacing whole PDF card)
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.import_contacts,
                    color: AppTheme.outline.withOpacity(0.2),
                    size: 64,
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(
                      Icons.schedule,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Your Passport needs 30 days of data',
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "You're 18 days away. Keep logging daily and your clinical report will be ready 30 March.",
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF7F756E),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '12 of 30 days',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  '40%',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: 0.40,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceContainer,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFDAD3)),
              ),
            ),
            const SizedBox(height: 24),

            // Log Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFFFDAD3),
                  foregroundColor: const Color(0xFF341009),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Log today',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Sufficient Data state: active share doctor card
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceContainer),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFEDDDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_information,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Share with Your Doctor',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Generate a comprehensive report of your symptoms and triggers.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Text(
                  'Generate PDF Report',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Severity Trend Curve Custom Painter
// ---------------------------------------------------------------------------

class TrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          const Color(0xFFEDDDF5).withOpacity(0.8),
          const Color(0xFFEDDDF5).withOpacity(0.0),
        ],
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.85);
    
    // Map control points for smooth quadratic curves matching original design
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.625,
      size.width * 0.2,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.775,
      size.width * 0.4,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.325,
      size.width * 0.6,
      size.height * 0.375,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.425,
      size.width * 0.8,
      size.height * 0.55,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.275,
      size.width * 1.0,
      size.height * 0.3,
    );

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw coordinate dots on the curve
    final dotPaint = Paint()
      ..color = const Color(0xFF814F45)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotCoords = [
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.4, size.height * 0.5),
      Offset(size.width * 0.6, size.height * 0.375),
      Offset(size.width * 0.8, size.height * 0.55),
      Offset(size.width * 1.0, size.height * 0.3),
    ];

    for (var coord in dotCoords) {
      canvas.drawCircle(coord, 3.5, dotPaint);
      canvas.drawCircle(coord, 1.5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// AI Insights Correlations – inline widgets on AnalyticsPage
// ============================================================================

extension _CorrelationWidgets on _AnalyticsPageState {
  Widget _buildAiCapabilityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF67594E), Color(0xFF817266), Color(0xFF655A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF67594E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eunora AI has found 5 patterns in your data',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minimum 7 events required per insight · Updated weekly',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF856404).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFF856404),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'These patterns are for informational purposes only. Not medical advice. Discuss with your doctor.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF856404),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Negative – Red wine
        _buildCorrelationCard(
          emoji: '🍷',
          title: 'Red wine',
          effectText: '→ +4.2 hot flashes the next morning',
          badgeLabel: 'Strong link',
          badgeBg: const Color(0xFFFFF1F1),
          badgeColor: const Color(0xFFD32F2F),
          borderColor: const Color(0xFFF87171),
          correlationPct: 0.79,
          correlationLabel: '79% correlation',
          eventsLabel: 'Based on 12 events',
          footnote:
              'You logged red wine on 12 evenings. Next-morning hot flash count was higher 9 of those times.',
        ),
        const SizedBox(height: 16),

        // Card 2: Positive – Exercise
        _buildCorrelationCard(
          icon: Icons.directions_run,
          iconColor: const Color(0xFF388E3C),
          title: '30+ min exercise',
          effectText: '−1.4 hot flash intensity that day',
          effectColor: const Color(0xFF388E3C),
          badgeLabel: 'Protective factor',
          badgeBg: const Color(0xFFF0FFF4),
          badgeColor: const Color(0xFF2E7D32),
          borderColor: const Color(0xFF4ADE80),
          correlationPct: 0.73,
          correlationLabel: '73% correlation',
          eventsLabel: '11 events',
          showStrikethrough: true,
        ),
        const SizedBox(height: 16),

        // Card 3: Mood – Stress
        _buildCorrelationCard(
          icon: Icons.psychology_alt,
          iconColor: const Color(0xFFF59E0B),
          title: 'High stress days',
          effectText: '→ Anxiety score +2.1 the same day',
          badgeLabel: '',
          badgeBg: Colors.transparent,
          badgeColor: Colors.transparent,
          borderColor: const Color(0xFFFBBF24),
          correlationPct: 0.68,
          correlationLabel: '68% correlation',
          eventsLabel: '9 events',
          showBadge: false,
        ),
        const SizedBox(height: 16),

        // Card 4: Building data – Coffee
        _buildBuildingDataCard(),
        const SizedBox(height: 16),

        // Card 5: Weather
        _buildCorrelationCard(
          icon: Icons.thermostat,
          iconColor: AppTheme.primary,
          title: 'Hot/humid days',
          effectText: '→ 2× more hot flashes reported',
          badgeLabel: '',
          badgeBg: Colors.transparent,
          badgeColor: Colors.transparent,
          borderColor: AppTheme.primaryContainer,
          correlationPct: 0.71,
          correlationLabel: '71%',
          eventsLabel: '8 events',
          showBadge: false,
        ),

        const SizedBox(height: 24),

        // Footer link
        Center(
          child: TextButton.icon(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF655A6E),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: Text(
              'How are these calculated?',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF655A6E),
              ),
            ),
            label: const Icon(
              Icons.arrow_forward,
              size: 16,
              color: Color(0xFF655A6E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorrelationCard({
    String? emoji,
    IconData? icon,
    Color? iconColor,
    required String title,
    required String effectText,
    Color? effectColor,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeColor,
    required Color borderColor,
    required double correlationPct,
    required String correlationLabel,
    required String eventsLabel,
    String? footnote,
    bool showBadge = true,
    bool showStrikethrough = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon/emoji + title + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (emoji != null)
                    Text(emoji, style: const TextStyle(fontSize: 28))
                  else
                    Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (showBadge && badgeLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    badgeLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Effect text
          if (showStrikethrough)
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Hot flash intensity  ',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: const Color(0xFFF87171),
                      height: 1.4,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    effectText,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: effectColor ?? AppTheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              effectText,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: effectColor ?? AppTheme.onSurface,
                height: 1.4,
              ),
            ),

          const SizedBox(height: 12),

          // Progress bar row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                correlationLabel,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.outline,
                ),
              ),
              Text(
                eventsLabel,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: correlationPct,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(borderColor),
            ),
          ),

          // Optional footnote
          if (footnote != null) ...[
            const SizedBox(height: 12),
            Text(
              footnote,
              style: GoogleFonts.notoSerif(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBuildingDataCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.coffee, color: AppTheme.outline, size: 28),
              const SizedBox(width: 12),
              Text(
                'Coffee in the morning',
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Building data…',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.outline,
                ),
              ),
              Text(
                '5 of 7 events needed',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 6 ? 3 : 0),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < 5
                        ? AppTheme.outlineVariant
                        : AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'Keep logging to unlock this insight',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.outline,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
