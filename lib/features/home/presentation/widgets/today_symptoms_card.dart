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
    int blocks = 1;
    if (severity == 'Moderate') blocks = 2;
    if (severity == 'Severe') blocks = 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E0D8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 8),

          // Mini severity indicator columns (3 bars)
          Row(
            children: List.generate(3, (index) {
              final active = index < blocks;
              return Container(
                width: 3,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primary : AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(1),
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
              color: AppTheme.primary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
