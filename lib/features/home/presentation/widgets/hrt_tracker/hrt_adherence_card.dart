import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';

import 'package:eunora/features/hrt_tracker/domain/hrt_schedule_service.dart';

class HrtAdherenceCard extends ConsumerStatefulWidget {
  final DateTime focusedMonth;
  final Map<int, DailyLog> monthlyLogs;

  const HrtAdherenceCard({
    super.key,
    required this.focusedMonth,
    required this.monthlyLogs,
  });

  @override
  ConsumerState<HrtAdherenceCard> createState() => _HrtAdherenceCardState();
}

class _HrtAdherenceCardState extends ConsumerState<HrtAdherenceCard> {
  String? _selectedMedicationId; // null = 'all'

  @override
  Widget build(BuildContext context) {
    final providerMeds = ref.watch(medicationsProvider).medications
        .where((m) => m.endedAt == null)
        .where((m) => !HrtScheduleService.isAsNeeded(m))
        .toList();
    final totalDays = DateUtils.getDaysInMonth(widget.focusedMonth.year, widget.focusedMonth.month);

    final today = DateTime.now();
    final isCurrentMonth = today.year == widget.focusedMonth.year && today.month == widget.focusedMonth.month;
    final limitDay = isCurrentMonth ? today.day : totalDays;

    int totalScheduled = 0;
    int totalLogged = 0;

    if (providerMeds.isEmpty) {
      for (int day = 1; day <= limitDay; day++) {
        final log = widget.monthlyLogs[day];
        if (log != null) {
          if (_selectedMedicationId == null) {
            totalScheduled += log.hrtIntakes.length;
            totalLogged += log.hrtIntakes.where((h) => h.isTaken).length;
          } else {
            final medIntakes = log.hrtIntakes.where(
              (h) => h.medicationId == _selectedMedicationId || h.name.toLowerCase() == _selectedMedicationId!.toLowerCase(),
            );
            totalScheduled += medIntakes.length;
            totalLogged += medIntakes.where((h) => h.isTaken).length;
          }
        }
      }
    } else {
      final targetMeds = _selectedMedicationId == null
          ? providerMeds
          : providerMeds.where((m) => m.id == _selectedMedicationId || m.name.toLowerCase() == _selectedMedicationId!.toLowerCase()).toList();

      for (int day = 1; day <= limitDay; day++) {
        final date = DateTime(widget.focusedMonth.year, widget.focusedMonth.month, day);
        final log = widget.monthlyLogs[day];

        for (final med in targetMeds) {
          if (HrtScheduleService.isScheduledOnDate(med, date)) {
            totalScheduled++;
            if (log != null) {
              final intake = log.hrtIntakes.firstWhere(
                (h) => h.medicationId == med.id || h.name.toLowerCase() == med.name.toLowerCase(),
                orElse: () => HrtIntakeLog(medicationId: med.id, name: med.name, dose: med.dose, unit: med.unit, time: '', isTaken: false),
              );
              if (intake.isTaken) {
                totalLogged++;
              }
            }
          }
        }
      }
    }

    int rate = 100;
    if (totalScheduled > 0 && widget.monthlyLogs.isNotEmpty) {
      rate = ((totalLogged / totalScheduled) * 100).round();
    } else {
      final hasMeds = providerMeds.isNotEmpty;
      rate = hasMeds ? 100 : (totalScheduled > 0 ? ((totalLogged / totalScheduled) * 100).round() : 100);
    }

    final String selectedName = _selectedMedicationId == null
        ? 'Combined'
        : (providerMeds.firstWhere(
            (m) => m.id == _selectedMedicationId || m.name.toLowerCase() == _selectedMedicationId!.toLowerCase(),
            orElse: () => providerMeds.isNotEmpty ? providerMeds.first : Medication(name: 'Medication', type: MedicationType.pill, dose: 1, unit: 'mg', frequency: 'Daily'),
          ).name);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0E8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF2D5A3E).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFF2D5A3E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedMedicationId == null
                          ? 'Adherence this month: $rate%'
                          : '$selectedName Adherence: $rate%',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rate >= 80
                          ? "You're staying consistent! Keep it up."
                          : "Try checking your reminders to log doses daily.",
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: const Color(0xFF2D5A3E).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                color: const Color(0xFF2D5A3E).withOpacity(0.3),
                size: 22,
              ),
            ],
          ),
          if (providerMeds.length > 1) ...[
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All Medications',
                    isSelected: _selectedMedicationId == null,
                    onTap: () => setState(() => _selectedMedicationId = null),
                  ),
                  ...providerMeds.map((med) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildFilterChip(
                          label: med.name,
                          isSelected: _selectedMedicationId == med.id || _selectedMedicationId == med.name.toLowerCase(),
                          onTap: () => setState(() => _selectedMedicationId = med.id),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D5A3E) : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D5A3E) : const Color(0xFF2D5A3E).withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF2D5A3E),
          ),
        ),
      ),
    );
  }
}
