import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/widgets/app_card.dart';
import 'package:eunora/core/services/premium_guard_provider.dart';
import 'package:eunora/features/insights/models/insight_result.dart';
import 'package:eunora/features/insights/providers/insights_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);
    final isPremium = ref.watch(premiumGuardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFEF8F6),
      appBar: AppBar(
        title: Text(
          'AI Insights',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: insightsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
            error: (err, stack) {
              debugPrint("Error loading insights: $err\n$stack");
              // Fallback to empty state UI, showing SnackBar rather than crashing
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Something went wrong — your data is safe',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFFBA1A1A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              });
              return _buildEmptyState(null);
            },
            data: (insights) {
              if (insights.isEmpty) {
                return _buildEmptyState(insights);
              }

              // Separate and sort by type
              final doseChanges = insights.where((i) => i.type == InsightType.doseChange).toList();
              final triggers = insights.where((i) => i.type == InsightType.trigger).toList();
              final progress = insights.where((i) => i.type == InsightType.progress).toList();

              // Dose changes first, then triggers (already sorted by percent by engine), then progress
              final List<InsightResult> sortedList = [
                ...doseChanges,
                ...triggers,
                ...progress,
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Persistent Banner Disclaimer
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EDEA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Insights are generated automatically using clinical statistical correlations from your logged symptoms and triggers. These are not medical diagnoses and should be discussed with your physician.",
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF3A3A3A).withOpacity(0.85),
                        height: 1.45,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: sortedList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = sortedList[index];
                        return _buildInsightCard(context, ref, item, isPremium);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(List<InsightResult>? insights) {
    String message = "Log a few days of symptoms and we'll start finding your patterns.";
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Color(0xFF9B8B7E),
            ),
            const SizedBox(height: 16),
            Text(
              "Building your insights",
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, WidgetRef ref, InsightResult item, bool isPremium) {
    final bool needsPremium = (item.type == InsightType.trigger || item.type == InsightType.doseChange) && !isPremium;

    // Define accent colors per spec
    Color accentColor = const Color(0xFFD8C9E0); // Progress/building default
    if (!needsPremium) {
      if (item.direction == 'negative') {
        accentColor = const Color(0xFFA8D5BA); // Success Soft Green (improves)
      } else if (item.direction == 'positive') {
        accentColor = const Color(0xFFE8A89B); // Peachy Rose (worsens)
      }
    }

    return AppCard(
      onTap: needsPremium
          ? () => context.push('/premium-upgrade')
          : (item.type == InsightType.progress
              ? null
              : () => context.push('/insights/${item.id}')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  item.type == InsightType.doseChange
                      ? 'HRT IMPACT'
                      : (item.type == InsightType.trigger ? 'CORRELATION' : 'BUILDING'),
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: item.direction == 'negative' && !needsPremium
                        ? const Color(0xFF2E5E4E)
                        : (item.direction == 'positive' && !needsPremium
                            ? const Color(0xFF6E3E3E)
                            : const Color(0xFF4C3E56)),
                  ),
                ),
              ),
              if (needsPremium)
                const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: Color(0xFF817266),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (needsPremium) ...[
            Text(
              'Unlock Premium Insights',
              style: GoogleFonts.notoSerif(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'AI trigger correlations and HRT dose analyses require a Premium subscription.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/premium-upgrade'),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: const BorderSide(color: AppTheme.primary),
              ),
              child: Text(
                'Upgrade to Premium',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ] else ...[
            Text(
              item.label,
              style: GoogleFonts.notoSerif(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            if (item.disclaimer != null && item.disclaimer!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                item.disclaimer!,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: const Color(0xFF3A3A3A).withOpacity(0.65),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
