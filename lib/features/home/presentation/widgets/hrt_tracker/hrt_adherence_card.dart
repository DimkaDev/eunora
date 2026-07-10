import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';

class HrtAdherenceCard extends ConsumerWidget {
  final DateTime focusedMonth;
  final Map<int, DailyLog> monthlyLogs;

  const HrtAdherenceCard({
    super.key,
    required this.focusedMonth,
    required this.monthlyLogs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalDays = DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);

    final today = DateTime.now();
    final isCurrentMonth = today.year == focusedMonth.year && today.month == focusedMonth.month;
    final limitDay = isCurrentMonth ? today.day : totalDays;

    int totalScheduled = 0;
    int totalLogged = 0;

    for (int day = 1; day <= limitDay; day++) {
      final log = monthlyLogs[day];
      if (log != null) {
        totalScheduled += log.hrtIntakes.length;
        totalLogged += log.hrtIntakes.where((h) => h.isTaken).length;
      }
    }

    int rate = 100;
    if (totalScheduled > 0) {
      rate = ((totalLogged / totalScheduled) * 100).round();
    } else {
      final hasMeds = ref.read(medicationsProvider).medications.isNotEmpty;
      rate = hasMeds ? 100 : 0;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF2D5A3E).withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up,
              color: Color(0xFF2D5A3E),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adherence this month: $rate%',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rate >= 80
                      ? "You're staying consistent! Keep it up."
                      : "Try checking your reminders to log doses daily.",
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF2D5A3E).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.analytics_outlined,
            color: const Color(0xFF2D5A3E).withOpacity(0.3),
            size: 22,
          ),
        ],
      ),
    );
  }
}
