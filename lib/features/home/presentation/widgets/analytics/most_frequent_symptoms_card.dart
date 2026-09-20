import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';

class MostFrequentSymptomsCard extends StatelessWidget {
  final List<DailyLog> filteredLogs;

  const MostFrequentSymptomsCard({
    super.key,
    required this.filteredLogs,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, int> symptomDays = {};
    final Map<String, double> symptomIntensitySum = {};
    final Map<String, String> symptomNames = {};

    for (final log in filteredLogs) {
      final Set<String> symptomsLoggedToday = {};
      for (final s in log.symptoms) {
        final id = s.symptom.id;
        symptomsLoggedToday.add(id);
        symptomNames[id] = s.symptom.name;
        final intensity = s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
        symptomIntensitySum[id] = (symptomIntensitySum[id] ?? 0.0) + intensity;
      }

      for (final id in symptomsLoggedToday) {
        symptomDays[id] = (symptomDays[id] ?? 0) + 1;
      }
    }

    final List<Map<String, dynamic>> ranks = [];
    symptomDays.forEach((id, days) {
      final avgIntensity = symptomIntensitySum[id]! / days;
      ranks.add({
        'id': id,
        'name': symptomNames[id] ?? id,
        'days_logged': days,
        'avg_intensity': avgIntensity,
      });
    });

    // Sort: days_logged DESC, tie-break avg_intensity DESC
    ranks.sort((a, b) {
      final int daysCompare = (b['days_logged'] as int).compareTo(a['days_logged'] as int);
      if (daysCompare != 0) return daysCompare;
      return (b['avg_intensity'] as double).compareTo(a['avg_intensity'] as double);
    });

    final top5 = ranks.take(5).toList();
    final topDaysCount = top5.isNotEmpty ? (top5.first['days_logged'] as int) : 1;

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

          if (top5.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: AppTheme.outline,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No data recorded for this period',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log your daily symptoms to track frequency.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(top5.length, (index) {
              final item = top5[index];
              final String name = item['name'] as String;
              final int days = item['days_logged'] as int;
              final double factor = days / topDaysCount;

              Color color = AppTheme.primary;
              if (index == 1) {
                color = const Color(0xFF814F45);
              } else if (index == 2) {
                color = const Color(0xFFD0C1D8);
              } else if (index >= 3) {
                color = AppTheme.outline;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: index == top5.length - 1 ? 0 : 16),
                child: _buildSymptomBar(
                  name,
                  '$days day${days == 1 ? '' : 's'}',
                  factor,
                  color,
                ),
              );
            }),
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
              widthFactor: factor.clamp(0.01, 1.0),
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
}
