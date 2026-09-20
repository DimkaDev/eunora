import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/home/presentation/widgets/dose_change_alert.dart';
import 'package:eunora/features/onboarding/presentation/widgets/add_medication_modal.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eunora/features/hrt_tracker/domain/hrt_schedule_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/core/utils/time_formatter.dart';

enum HrtLogStatus { pending, taken, skipped }

class SuccessCheckmark extends StatefulWidget {
  const SuccessCheckmark({super.key});

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFF2D5A3E),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 14),
      ),
    );
  }
}

class HrtEditEntry {
  String? id;
  String name;
  String details;
  String status;
  bool isTaken;
  String dose;
  String unit; // 'mcg' | 'mg' | 'pump'
  String applicationType; // e.g. 'Patch' | 'Tablet' | 'Gel'
  String timeTaken; // e.g. '08:30'
  bool isOneOff;

  HrtEditEntry({
    this.id,
    required this.name,
    required this.details,
    required this.status,
    required this.isTaken,
    required this.dose,
    required this.unit,
    required this.applicationType,
    required this.timeTaken,
    this.isOneOff = false,
  });

  factory HrtEditEntry.fromMap(Map<String, String> map) {
    final isTaken = map['isTaken'] == 'true';
    final isOneOff = map['isOneOff'] == 'true';
    final details = map['details'] ?? '';
    String dose = map['dose'] ?? '50';
    String unit = map['unit'] ?? 'mcg';
    String applicationType = 'Patch';
    final detailParts = details.split('·');
    if (detailParts.isNotEmpty) {
      final doseStr = detailParts.first.trim();
      final doseMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(\w+)').firstMatch(doseStr);
      if (doseMatch != null) {
        if (map['dose'] == null) dose = doseMatch.group(1) ?? '50';
        if (map['unit'] == null) unit = doseMatch.group(2) ?? 'mcg';
      }
    }
    if (detailParts.length > 1) {
      applicationType = detailParts[1].trim();
    }

    // Parse time from status like 'Taken 08:30' or 'Taken 10:17 PM'
    final statusStr = map['status'] ?? '';
    final timeTaken = AppTimeFormatter.extractTimeFromStatus(
      statusStr,
      defaultFallback: '08:00 AM',
    );

    return HrtEditEntry(
      id: map['id'],
      name: map['name'] ?? '',
      details: details,
      status: statusStr,
      isTaken: isTaken,
      dose: dose,
      unit: unit,
      applicationType: applicationType,
      timeTaken: timeTaken,
      isOneOff: isOneOff,
    );
  }

  Map<String, String> toMap() {
    return {
      if (id != null) 'id': id!,
      'name': name,
      'details': '$dose $unit · $applicationType',
      'status': isTaken ? 'Taken ${AppTimeFormatter.formatTimeString(timeTaken)}' : 'Not taken',
      'isTaken': isTaken.toString(),
      'dose': dose,
      'unit': unit,
      'isOneOff': isOneOff.toString(),
    };
  }
}

class CalendarHrtEditSheet extends ConsumerStatefulWidget {
  final List<Map<String, String>> initialHrt;
  final DateTime? selectedDate;
  final void Function(List<Map<String, String>> updated) onSave;
  final bool showAddButton;

  const CalendarHrtEditSheet({
    super.key,
    required this.initialHrt,
    this.selectedDate,
    required this.onSave,
    this.showAddButton = true,
  });

  @override
  ConsumerState<CalendarHrtEditSheet> createState() =>
      _CalendarHrtEditSheetState();
}

class _CalendarHrtEditSheetState extends ConsumerState<CalendarHrtEditSheet> {
  late List<HrtEditEntry> _entries;
  int? _expandedIndex; // which card is expanded for editing
  final Map<String, DateTime> _lastTakenDates = {};

  @override
  void initState() {
    super.initState();
    _entries = widget.initialHrt.map(HrtEditEntry.fromMap).toList();
    _loadRealLastTakenDates();
  }

