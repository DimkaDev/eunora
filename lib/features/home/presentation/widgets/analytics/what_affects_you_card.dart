import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/analysis/domain/models/analysis_period.dart';
import 'package:eunora/features/analysis/domain/models/pattern_result.dart';

/// Section 4: "What Affects You?" Card
/// Shows top 3 non-HRT factors (triggers, protective habits, environment, and sleep if trusted).
class WhatAffectsYouCard extends StatelessWidget {
  final PatternEngineResult patternResult;
  final AnalysisPeriod selectedPeriod;
  final bool isSleepTrusted;
  final int loggedDaysCount;
  final bool isPremium;
  final VoidCallback? onSeeAllEffects;

  const WhatAffectsYouCard({
    super.key,
    required this.patternResult,
    required this.selectedPeriod,
    this.isSleepTrusted = true,
    this.loggedDaysCount = 0,
    this.isPremium = true,
    this.onSeeAllEffects,
  });

  bool _isEnvironmentTrigger(String id, String name) {
    final cleanId = id.toLowerCase();
    final cleanName = name.toLowerCase();
    return cleanId.contains('weather') ||
        cleanId.contains('environment') ||
        cleanName.contains('weather') ||
        cleanName.contains('temperature') ||
        cleanName.contains('environment') ||
        cleanName.contains('humidity');
  }

  bool _isSleepTrigger(String id, String name) {
    final cleanId = id.toLowerCase();
    final cleanName = name.toLowerCase();
    return cleanId.contains('sleep') ||
        cleanId.contains('insomnia') ||
        cleanId.contains('waking') ||
        cleanName.contains('sleep');
  }

  IconData _getIconForTrigger(String id, String name) {
    final cleanId = id.toLowerCase();
    final cleanName = name.toLowerCase();

    if (cleanId.contains('caffeine') || cleanId.contains('coffee') || cleanName.contains('coffee')) {
      return Icons.coffee;
    }
    if (cleanId.contains('alcohol') || cleanId.contains('wine') || cleanName.contains('alcohol') || cleanName.contains('wine')) {
      return Icons.wine_bar;
    }
    if (cleanId.contains('stress') || cleanName.contains('stress')) {
      return Icons.psychology;
    }
    if (cleanId.contains('exercise') || cleanName.contains('exercise') || cleanName.contains('walk')) {
      return Icons.fitness_center;
    }
    if (_isEnvironmentTrigger(cleanId, cleanName)) {
      return Icons.thermostat;
    }
    if (_isSleepTrigger(cleanId, cleanName)) {
      return Icons.bedtime;
    }
    return Icons.auto_awesome;
  }

  Color _getIconBg(String id, String name) {
    final cleanId = id.toLowerCase();
    final cleanName = name.toLowerCase();

    if (cleanId.contains('caffeine') || cleanId.contains('coffee') || cleanName.contains('coffee')) {
      return const Color(0xFFEFEBE9);
    }
    if (cleanId.contains('alcohol') || cleanId.contains('wine') || cleanName.contains('alcohol') || cleanName.contains('wine')) {
      return const Color(0xFFFFEBEE);
    }
    if (cleanId.contains('stress') || cleanName.contains('stress')) {
      return const Color(0xFFFFF3E0);
    }
    if (cleanId.contains('exercise') || cleanName.contains('exercise')) {
      return const Color(0xFFE8F5E9);
    }
    if (_isEnvironmentTrigger(cleanId, cleanName)) {
      return const Color(0xFFE1F5FE);
    }
    if (_isSleepTrigger(cleanId, cleanName)) {
      return const Color(0xFFEDE7F6);
    }
    return const Color(0xFFEDDDF5);
  }

  Color _getIconColor(String id, String name) {
    final cleanId = id.toLowerCase();
    final cleanName = name.toLowerCase();

    if (cleanId.contains('caffeine') || cleanId.contains('coffee') || cleanName.contains('coffee')) {
      return const Color(0xFF5D4037);
    }
    if (cleanId.contains('alcohol') || cleanId.contains('wine') || cleanName.contains('alcohol') || cleanName.contains('wine')) {
      return const Color(0xFFC2185B);
    }
    if (cleanId.contains('stress') || cleanName.contains('stress')) {
      return const Color(0xFFE65100);
    }
    if (cleanId.contains('exercise') || cleanName.contains('exercise')) {
      return const Color(0xFF2E7D32);
    }
    if (_isEnvironmentTrigger(cleanId, cleanName)) {
      return const Color(0xFF0288D1);
    }
    if (_isSleepTrigger(cleanId, cleanName)) {
      return const Color(0xFF512DA8);
    }
    return const Color(0xFF211828);
  }

