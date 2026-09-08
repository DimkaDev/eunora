import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';

import 'package:eunora/features/hrt_tracker/domain/hrt_schedule_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/core/utils/time_formatter.dart';

class MedicationHrtCard extends StatelessWidget {
  final List<Medication> medications;
  final Map<String, bool> takenStatus;
  final Map<String, String> takenTime;
  final ValueChanged<Map<String, bool>>? onTakenStatusChanged;
  final VoidCallback? onManageTap;

  const MedicationHrtCard({
    super.key,
    required this.medications,
    required this.takenStatus,
    required this.takenTime,
    this.onTakenStatusChanged,
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

                final loggedIntake = isTaken
                    ? HrtIntakeLog(
                        medicationId: med.id,
                        name: med.name,
                        dose: med.dose,
                        unit: med.unit,
                        time: takenTime[med.name] ?? '',
                        isTaken: true,
                      )
                    : null;

                final dailyState = HrtScheduleService.getDailyState(
                  med: med,
                  date: DateTime.now(),
                  loggedIntake: loggedIntake,
                );

                String pendingText = 'SCHEDULED TODAY';
                if (dailyState == DailyScheduledState.asNeeded) {
                  pendingText = 'AS NEEDED';
                } else if (dailyState == DailyScheduledState.notScheduledToday) {
                  pendingText = 'NOT SCHEDULED TODAY';
                }

                final rawTime = takenTime[med.name];
                final formattedTime = (rawTime != null && rawTime.trim().isNotEmpty)
                    ? AppTimeFormatter.formatTimeString(rawTime)
                    : '';
                final timeStr = formattedTime.isNotEmpty ? ' • $formattedTime' : '';

                return Padding(
                  padding: EdgeInsets.only(bottom: idx == medications.length - 1 ? 0 : 12),
                  child: _buildMedicationRow(
                    context: context,
                    icon: icon,
                    iconColor: iconColor,
                    name: med.name,
                    schedule: isTaken ? '${med.doseAndFrequency}$timeStr' : med.doseAndFrequency,
                    isTaken: isTaken,
                    dailyState: dailyState,
                    onTap: onManageTap,
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
    required DailyScheduledState dailyState,
    required VoidCallback? onTap,
    required String activeBadgeText,
  }) {
    Color containerBg;
    Color containerBorder;
    Color badgeBg;
    Color badgeColor;
    IconData? badgeIcon;
    String badgeText;

    if (isTaken || dailyState == DailyScheduledState.logged) {
      containerBg = const Color(0xFFE8F5ED);
      containerBorder = const Color(0xFFC7E8D5);
      badgeBg = const Color(0xFFC7E8D5);
      badgeColor = const Color(0xFF2D5A3E);
      badgeIcon = Icons.check_circle;
      badgeText = activeBadgeText.toUpperCase();
    } else if (dailyState == DailyScheduledState.asNeeded) {
      containerBg = const Color(0xFFF5F3FF);
      containerBorder = const Color(0xFFE8E2FA);
      badgeBg = const Color(0xFFE8E2FA);
      badgeColor = const Color(0xFF6B52B6);
      badgeIcon = Icons.medical_services;
      badgeText = 'AS NEEDED';
    } else if (dailyState == DailyScheduledState.notScheduledToday) {
      containerBg = const Color(0xFFF7F6F5);
      containerBorder = const Color(0xFFEBE8E5);
      badgeBg = const Color(0xFFEBE8E5);
      badgeColor = const Color(0xFF8C827A);
      badgeIcon = Icons.event_busy;
      badgeText = 'NOT SCHEDULED TODAY';
    } else {
      // readyToLog / SCHEDULED TODAY
      containerBg = const Color(0xFFFFF9F5);
      containerBorder = const Color(0xFFF5E6DD);
      badgeBg = const Color(0xFFFFECE0);
      badgeColor = const Color(0xFFC85A32);
      badgeIcon = Icons.schedule;
      badgeText = 'SCHEDULED TODAY';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: containerBorder),
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
                    decoration: BoxDecoration(
                      color: isTaken ? const Color(0xFFC7E8D5) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: isTaken
                          ? []
                          : const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Icon(
                      isTaken ? Icons.check : icon,
                      color: isTaken ? const Color(0xFF2D5A3E) : iconColor,
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
                                ? const Color(0xFF1B432C)
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
                                ? const Color(0xFF2D5A3E).withOpacity(0.8)
                                : const Color(0xFF78716C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right portion: Status badge indicating logged state
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (badgeIcon != null) ...[
                    Icon(
                      badgeIcon,
                      size: 11,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    badgeText,
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