  Future<void> _loadRealLastTakenDates() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final firestore = ref.read(firestoreServiceProvider);
      // Fetch past 90 days to find last taken intakes
      final start = DateTime.now().subtract(const Duration(days: 90));
      final logs = await firestore.getDailyLogsHistory(
        user.uid,
        start,
        DateTime.now(),
      );
      // Sort oldest first to chronologically process intake logs
      logs.sort((a, b) => a.date.compareTo(b.date));

      final Map<String, DateTime> realLastTaken = {};
      for (final log in logs) {
        // check if this is not today's log draft we are currently editing
        final logDateStr =
            "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
        final todayDateStr =
            "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
        if (logDateStr == todayDateStr) {
          continue;
        }

        if (log.hrtIntakes.isNotEmpty) {
          for (final intake in log.hrtIntakes) {
            if (intake.isTaken) {
              realLastTaken[intake.name.toLowerCase()] = log.date;
              if (intake.medicationId.isNotEmpty) {
                realLastTaken[intake.medicationId] = log.date;
              }
            }
          }
        } else {
          // Fallback parsing estradiol / progesterone flat fields
          if (log.estradiolChecked) {
            final meds = ref.read(medicationsProvider).medications;
            for (final med in meds) {
              if (med.name.toLowerCase().contains('estradiol') ||
                  med.name.toLowerCase().contains('estrogen')) {
                realLastTaken[med.id] = log.date;
                realLastTaken[med.name.toLowerCase()] = log.date;
              }
            }
          }
          if (log.progesteroneChecked) {
            final meds = ref.read(medicationsProvider).medications;
            for (final med in meds) {
              if (med.name.toLowerCase().contains('progesterone') ||
                  med.name.toLowerCase().contains('utrogestan')) {
                realLastTaken[med.id] = log.date;
                realLastTaken[med.name.toLowerCase()] = log.date;
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _lastTakenDates.addAll(realLastTaken);
        });
      }
    } catch (e) {
      debugPrint("Error loading real last taken hrt dates: $e");
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.day} ${_getMonthName(dt.month)}";
  }

