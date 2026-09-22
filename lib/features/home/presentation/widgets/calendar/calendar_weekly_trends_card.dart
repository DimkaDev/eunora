import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../analysis/services/weekly_trends_calculator.dart';

/// Weekly Trends card for Tracker / Calendar.
/// Displays Symptom Intensity and Sleep (hours) compared to previous week by same weekdays,
/// with 7 mini-bars (unlogged days as empty slots).
/// Tapping either card opens Trend Detail.
class CalendarWeeklyTrendsCard extends StatelessWidget {
  final WeeklyTrendsData? trendsData;
  final VoidCallback? onTapIntensity;
  final VoidCallback? onTapSleep;

  // Legacy parameters for backward compatibility with existing tests/callers
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
    this.trendsData,
    this.onTapIntensity,
    this.onTapSleep,
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
    if (trendsData != null) {
      return _buildWithTrendsData(context, trendsData!);
    }

    if (isInsufficientData) {
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
        child: _buildInProgressTrends(),
      );
    }

    // Fallback legacy display
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
      child: Column(
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
          _buildTappableTrendRow(
            title: 'Symptom Intensity',
            value: 'Avg ${averageIntensity.toStringAsFixed(1)}',
            change: intensityChangeLabel,
            isGood: isIntensityChangeGood,
            bars: intensityHeights.map((h) => h <= 0.0 ? null : h * 5.0).toList(),
            maxScale: 5.0,
            onTap: onTapIntensity,
          ),
          const Divider(height: 24, color: Color(0xFFF2EDEA)),
          _buildTappableTrendRow(
            title: 'Sleep',
            value: '${averageSleep.toStringAsFixed(1)} hrs',
            change: sleepChangeLabel,
            isGood: isSleepChangeGood,
            bars: sleepHeights.map((h) => h <= 0.0 ? null : h * 10.0).toList(),
            maxScale: 10.0,
            onTap: onTapSleep,
          ),
        ],
      ),
    );
  }

  Widget _buildWithTrendsData(BuildContext context, WeeklyTrendsData data) {
    final bool hasAnyLogs = data.currentWeekLoggedDays > 0;

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
      child: !hasAnyLogs
          ? _buildInProgressTrends()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Trends',
                      style: GoogleFonts.notoSerif(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      'Tap card for details',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: const Color(0xFF8C7D70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card 1: Symptom Intensity
                _buildTappableTrendRow(
                  title: 'Symptom Intensity',
                  value: data.hasEnoughDataForValues
                      ? data.intensityDisplay
                      : 'Not enough data',
                  change: data.intensityChangeDisplay,
                  isGood: data.isIntensityImproved,
                  bars: data.intensityMiniBars,
                  maxScale: 5.0,
                  onTap: onTapIntensity,
                ),

                const Divider(height: 24, color: Color(0xFFF2EDEA)),

                // Card 2: Sleep (hours)
                _buildTappableTrendRow(
                  title: 'Sleep',
                  value: data.hasEnoughDataForValues
                      ? data.sleepDisplay
                      : 'Not enough data',
                  change: data.sleepChangeDisplay,
                  isGood: data.isSleepImproved,
                  subtitle: data.sleepDisruptionDays > 0
                      ? 'Sleep disruption: ${data.sleepDisruptionDays} ${data.sleepDisruptionDays == 1 ? 'day' : 'days'}'
                      : null,
                  bars: data.sleepMiniBars,
                  maxScale: 12.0,
                  onTap: onTapSleep,
                ),
              ],
            ),
    );
  }

  Widget _buildTappableTrendRow({
    required String title,
    required String value,
    required String change,
    required bool? isGood,
    String? subtitle,
    required List<double?> bars,
    required double maxScale,
    VoidCallback? onTap,
  }) {
    Color changeColor = const Color(0xFF8C7D70);
    if (isGood == true) {
      changeColor = const Color(0xFF2D402D);
    } else if (isGood == false) {
      changeColor = const Color(0xFFBA1A1A);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      change,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7A6B5F),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildMiniBars(bars, maxScale),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFFB0A59A),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Seven mini-bars: unlogged days appear as empty slots (null).
  Widget _buildMiniBars(List<double?> bars, double maxScale) {
    const double barHeight = 26.0;
    const double barWidth = 4.0;

    return SizedBox(
      height: barHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars.length, (index) {
          final val = bars[index];
          final isGap = val == null;

          if (isGap) {
            // Unlogged day: empty slot placeholder
            return Container(
              width: barWidth,
              height: barHeight,
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              decoration: BoxDecoration(
                color: const Color(0xFFEBE6DF),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }

          // Logged day: vertical mini-bar scaled by value
          final fraction = (val / maxScale).clamp(0.15, 1.0);
          return Container(
            width: barWidth,
            height: barHeight * fraction,
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            decoration: BoxDecoration(
              color: const Color(0xFF2D402D),
              borderRadius: BorderRadius.circular(2),
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
                'Data is still being collected. Log at least 2 days this week to see weekly trends.',
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
