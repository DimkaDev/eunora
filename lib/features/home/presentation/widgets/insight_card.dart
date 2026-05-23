import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

enum InsightType {
  weekly,
  daily,
  highSeverity,
}

class InsightCard extends StatelessWidget {
  final InsightType type;

  const InsightCard({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case InsightType.weekly:
        return _buildWeeklyInsight();
      case InsightType.daily:
        return _buildDailyInsight();
      case InsightType.highSeverity:
        return _buildHighSeverityInsight();
    }
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
                  'CRITICAL CORRELATION',
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
                const TextSpan(text: ' compared to last week, which aligns with lower hot flash severity today.'),
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
        // 1. High Symptom Severity Alert Box
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
                          'High Symptom Severity Alert',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "You've logged severe hot flashes for 3 consecutive days. We recommend consulting your healthcare provider to discuss your current management plan.",
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
        const SizedBox(height: 16),
        // 2. Proactive Care Insight Card
        Container(
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
                    const TextSpan(text: ', try lowering your bedroom temperature to 65°F at night and wearing breathable, moisture-wicking layers.'),
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
              const SizedBox(height: 16),
              _buildActionButton('View Management Strategies', const Color(0xFF67594E)),
            ],
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
              fontSize: 16,
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

  Widget _buildActionButton(String label, Color color) {
    return InkWell(
      onTap: () {},
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