  bool _isScheduledToday(String name, DateTime? lastTaken) {
    // Resolve frequency from medications provider first
    final meds = ref.read(medicationsProvider).medications;
    final matchingMed = meds.firstWhere(
      (m) => m.name.toLowerCase() == name.toLowerCase() || (m.id == name),
      orElse: () => Medication(
        name: name,
        type: MedicationType.other,
        dose: 50.0,
        unit: 'mcg',
        frequency: 'daily',
      ),
    );

    final freq = matchingMed.frequency;

    if (freq.toLowerCase() == 'daily') {
      return true;
    }
    if (lastTaken == null) {
      return true;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(lastTaken.year, lastTaken.month, lastTaken.day);
    final daysDiff = today.difference(thatDay).inDays;

    if (freq.toLowerCase().contains('twice weekly')) {
      return daysDiff >= 3;
    }
    if (freq.toLowerCase().contains('every 2 days')) {
      return daysDiff >= 2;
    }
    return true;
  }

  IconData _getMedIcon(String name) {
    if (name.toLowerCase().contains('gel')) {
      return Icons.opacity;
    }
    return Icons.medication;
  }

  HrtLogStatus _getEntryStatus(HrtEditEntry entry, int index) {
    if (entry.isTaken) {
      return HrtLogStatus.taken;
    }
    final lastTaken =
        _lastTakenDates[entry.id ?? ''] ??
        _lastTakenDates[entry.name.toLowerCase()];
    final isScheduled = _isScheduledToday(entry.id ?? entry.name, lastTaken);
    return isScheduled ? HrtLogStatus.pending : HrtLogStatus.skipped;
  }

  String _formatDateTime(DateTime dt, BuildContext context) {
    final dateStr = "${dt.day} ${_getMonthName(dt.month)}";
    if (context.mounted) {
      final timeStr = TimeOfDay(
        hour: dt.hour,
        minute: dt.minute,
      ).format(context);
      return "$dateStr, $timeStr";
    }
    return dateStr;
  }

  String _getMonthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  String _daysAgo(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(thatDay).inDays;
    if (diff <= 0) return 'today';
    if (diff == 1) return 'yesterday';
    return '$diff days ago';
  }

  void _setUnit(int index, String unit) {
    setState(() {
      _entries[index].unit = unit;
      _entries[index].details = '${_entries[index].dose} $unit · ${_entries[index].applicationType}';
    });
    _syncChanges();
  }

  void _setDose(int index, String dose) {
    setState(() {
      _entries[index].dose = dose;
      _entries[index].details = '$dose ${_entries[index].unit} · ${_entries[index].applicationType}';
    });
    _syncChanges();
  }

  void _toggleExpanded(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  List<double> _getAvailableDoses(String unit) {
    final u = unit.toLowerCase();
    if (u == 'mcg') {
      return [
        12.5,
        25.0,
        37.5,
        50.0,
        62.5,
        75.0,
        87.5,
        100.0,
        112.5,
        125.0,
        150.0,
        175.0,
        200.0,
        250.0,
      ];
    } else if (u == 'mg') {
      return [
        0.5,
        1.0,
        1.5,
        2.0,
        2.5,
        3.0,
        4.0,
        5.0,
        10.0,
        20.0,
        50.0,
        100.0,
        150.0,
        200.0,
        300.0,
        400.0,
      ];
    } else if (u == 'pump' || u == 'pumps') {
      return [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
    } else {
      return List.generate(20, (i) => (i + 1).toDouble());
    }
  }

  void _openDosePicker({
    required int index,
    required String unit,
    required double currentDose,
    required ValueChanged<double> onDoseChanged,
  }) {
    final doses = _getAvailableDoses(unit);
    int initialIndex = doses.indexWhere((d) => (d - currentDose).abs() < 0.01);
    if (initialIndex == -1) initialIndex = 0;

    double tempDose = doses[initialIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFEF8F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0C4BC).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8A817C),
                      ),
                    ),
                  ),
                  Text(
                    'Select Dose',
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onDoseChanged(tempDose);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Done',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  itemExtent: 44,
                  onSelectedItemChanged: (index) {
                    tempDose = doses[index];
                  },
                  children: doses.map((d) {
                    return Center(
                      child: Text(
                        d
                            .toStringAsFixed(d == d.toInt() ? 0 : 2)
                            .replaceAll(RegExp(r'\.00$'), ''),
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _syncChanges() {
    final meds = ref.read(medicationsProvider).medications;
    for (final entry in _entries) {
      if (entry.isOneOff) {
        continue;
      }
      final matchingIndex = meds.indexWhere(
        (m) =>
            (m.id.isNotEmpty && m.id == entry.id) ||
            m.name.toLowerCase() == entry.name.toLowerCase(),
      );
      if (matchingIndex != -1) {
        final matchingMed = meds[matchingIndex];
        final newDoseVal = double.tryParse(entry.dose) ?? matchingMed.dose;
        if (newDoseVal != matchingMed.dose || entry.unit != matchingMed.unit) {
          ref.read(medicationsProvider.notifier).updateMedication(
            matchingMed.copyWith(dose: newDoseVal, unit: entry.unit),
          );
        }
      }
    }
    widget.onSave(_entries.map((e) => e.toMap()).toList());
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically listen to medicationsProvider updates
    ref.listen(medicationsProvider, (previous, next) {
      // Detect newly added medications not already present in _entries
      for (final med in next.medications) {
        final exists = _entries.any(
          (entry) => (entry.id != null && entry.id == med.id) || entry.name.toLowerCase() == med.name.toLowerCase(),
        );
        if (!exists) {
          final selectedDate = widget.selectedDate ?? DateTime.now();
          final target = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
          bool isActiveOnSelectedDate = true;
          if (med.startedAt != null) {
            final start = DateTime(med.startedAt!.year, med.startedAt!.month, med.startedAt!.day);
            if (target.isBefore(start)) isActiveOnSelectedDate = false;
          }
          if (med.endedAt != null) {
            final end = DateTime(med.endedAt!.year, med.endedAt!.month, med.endedAt!.day);
            if (target.isAfter(end)) isActiveOnSelectedDate = false;
          }

          if (isActiveOnSelectedDate) {
            final appType = med.type.displayName;
            setState(() {
              _entries.add(
                HrtEditEntry(
                  id: med.id,
                  name: med.name,
                  details:
                      '${med.dose.toStringAsFixed(0)} ${med.unit} · $appType',
                  status: 'Not taken',
                  isTaken: false,
                  dose: med.dose.toStringAsFixed(0),
                  unit: med.unit,
                  applicationType: appType,
                  timeTaken: '08:00',
                ),
              );
              _lastTakenDates[med.id] = DateTime.now().subtract(
                const Duration(days: 1),
              );
              _lastTakenDates[med.name.toLowerCase()] = DateTime.now().subtract(
                const Duration(days: 1),
              );
            });
          }
        }
      }
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _syncChanges();
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFEF8F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0DEDA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Medication',
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1D1B1A),
                        ),
                      ),
                      Text(
                        'Tap a medication to edit details',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: const Color(0xFF7F756E),
                        ),
                      ),
                    ],
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _syncChanges();
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EDEA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF9B8B7E),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CURRENT PRESCRIPTION label
                  Text(
                    'CURRENT PRESCRIPTION',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: const Color(0xFF9B8B7E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Medication cards or empty state
                  if (_entries.where((e) => _isMedActiveOnSelectedDate(e)).isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F7F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE7E5E4)),
                      ),
                      child: Center(
                        child: Text(
                          'No HRT medications were active on this date.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: const Color(0xFF78716C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._entries.asMap().entries.where((e) => _isMedActiveOnSelectedDate(e.value)).map((e) {
                      return _buildMedicationCard(e.key, e.value);
                    }),

                  if (widget.showAddButton) ...[
                    const SizedBox(height: 12),
                    // Button to add custom HRT medications
                    InkWell(
                      onTap: () {
                        final now = DateTime.now();
                        final isToday = widget.selectedDate == null ||
                            (now.year == widget.selectedDate!.year &&
                             now.month == widget.selectedDate!.month &&
                             now.day == widget.selectedDate!.day);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddMedicationModal(
                            showDiscontinuedToggle: !isToday,
                            isRetrospectiveOneOff: !isToday,
                            loggingDate: widget.selectedDate,
                            onAddOneOffEntry: (entry) {
                              setState(() {
                                final existingIndex = _entries.indexWhere(
                                  (e) => (e.id != null && e.id == entry.id) || e.name.toLowerCase() == entry.name.toLowerCase(),
                                );
                                if (existingIndex != -1) {
                                  _entries[existingIndex] = entry;
                                } else {
                                  _entries.add(entry);
                                }
                              });
                              _syncChanges();
                            },
                            onMedicationCreated: (med) {
                              setState(() {
                                final newEntry = HrtEditEntry(
                                  id: med.id,
                                  name: med.name,
                                  details: '${med.dose.toStringAsFixed(med.dose == med.dose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), '')} ${med.unit} · ${med.type.displayName}',
                                  status: 'Taken',
                                  isTaken: true,
                                  dose: med.dose.toStringAsFixed(med.dose == med.dose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), ''),
                                  unit: med.unit,
                                  applicationType: med.type.displayName,
                                  timeTaken: '08:00',
                                  isOneOff: true,
                                );
                                final existingIndex = _entries.indexWhere(
                                  (e) => (e.id != null && e.id == med.id) || e.name.toLowerCase() == med.name.toLowerCase(),
                                );
                                if (existingIndex != -1) {
                                  _entries[existingIndex] = newEntry;
                                } else {
                                  _entries.add(newEntry);
                                }
                              });
                              _syncChanges();
                            },
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_circle_outline,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add HRT Medication',
                              style: GoogleFonts.manrope(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Wellness tip box
                  _buildTipCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Safe bottom spacing
          const SafeArea(
            top: false,
            child: SizedBox(height: 16),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildMedicationCard(int index, HrtEditEntry entry) {
    final isExpanded = _expandedIndex == index;

    final icon = _getMedIcon(entry.name);
    final lastTaken =
        _lastTakenDates[entry.id ?? ''] ??
        _lastTakenDates[entry.name.toLowerCase()];
    // Resolve frequency from medications provider first
    final meds = ref.read(medicationsProvider).medications;
    final matchingMed = meds.firstWhere(
      (m) =>
          m.name.toLowerCase() == entry.name.toLowerCase() ||
          (m.id == entry.id),
      orElse: () => Medication(
        name: entry.name,
        type: MedicationType.other,
        dose: double.tryParse(entry.dose) ?? 50.0,
        unit: entry.unit,
        frequency: 'daily',
      ),
    );

    final selectedDate = widget.selectedDate ?? DateTime.now();

    final loggedIntake = entry.isTaken
        ? HrtIntakeLog(
            medicationId: matchingMed.id,
            name: matchingMed.name,
            dose: matchingMed.dose,
            unit: matchingMed.unit,
            time: entry.timeTaken,
            isTaken: true,
          )
        : null;

    final dailyState = HrtScheduleService.getDailyState(
      med: matchingMed,
      date: selectedDate,
      loggedIntake: loggedIntake,
    );

    final freqStr = matchingMed.formattedFrequency;

    final subtitle = entry.isTaken
        ? '${entry.dose} ${entry.unit} • ${entry.timeTaken} • $freqStr'
        : '$freqStr • ' +
              (lastTaken == null
                  ? 'No information'
                  : 'Last taken: ${_formatDate(lastTaken)}');

    Color tileBgColor = Colors.white;
    Color tileBorderColor = const Color(0xFFF2EDEA);
    Color textColor = AppTheme.onSurface;
    Color subtitleColor = AppTheme.outline;
    Color iconColor = AppTheme.primary;
    Widget? trailingWidget;

    final activeBadgeText = matchingMed.type == MedicationType.patch ? 'Applied' : 'Taken';

    if (entry.isTaken || dailyState == DailyScheduledState.logged) {
      tileBgColor = const Color(0xFFE8F5ED);
      tileBorderColor = const Color(0xFFC7E8D5);
      textColor = const Color(0xFF1B432C);
      subtitleColor = const Color(0xFF2D5A3E).withValues(alpha: 0.8);
      iconColor = const Color(0xFF2D5A3E);
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFC7E8D5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              activeBadgeText,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D5A3E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const SuccessCheckmark(),
        ],
      );
    } else if (dailyState == DailyScheduledState.asNeeded) {
      tileBgColor = const Color(0xFFF5F3FF);
      tileBorderColor = const Color(0xFFE8E2FA);
      textColor = AppTheme.onSurface;
      subtitleColor = const Color(0xFF6B52B6).withValues(alpha: 0.8);
      iconColor = const Color(0xFF6B52B6);
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E2FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.medical_services,
                  color: Color(0xFF6B52B6),
                  size: 10,
                ),
                const SizedBox(width: 4),
                Text(
                  'As needed',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B52B6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF6B52B6)),
        ],
      );
    } else if (dailyState == DailyScheduledState.readyToLog) {
      tileBgColor = const Color(0xFFFFF9F5);
      tileBorderColor = const Color(0xFFF5E6DD);
      textColor = AppTheme.onSurface;
      subtitleColor = const Color(0xFFC85A32).withValues(alpha: 0.8);
      iconColor = const Color(0xFFC85A32);
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECE0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, color: Color(0xFFC85A32), size: 10),
                const SizedBox(width: 4),
                Text(
                  'Ready to log',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC85A32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF9B8B7E)),
        ],
      );
    } else {
      tileBgColor = const Color(0xFFF7F6F5);
      tileBorderColor = const Color(0xFFEBE8E5);
      textColor = const Color(0xFF7F756E);
      subtitleColor = const Color(0xFF8C827A);
      iconColor = const Color(0xFF8C827A);
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEBE8E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.event_busy,
                  color: Color(0xFF8C827A),
                  size: 10,
                ),
                const SizedBox(width: 4),
                Text(
                  'Not scheduled today',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8C827A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF8C827A)),
        ],
      );
    }

    Widget baseTile = Container(
      decoration: BoxDecoration(color: tileBgColor),
      child: ListTile(
        onTap: () => _toggleExpanded(index),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (entry.isTaken || dailyState == DailyScheduledState.logged)
                ? const Color(0xFFC7E8D5).withValues(alpha: 0.4)
                : dailyState == DailyScheduledState.notScheduledToday
                ? const Color(0xFFEAE6E0).withValues(alpha: 0.4)
                : const Color(0xFFEDDDF5).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          entry.name,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: subtitleColor,
          ),
        ),
        trailing: trailingWidget,
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? AppTheme.primary.withValues(alpha: 0.3)
              : const Color(0xFFEAE6E0),
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          children: [
            baseTile,
            if (isExpanded) ...[_buildExpandedPanel(index, entry)],
          ],
        ),
      ),
    );
  }

  bool _isMedActiveOnSelectedDate(HrtEditEntry entry) {
    if (entry.isOneOff || entry.isTaken) {
      return true;
    }
    final date = widget.selectedDate ?? DateTime.now();
    final target = DateTime(date.year, date.month, date.day);

    final meds = ref.read(medicationsProvider).medications;
    final matchingIndex = meds.indexWhere(
      (m) => (m.id.isNotEmpty && m.id == entry.id) || m.name.toLowerCase() == entry.name.toLowerCase(),
    );

    if (matchingIndex == -1) {
      // One-off entry explicitly added for this date or loaded from this date's log
      return true;
    }

    final matching = meds[matchingIndex];

    if (matching.startedAt != null) {
      final start = DateTime(matching.startedAt!.year, matching.startedAt!.month, matching.startedAt!.day);
      if (target.isBefore(start)) return false;
    }
    if (matching.endedAt != null) {
      final end = DateTime(matching.endedAt!.year, matching.endedAt!.month, matching.endedAt!.day);
      if (target.isAfter(end)) return false;
    }
    return true;
  }

  Widget _buildTakenToggle(HrtEditEntry entry) {
    final isActive = _isMedActiveOnSelectedDate(entry);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isActive ? 'Taken today?' : 'Not active on this date',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isActive ? AppTheme.onSurface : const Color(0xFF8C3A25),
          ),
        ),
        Opacity(
          opacity: isActive ? 1.0 : 0.4,
          child: CupertinoSwitch(
            value: isActive && entry.isTaken,
            activeColor: AppTheme.primary,
            onChanged: isActive
                ? (val) {
                    setState(() {
                      entry.isTaken = val;
                      if (val) {
                        entry.timeTaken = AppTimeFormatter.formatTimeOfDay(TimeOfDay.now());
                      }
                    });
                    _syncChanges();
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedPanel(int index, HrtEditEntry entry) {
    return _buildExpandedEditSection(entry, index);
  }

  Widget _buildExpandedEditSection(HrtEditEntry entry, int index) {
    final lastTaken =
        _lastTakenDates[entry.id ?? ''] ??
        _lastTakenDates[entry.name.toLowerCase()];
    final List<String> unitOptions = ['mg', 'mcg', 'pumps', 'applicator', 'g', 'sprays'];
    final meds = ref.read(medicationsProvider).medications;
    final matchingMed = meds.firstWhere(
      (m) => m.name.toLowerCase() == entry.name.toLowerCase(),
      orElse: () => Medication(name: entry.name, type: MedicationType.other, dose: 50, unit: 'mcg', frequency: ''),
    );
    if (!unitOptions.contains(entry.unit)) {
      unitOptions.add(entry.unit);
    }
    for (final m in meds) {
      if (!unitOptions.contains(m.unit)) {
        unitOptions.add(m.unit);
      }
    }

    final loggedIntake = entry.isTaken
        ? HrtIntakeLog(
            medicationId: matchingMed.id,
            name: matchingMed.name,
            dose: double.tryParse(entry.dose) ?? matchingMed.dose,
            unit: entry.unit,
            time: entry.timeTaken,
            isTaken: true,
          )
        : null;

    final dailyState = HrtScheduleService.getDailyState(
      med: matchingMed,
      date: widget.selectedDate ?? DateTime.now(),
      loggedIntake: loggedIntake,
    );

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2EC).withValues(alpha: 0.85),
        border: Border(
          top: const BorderSide(color: Color(0xFFEAE5DF), width: 1),
          bottom: const BorderSide(color: Color(0xFFEAE5DF), width: 1),
          left: BorderSide(color: AppTheme.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTakenToggle(entry),
          const SizedBox(height: 12),
          if (entry.isTaken) ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DOSE',
                        style: GoogleFonts.manrope(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8A817C),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          final currentDose =
                              double.tryParse(entry.dose) ?? 1.0;
                          _openDosePicker(
                            index: index,
                            unit: entry.unit,
                            currentDose: currentDose,
                            onDoseChanged: (newDose) {
                              _setDose(
                                index,
                                newDose
                                    .toStringAsFixed(
                                      newDose == newDose.toInt() ? 0 : 2,
                                    )
                                    .replaceAll(RegExp(r'\.00$'), ''),
                              );
                            },
                          );
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFFD0C4BC,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            entry.dose,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNIT',
                        style: GoogleFonts.manrope(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8A817C),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7E5).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          entry.unit,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TIME',
                        style: GoogleFonts.manrope(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8A817C),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _showTimePicker(index),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFFD0C4BC,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 14,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.timeTaken,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dailyState == DailyScheduledState.readyToLog
                            ? 'Scheduled for this day — Not logged yet'
                            : (dailyState == DailyScheduledState.asNeeded
                                ? 'Taken as needed — Not logged yet'
                                : 'Not scheduled for today'),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: dailyState == DailyScheduledState.readyToLog
                              ? const Color(0xFFC85A32)
                              : const Color(0xFF8A817C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastTaken == null
                            ? 'No last taken date recorded'
                            : 'Last taken: ${_formatDateTime(lastTaken, context)} (${_daysAgo(lastTaken)})',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEAE5DF), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    // Soft-stop: mark the medication as ended as of today
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(
                          'Stop Tracking?',
                          style: GoogleFonts.notoSerif(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'This will stop tracking this medication starting today. Your complete historical logging data, charts, and passport report history will be safely preserved. You can resume tracking it anytime.',
                          style: GoogleFonts.manrope(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                color: AppTheme.outline,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              final matchingMed = ref
                                  .read(medicationsProvider)
                                  .medications
                                  .firstWhere(
                                    (m) =>
                                        m.name.toLowerCase() ==
                                            entry.name.toLowerCase() ||
                                        (m.id == entry.id),
                                    orElse: () => Medication(
                                      name: entry.name,
                                      type: MedicationType.other,
                                      dose: 50.0,
                                      unit: 'mcg',
                                      frequency: 'daily',
                                    ),
                                  );
                              ref
                                  .read(medicationsProvider.notifier)
                                  .endMedication(matchingMed.id);
                              setState(() {
                                _entries.removeAt(index);
                                if (_expandedIndex == index) {
                                  _expandedIndex = null;
                                } else if (_expandedIndex != null &&
                                    _expandedIndex! > index) {
                                  _expandedIndex = _expandedIndex! - 1;
                                }
                              });
                              _syncChanges();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Stopped tracking ${entry.name}. History preserved.',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Text(
                              'Stop Tracking',
                              style: GoogleFonts.manrope(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.stop_circle_outlined,
                    size: 16,
                    color: Color(0xFF8C3A25),
                  ),
                  label: Text(
                    'Stop Tracking',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8C3A25),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final matchingMed = ref
                        .read(medicationsProvider)
                        .medications
                        .firstWhere(
                          (m) =>
                              m.name.toLowerCase() ==
                                  entry.name.toLowerCase() ||
                              (m.id == entry.id),
                          orElse: () => Medication(
                            name: entry.name,
                            type: MedicationType.other,
                            dose: 50.0,
                            unit: 'mcg',
                            frequency: 'daily',
                          ),
                        );

                    bool hasHistory = false;
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final historyLogs = await ref
                            .read(firestoreServiceProvider)
                            .getDailyLogsHistory(
                              user.uid,
                              DateTime(2020),
                              DateTime.now(),
                            );
                        hasHistory = HrtScheduleService.hasLoggedHistory(
                            matchingMed, historyLogs);
                      }
                    } catch (_) {}

                    if (!context.mounted) return;

                    if (hasHistory) {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(
                            'Cannot Delete Medication',
                            style: GoogleFonts.notoSerif(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8C3A25),
                            ),
                          ),
                          content: Text(
                            'This medication has recorded intake history in your logs. To preserve your medical timeline, it cannot be deleted. You can stop tracking it instead.',
                            style: GoogleFonts.manrope(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.manrope(
                                  color: AppTheme.outline,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                ref
                                    .read(medicationsProvider.notifier)
                                    .endMedication(matchingMed.id);
                                setState(() {
                                  _entries[index].isTaken = false;
                                  _entries[index].status = 'Stopped';
                                });
                                _syncChanges();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Stopped tracking ${entry.name}. History preserved.',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Text(
                                'Stop Tracking',
                                style: GoogleFonts.manrope(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    // Hard Delete: zero history -> remove medication completely
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(
                          'Delete Medication?',
                          style: GoogleFonts.notoSerif(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        content: Text(
                          'This medication has zero logged history. It will be permanently removed from your account.',
                          style: GoogleFonts.manrope(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                color: AppTheme.outline,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              ref
                                  .read(medicationsProvider.notifier)
                                  .removeMedication(matchingMed.id);
                              setState(() {
                                _entries.removeAt(index);
                                if (_expandedIndex == index) {
                                  _expandedIndex = null;
                                } else if (_expandedIndex != null &&
                                    _expandedIndex! > index) {
                                  _expandedIndex = _expandedIndex! - 1;
                                }
                              });
                              _syncChanges();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Medication permanently deleted.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.delete_forever_outlined,
                    size: 16,
                    color: Colors.red,
                  ),
                  label: Text(
                    'Delete Completely',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2DFD0).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD6C3B5).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Consistency is key for hormone stability. Try to take your medication within the same time window each day.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: const Color(0xFF51443A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseSheetTimeOfDay(String timeStr) {
    return AppTimeFormatter.parseTimeOfDay(timeStr);
  }

  void _showTimePicker(int index) {
    final parentContext = context;
    final currentTimeStr = _entries[index].timeTaken;
    final initialTimeOfDay = _parseSheetTimeOfDay(currentTimeStr);

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFEF8F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0C4BC).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Text(
                'Select Time',
                style: GoogleFonts.notoSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final now = TimeOfDay.now();
                    final formatted = AppTimeFormatter.formatTimeOfDay(now);
                    setState(() {
                      _entries[index].timeTaken = formatted;
                      _entries[index].isTaken = true;
                    });
                    _syncChanges();
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'Set to Now (${AppTimeFormatter.formatTimeOfDay(TimeOfDay.now())})',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final picked = await showTimePicker(
                      context: parentContext,
                      initialTime: initialTimeOfDay,
                    );
                    if (picked != null && parentContext.mounted) {
                      setState(() {
                        _entries[index].timeTaken = AppTimeFormatter.formatTimeOfDay(picked);
                        _entries[index].isTaken = true;
                      });
                      _syncChanges();
                    }
                  },
                  icon: const Icon(
                    Icons.schedule,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  label: Text(
                    'Choose Custom Time...',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatAmPm(String time24) {
    final parts = time24.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    return hour < 12 ? 'AM' : 'PM';
  }
}