  @override
  Widget build(BuildContext context) {
    // Filter displayable patterns:
    // 1. Non-HRT (patterns from PatternEngine are all lifestyle/environmental triggers, never HRT)
    // 2. If sleep trust gate fails, suppress sleep-related patterns per SD-6
    final displayable = patternResult.patterns.where((p) {
      if (!isSleepTrusted &&
          (_isSleepTrigger(p.triggerId, p.triggerDisplayName) ||
              _isSleepTrigger(p.outcomeId, p.outcomeDisplayName))) {
        return false;
      }
      return true;
    }).take(3).toList();

    // Window label: labeled when different from selected period or clamped
    // (e.g. 7 days selected -> analysis window is 30 days -> "Based on last 30 days")
    String? windowNoticeText;
    if (selectedPeriod == AnalysisPeriod.days7) {
      windowNoticeText = 'Based on last 30 days';
    } else if (patternResult.windowNotice != null) {
      windowNoticeText = patternResult.windowNotice;
    }

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
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
                    if (windowNoticeText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        windowNoticeText,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  if (onSeeAllEffects != null) {
                    onSeeAllEffects!();
                  } else {
                    context.push('/insights');
                  }
                },
                child: Text(
                  'See all effects',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (displayable.isEmpty)
            _buildEmptyState(context)
          else
            ...List.generate(displayable.length, (index) {
              final pattern = displayable[index];
              final bool needsLock = !isPremium;

              final icon = _getIconForTrigger(pattern.triggerId, pattern.triggerDisplayName);
              final iconBg = _getIconBg(pattern.triggerId, pattern.triggerDisplayName);
              final iconColor = _getIconColor(pattern.triggerId, pattern.triggerDisplayName);

              final bool isEnv = _isEnvironmentTrigger(pattern.triggerId, pattern.triggerDisplayName);
              final bool isProtective = pattern.type == PatternType.protective;

              final String categoryChipLabel = isEnv
                  ? 'Environment'
                  : isProtective
                      ? 'Protective'
                      : 'Trigger';

              final Color chipBg = isEnv
                  ? const Color(0xFFE1F5FE)
                  : isProtective
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFBE9E7);

              final Color chipColor = isEnv
                  ? const Color(0xFF0288D1)
                  : isProtective
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFD84315);

              final String effectPhrase = isProtective
                  ? '${pattern.outcomeDisplayName} tends to be milder ${pattern.lag.displayText}'
                  : '${pattern.outcomeDisplayName} tends to be stronger ${pattern.lag.displayText}';

              return Padding(
                padding: EdgeInsets.only(bottom: index == displayable.length - 1 ? 0 : 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                pattern.triggerDisplayName,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Category chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: chipBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  categoryChipLabel,
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: chipColor,
                                  ),
                                ),
                              ),
                              if (pattern.confidence.isHigh && !needsLock) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'High confidence',
                                    style: GoogleFonts.manrope(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (needsLock)
                            GestureDetector(
                              onTap: () => context.push('/premium-upgrade'),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_outline, size: 12, color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Unlock to see impact',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              effectPhrase,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: isProtective ? const Color(0xFF2E7D32) : AppTheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // SD-10: Three kinds of empty
    final nearest = patternResult.buildingItems.isNotEmpty
        ? patternResult.buildingItems.first
        : null;

    if (nearest != null || patternResult.emptyStateType == SD10EmptyType.notEnoughData) {
      final triggerName = nearest?.triggerDisplayName ?? 'Logging';
      final currentEvents = nearest?.eventsCount ?? loggedDaysCount;
      final targetEvents = nearest?.targetCount ?? 7;
      final progressFraction = (currentEvents / targetEvents).clamp(0.0, 1.0);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INSUFFICIENT DATA',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppTheme.outline,
                  ),
                ),
                Text(
                  '$triggerName · $currentEvents of $targetEvents events',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D402D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressFraction,
                minHeight: 6,
                backgroundColor: const Color(0xFFEBE6DF),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D402D)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Personal patterns unlock once at least $targetEvents paired events are recorded.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    } else if (patternResult.emptyStateType == SD10EmptyType.notEnoughVariety) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          patternResult.emptyStateMessage ?? 'We need a few days without this trigger to compare.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      );
    } else {
      // SD10EmptyType.nothingNotable
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          patternResult.emptyStateMessage ?? 'No clear patterns yet — we keep checking as you log.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      );
    }
  }
}
