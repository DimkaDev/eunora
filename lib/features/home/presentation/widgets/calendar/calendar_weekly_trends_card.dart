import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class CalendarWeeklyTrendsCard extends StatelessWidget {
  final double averageIntensity;
  final double averageSleep;
  final List<double> intensityHeights;
  final List<double> sleepHeights;
  final String intensityChangeLabel;
  final String sleepChangeLabel;
  final bool isIntensityChangeGood;
  final bool isSleepChangeGood;
  final bool isInsufficientData;

  const CalendarWeeklyTrendsCard({
    super.key,
    this.averageIntensity = 4.2,
    this.averageSleep = 6.5,
    this.intensityHeights = const [0.4, 0.6, 0.8, 0.3, 0.5, 0.45, 0.0],
    this.sleepHeights = const [0.7, 0.65, 0.9, 0.55, 0.6, 0.4, 0.0],
    this.intensityChangeLabel = '↓ 12%',
    this.sleepChangeLabel = '↓ 4%',
    this.isIntensityChangeGood = true,
    this.isSleepChangeGood = false,
    this.isInsufficientData = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: isInsufficientData
          ? _buildInProgressTrends()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Text(
            'Weekly Trends',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendRow(
            title: 'Symptom Intensity',
            value: 'Avg ${averageIntensity.toStringAsFixed(1)}',
            change: intensityChangeLabel,
            isGood: isIntensityChangeGood,
            sparklineHeights: intensityHeights,
          ),
          const Divider(height: 24, color: Color(0xFFF2EDEA)),
          _buildTrendRow(
            title: 'Sleep Quality',
            value: '${averageSleep.toStringAsFixed(1)} hrs',
            change: sleepChangeLabel,
            isGood: isSleepChangeGood,
            sparklineHeights: sleepHeights,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendRow({
    required String title,
    required String value,
    required String change,
    required bool isGood,
    required List<double> sparklineHeights,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    change,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isGood ? Colors.green[600] : Colors.red[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildSparkline(sparklineHeights),
        ],
      ),
    );
  }

  Widget _buildSparkline(List<double> heights) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(heights.length, (index) {
          final h = heights[index];
          // Sparkline highlights active column (index 5)
          final isHighlighted = index == 5;
          return Container(
            width: 4,
            height: 24 * h,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: h == 0
                  ? Colors.transparent
                  : (isHighlighted ? AppTheme.primary : const Color(0xFFD0C1D8)),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInProgressTrends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Trends',
          style: GoogleFonts.notoSerif(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF9B8B7E),
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'IN PROGRESS',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppTheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log at least 3 days this week to generate weekly trends.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
