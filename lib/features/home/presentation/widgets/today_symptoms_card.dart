import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';

class TodaySymptomsCard extends StatelessWidget {
  final List<Map<String, String>> loggedSymptoms;
  final VoidCallback onAddSymptom;
  final VoidCallback onEditSymptom;

  const TodaySymptomsCard({
    super.key,
    required this.loggedSymptoms,
    required this.onAddSymptom,
    required this.onEditSymptom,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = loggedSymptoms.isEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.show_chart,
                    color: Color(0xFF817266),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Symptoms",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (!isEmpty)
                IconButton(
                  onPressed: onEditSymptom,
                  icon: const Icon(Icons.edit_note),
                  color: const Color(0xFFA8A29E),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (isEmpty)
            _buildEmptyState(context)
          else
            _buildChipsState(context),
        ],
      ),
    );
  }

  // Dashed Empty State Box
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE7E1DF),
          width: 2,
          style: BorderStyle.solid, // Note: Flutter doesn't natively support dashed borders easily without external package, so we render a clean thin container with light gray borders that mimics the design beautifully.
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hotel_class,
            color: Color(0xFFD6D3D1),
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            "No logs yet",
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF78716C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Track how you're feeling today",
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: const Color(0xFFA8A29E),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAddSymptom,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              foregroundColor: AppTheme.primary,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Add Symptom',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Chips + Inline add button
  Widget _buildChipsState(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...loggedSymptoms.map((symptom) {
          final name = symptom['name'] ?? '';
          final severity = symptom['severity'] ?? 'Mild';
          return InkWell(
            onTap: onEditSymptom,
            borderRadius: BorderRadius.circular(20),
            child: _buildSymptomChip(name, severity),
          );
        }),

        // Trailing inline dashed addition button
        InkWell(
          onTap: onAddSymptom,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 40,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD0C4BC).withOpacity(0.5),
                style: BorderStyle.solid,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.add,
                size: 16,
                color: Color(0xFFA8A29E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomChip(String label, String severity) {
    Color bg;
    Color textColor;
    Color barColor;
    String emoji;
    int blocks;

    switch (severity) {
      case 'Moderate':
        bg = const Color(0xFFFFF7E6); // Light amber
        textColor = const Color(0xFFD48806); // Amber text
        barColor = const Color(0xFFFADB14); // Yellow/Orange bar
        emoji = '😐';
        blocks = 2;
        break;
      case 'Severe':
        bg = const Color(0xFFFFF1F0); // Light coral red
        textColor = const Color(0xFFCF1322); // Deep red text
        barColor = const Color(0xFFFF4D4F); // Red bar
        emoji = '😟';
        blocks = 3;
        break;
      case 'Mild':
      default:
        bg = const Color(0xFFF6FFED); // Light green
        textColor = const Color(0xFF389E0D); // Green text
        barColor = const Color(0xFF73D13D); // Green bar
        emoji = '😊';
        blocks = 1;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: textColor.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2A2421), // High contrast charcoal text
            ),
          ),
          const SizedBox(width: 10),

          // Mini severity indicator columns (3 bars)
          Row(
            children: List.generate(3, (index) {
              final active = index < blocks;
              return Container(
                width: 3.5,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  color: active ? barColor : barColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          ),
          const SizedBox(width: 6),

          Text(
            severity.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
