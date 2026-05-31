import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';

class MedicationHrtCard extends StatelessWidget {
  final List<Medication> medications;
  final Map<String, bool> takenStatus;
  final ValueChanged<Map<String, bool>> onTakenStatusChanged;
  final VoidCallback? onManageTap;

  const MedicationHrtCard({
    super.key,
    required this.medications,
    required this.takenStatus,
    required this.onTakenStatusChanged,
    this.onManageTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    Icons.medication,
                    color: Color(0xFF817266),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Medication & HRT",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onManageTap,
                child: Text(
                  "Manage",
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Medications List
          if (medications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "No medications configured today.",
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
          else
            Column(
              children: medications.asMap().entries.map((entry) {
                final idx = entry.key;
                final med = entry.value;
                final isTaken = takenStatus[med.name] ?? false;

                // Determine icon based on type
                IconData icon = Icons.medication;
                if (med.type == MedicationType.pill) {
                  icon = Icons.medication;
                } else if (med.type == MedicationType.gel || med.type == MedicationType.cream) {
                  icon = Icons.medication_liquid;
                }

                // Alternating icon colors
                final iconColor = idx % 2 == 0 ? const Color(0xFF655A6E) : AppTheme.primary;

                // Badge text if taken
                String activeBadgeText = 'Taken';
                if (med.type == MedicationType.patch) {
                  activeBadgeText = 'Applied';
                }

                // Check frequency to see if it's daily
                final isDaily = med.frequency.toLowerCase().contains('daily') ||
                                med.frequency.toLowerCase().contains('bedtime');
                final pendingText = isDaily ? 'PENDING' : 'OPTIONAL';

                return Padding(
                  padding: EdgeInsets.only(bottom: idx == medications.length - 1 ? 0 : 12),
                  child: _buildMedicationRow(
                    context: context,
                    icon: icon,
                    iconColor: iconColor,
                    name: med.name,
                    schedule: med.doseAndFrequency,
                    isTaken: isTaken,
                    pendingText: pendingText,
                    onChanged: (val) {
                      final newStatus = Map<String, bool>.from(takenStatus);
                      newStatus[med.name] = val;
                      onTakenStatusChanged(newStatus);
                    },
                    activeBadgeText: activeBadgeText,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String name,
    required String schedule,
    required bool isTaken,
    required String pendingText,
    required ValueChanged<bool> onChanged,
    required String activeBadgeText,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTaken
            ? const Color(0xFFEDDDF5).withOpacity(0.3)
            : const Color(0xFFF8F2F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left portion: Icon & details
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isTaken
                              ? const Color(0xFF4D4355)
                              : AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        schedule,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isTaken
                              ? const Color(0xFF4D4355).withOpacity(0.7)
                              : const Color(0xFF78716C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right portion: Switch and status badge
          Row(
            children: [
              // Status Badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isTaken
                      ? const Color(0xFFE8F0E8)
                      : const Color(0xFFE7E1DF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isTaken ? activeBadgeText.toUpperCase() : pendingText,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isTaken
                        ? const Color(0xFF2D402D)
                        : const Color(0xFF78716C),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Custom Switch
              GestureDetector(
                onTap: () => onChanged(!isTaken),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 24,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isTaken ? AppTheme.primary : const Color(0xFFD6D3D1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: isTaken ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
