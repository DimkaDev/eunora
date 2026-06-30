import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' show ImageFilter;
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/widgets/app_card.dart';
import 'package:eunora/core/services/premium_guard_provider.dart';
import 'package:eunora/features/insights/models/insight_result.dart';
import 'package:eunora/features/insights/providers/insights_provider.dart';

class InsightTeaserCard extends ConsumerWidget {
  const InsightTeaserCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);
    final isPremium = ref.watch(premiumGuardProvider);

    return insightsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (insights) {
        // Filter displayable trigger / doseChange insights
        final displayable = insights.where((i) => i.type == InsightType.trigger || i.type == InsightType.doseChange).toList();
        if (displayable.isEmpty) {
          return const SizedBox.shrink();
        }

        final topInsight = displayable.first;
        final bool isDoseChange = topInsight.type == InsightType.doseChange;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDDDF5),
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                    ),
                    child: Text(
                      'TOP INSIGHT',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: const Color(0xFF211828),
                      ),
                    ),
                  ),
                  if (!isPremium)
                    const Icon(
                      Icons.lock,
                      size: 16,
                      color: Color(0xFF655A6E),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (!isPremium) ...[
                // Locked Teaser State for Free users
                Text(
                  'Potential Symptom Correlative Identified',
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D1B1A),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: 0.35,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                    child: Text(
                      'Caffeine is followed by a significant increase in hot flash frequency...',
                      style: GoogleFonts.notoSerif(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF1D1B1A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => context.push('/premium-upgrade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Unlock Premium Insights',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Unlocked State for Premium users
                Text(
                  topInsight.label,
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D1B1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/insights'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'See all insights ›',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    if (topInsight.correlationPercent != null)
                      Text(
                        'Strength: ${topInsight.correlationPercent}%',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
