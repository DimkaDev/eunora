import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/analysis/domain/models/home_insight.dart';

enum InsightType {
  weekly,
  daily,
  highSeverity,
}

class InsightCard extends StatefulWidget {
  final HomeInsightCardData? dailyInsight;
  final HomeInsightCardData? weeklyInsight;
  final HomeInsightCardData? insightData;
  final HighSeverityAlertData? alertData;
  final void Function(HomeInsightCardData data)? onViewTrendDetail;

  final InsightType? type;
  final bool isInsufficientData;

  const InsightCard({
    super.key,
    this.dailyInsight,
    this.weeklyInsight,
    this.insightData,
    this.alertData,
    this.onViewTrendDetail,
    this.type,
    this.isInsufficientData = false,
  });

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  bool _showWeekly = false;

  @override
  Widget build(BuildContext context) {
    // If high severity alert is active, show the alert banner above the insight card
    final Widget? alertBanner = (widget.alertData != null && widget.alertData!.isActive)
        ? _buildHighSeverityAlertBanner(widget.alertData!)
        : null;

    final HomeInsightCardData? activeData = widget.insightData ??
        (_showWeekly ? (widget.weeklyInsight ?? widget.dailyInsight) : (widget.dailyInsight ?? widget.weeklyInsight));

    Widget cardContent;
    if (activeData != null) {
      cardContent = _buildDynamicInsight(context, activeData);
    } else if (widget.isInsufficientData) {
      cardContent = _buildInProgressInsight();
    } else {
      switch (widget.type ?? InsightType.daily) {
        case InsightType.weekly:
          cardContent = _buildWeeklyInsight();
          break;
        case InsightType.daily:
          cardContent = _buildDailyInsight();
          break;
        case InsightType.highSeverity:
          cardContent = _buildHighSeverityInsight();
          break;
      }
    }

    if (alertBanner != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          alertBanner,
          const SizedBox(height: 16),
          cardContent,
        ],
      );
    }

    return cardContent;
  }

  /// High Severity Alert Banner per Task 4 Section E3.
  Widget _buildHighSeverityAlertBanner(HighSeverityAlertData alert) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8A89B),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8A89B).withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -24,
                child: IgnorePointer(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.alertMessage,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (alert.showProactiveTips) ...[
          const SizedBox(height: 16),
          _buildProactiveCareCard(),
        ],
      ],
    );
  }

  Widget _buildProactiveCareCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8A89B).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Proactive Care Insight',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF67594E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ACTION RECOMMENDED',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: const Color(0xFFD47B6A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              text: 'To help manage the recent spike in severe ',
              children: [
                TextSpan(
                  text: 'Hot Flashes',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF67594E),
                  ),
                ),
                const TextSpan(
                    text:
                        ', try lowering your bedroom temperature to 65°F at night and wearing breathable, moisture-wicking layers.'),
              ],
            ),
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF817266),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCareGridItem('RECOMMENDED', 'Paced Breathing'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCareGridItem('HYDRATION GOAL', '+2 Glasses/Day'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a dynamic insight card driven by [HomeInsightCardData].
  Widget _buildDynamicInsight(BuildContext context, HomeInsightCardData data) {
    final Color bgColor;
    final Color borderColor;
    final Color tagTextColor;
    final Color titleColor;
    final Color headlineColor;
    final Color actionColor;

    switch (data.tag) {
      case HomeInsightTag.positiveTrend:
        bgColor = const Color(0xFFE8F0E8);
        borderColor = const Color(0xFFDCEDDC);
        tagTextColor = const Color(0xFF2D402D);
        titleColor = const Color(0xFF2D402D);
        headlineColor = const Color(0xFF4A5E4A);
        actionColor = const Color(0xFF2D402D);
        break;
      case HomeInsightTag.worthNoting:
        bgColor = const Color(0xFFFDF5F3);
        borderColor = const Color(0xFFF5D6D0);
        tagTextColor = const Color(0xFF9A5B1E);
        titleColor = const Color(0xFF5E3A33);
        headlineColor = const Color(0xFF6E4D45);
        actionColor = const Color(0xFF5E3A33);
        break;
      case HomeInsightTag.pattern:
        bgColor = const Color(0xFFF0F4F8);
        borderColor = const Color(0xFFD6E2E9);
        tagTextColor = const Color(0xFF2C5E7A);
        titleColor = const Color(0xFF243B53);
        headlineColor = const Color(0xFF334E68);
        actionColor = const Color(0xFF243B53);
        break;
      case HomeInsightTag.insight:
      default:
        bgColor = const Color(0xFFF7F5F0);
        borderColor = const Color(0xFFEBE6DF);
        tagTextColor = const Color(0xFF67594E);
        titleColor = const Color(0xFF67594E);
        headlineColor = const Color(0xFF8C7D70);
        actionColor = const Color(0xFF67594E);
        break;
    }

    final hasStats = data.averageSeverityDisplay != null || data.consistencyPercent != null;
    final hasBothInsights = widget.dailyInsight != null && widget.weeklyInsight != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + title + toggle/tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(data.icon ?? '✨', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    data.title,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasBothInsights) ...[
                    _buildSegmentButton('Daily', !_showWeekly, () {
                      setState(() => _showWeekly = false);
                    }),
                    const SizedBox(width: 4),
                    _buildSegmentButton('Weekly', _showWeekly, () {
                      setState(() => _showWeekly = true);
                    }),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      data.tag.label,
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: tagTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Headline
          Text(
            data.headline,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.6,
              color: headlineColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasStats) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (data.averageSeverityDisplay != null) ...[
                  Expanded(
                    child: _buildGridItem(
                      'AVG SEVERITY',
                      data.averageSeverityDisplay!,
                      isPositive: data.tag == HomeInsightTag.positiveTrend,
                    ),
                  ),
                ],
                if (data.averageSeverityDisplay != null && data.consistencyPercent != null)
                  const SizedBox(width: 12),
                if (data.consistencyPercent != null) ...[
                  Expanded(
                    child: _buildGridItem(
                      'CONSISTENCY',
                      '${data.consistencyPercent}%',
                      isPositive: data.consistencyPercent! >= 70,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (data.actionLabel != null) ...[
            const SizedBox(height: 16),
            _buildActionButton(
              data.actionLabel!,
              actionColor,
              onTap: () {
                if (widget.onViewTrendDetail != null) {
                  widget.onViewTrendDetail!(data);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF2D402D) : const Color(0xFF78716C),
          ),
        ),
      ),
    );
  }

  Widget _buildInProgressInsight() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBE6DF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Insight',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF67594E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCD6CD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'IN PROGRESS',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: const Color(0xFF67594E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'We are currently collecting data to find personalized correlations. Please log your symptoms, triggers, and medications for at least 3 days to build correlations.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF8C7D70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyInsight() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEDDC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Weekly Data Insight',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D402D),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PATTERN',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: const Color(0xFF2D402D).withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              text: 'Based on your logs, ',
              children: [
                TextSpan(
                  text: 'Hot Flashes severity increased by 40%',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' on days where sleep duration was under 6 hours.'),
              ],
            ),
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF4A5E4A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGridItem('AVG SEVERITY', 'High (7.2)', isPositive: false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGridItem('CONSISTENCY', '85%', isPositive: false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButton('View Detailed Trend Analysis', const Color(0xFF2D402D)),
        ],
      ),
    );
  }

  Widget _buildDailyInsight() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEDDC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Insight',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D402D),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'POSITIVE TREND',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: const Color(0xFF2D402D).withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              text: 'Great job staying consistent! ',
              children: [
                TextSpan(
                  text: 'Your sleep quality improved by 15%',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                    text: ' compared to last week, which aligns with lower hot flash severity today.'),
              ],
            ),
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF4A5E4A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGridItem('AVG SEVERITY', 'Low (2.4)', isPositive: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGridItem('CONSISTENCY', '100%', isPositive: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButton('View Detailed Trend Analysis', const Color(0xFF2D402D)),
        ],
      ),
    );
  }

  Widget _buildHighSeverityInsight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHighSeverityAlertBanner(
          const HighSeverityAlertData(
            isActive: true,
            consecutiveSevereDays: 3,
            message:
                "You've logged severe hot flashes for 3 consecutive days. We recommend consulting your healthcare provider to discuss your current management plan.",
            showProactiveTips: true,
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(String label, String value, {required bool isPositive}) {
    final Color valueColor = isPositive ? const Color(0xFF2D402D) : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: const Color(0xFF78716C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareGridItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: const Color(0xFF817266),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF67594E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Icon(Icons.arrow_forward, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
