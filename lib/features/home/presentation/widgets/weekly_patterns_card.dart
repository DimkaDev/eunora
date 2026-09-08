import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class WeeklyPatternsCard extends StatelessWidget {
  final bool isInsufficientData;

  const WeeklyPatternsCard({super.key, this.isInsufficientData = false});

  @override
  Widget build(BuildContext context) {
    if (isInsufficientData) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF5F5F4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This Week's Patterns",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
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
                    Icons.auto_graph_outlined,
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
                    'Data is still being collected. Eunora will highlight meaningful patterns once enough daily entries have been recorded.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5F5F4)!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "This Week's Patterns",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE7E5E4)!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LAST 7 DAYS',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFFA8A29E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayLabel('M'),
              _buildDayLabel('T'),
              _buildDayLabel('W', isActive: true),
              _buildDayLabel('T'),
              _buildDayLabel('F'),
              _buildDayLabel('S'),
              _buildDayLabel('S'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayCell(day: '17', color: const Color(0xFFEDDDF5), opacity: 0.4),
              _buildDayCell(day: '18', color: const Color(0xFFE8A89B)),
              _buildDayCell(day: '19', color: const Color(0xFFE8A89B), isSelected: true),
              _buildEmptyCell(),
              _buildEmptyCell(),
              _buildEmptyCell(),
              _buildEmptyCell(),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildPatternStat(
                  dotColor: const Color(0xFFE8A89B),
                  label: 'PRIMARY SYMPTOM',
                  value: 'Hot Flashes',
                  subValue: '6/7 days tracked',
                ),
              ),
              Expanded(
                child: _buildPatternStat(
                  dotColor: const Color(0xFFEDDDF5),
                  label: 'AVG DURATION',
                  value: '12 mins',
                  subValue: 'Peak: 11:00 PM',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(String label, {bool isActive = false}) {
    return SizedBox(
      width: 40,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isActive ? AppTheme.primary : const Color(0xFFA8A29E),
        ),
      ),
    );
  }

  Widget _buildDayCell({
    required String day,
    required Color color,
    double opacity = 1.0,
    bool isSelected = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            borderRadius: BorderRadius.circular(8),
            border: isSelected 
              ? Border.all(color: AppTheme.primary, width: 2)
              : Border.all(color: const Color(0xFFF5F5F4)!),
          ),
          alignment: Alignment.center,
          child: Text(
            day,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: opacity < 1.0 ? Colors.black.withOpacity(0.4) : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCell() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAF9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFF5F5F4)!,
              style: BorderStyle.solid, 
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          color: Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildPatternStat({
    required Color dotColor,
    required String label,
    required String value,
    required String subValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFA8A29E),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
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
              subValue,
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: const Color(0xFF78716C),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
