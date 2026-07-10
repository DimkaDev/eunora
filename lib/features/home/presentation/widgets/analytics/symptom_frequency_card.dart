import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';

class SymptomFrequencyCard extends StatelessWidget {
  final List<DailyLog> allLogs;
  final double q1;
  final double q2;

  const SymptomFrequencyCard({
    super.key,
    required this.allLogs,
    required this.q1,
    required this.q2,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed 28-day window (4 rows x 7 cols)
    final DateTime today = DateTime.now();
    final DateTime startDate = today.subtract(const Duration(days: 27));

    final Map<String, double?> dailyLoads = {};
    for (int i = 0; i < 28; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      dailyLoads[dateKey] = null;
    }

    int loggedDaysCount = 0;
    for (final log in allLogs) {
      if (log.date.isAfter(startDate.subtract(const Duration(days: 1))) && log.date.isBefore(today.add(const Duration(days: 1)))) {
        final dateKey = "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
        if (log.symptoms.isNotEmpty) {
          double sumIntensity = 0.0;
          for (final s in log.symptoms) {
            sumIntensity += s.intensity?.toDouble() ?? (s.severity == 'Mild' ? 1.0 : s.severity == 'Moderate' ? 3.0 : 5.0);
          }
          dailyLoads[dateKey] = sumIntensity / log.symptoms.length;
        } else {
          dailyLoads[dateKey] = 0.0;
        }
        loggedDaysCount++;
      }
    }

    const periodLabel = "Last 28 Days";

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
                    periodLabel,
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
                    '$loggedDaysCount/28',
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

          // Heatmap grid (4 rows x 7 cols)
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
              final cellDate = startDate.add(Duration(days: index));
              final cellKey = "${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}";
              final dailyLoad = dailyLoads[cellKey];

              Color color = const Color(0xFFF7F5F0); // Default cream no-data
              Border? border = Border.all(color: AppTheme.outlineVariant.withOpacity(0.3));

              if (dailyLoad != null) {
                border = null;
                if (dailyLoad <= q1) {
                  color = const Color(0xFFD8C9E0).withOpacity(0.4); // Soft lavender 40%
                } else if (dailyLoad <= q2) {
                  color = const Color(0xFFE8A89B).withOpacity(0.55); // Peachy Rose 55%
                } else {
                  color = const Color(0xFFE8A89B); // Peachy Rose 100%
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: color,
                  border: border,
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
                        Color(0xFFD8C9E0),
                        Color(0xFFE8A89B),
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
}
