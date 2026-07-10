import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/home/presentation/widgets/dose_change_alert.dart';
import 'package:eunora/features/onboarding/presentation/widgets/add_medication_modal.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';

enum HrtLogStatus { pending, taken, skipped }

class SuccessCheckmark extends StatefulWidget {
  const SuccessCheckmark({super.key});

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark> with SingleTickerProviderStateMixin {
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
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
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
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 14,
        ),
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
  });

  /// Parse from the `Map<String, String>` format.
  factory HrtEditEntry.fromMap(Map<String, String> map) {
    final isTaken = map['isTaken'] == 'true';
    final details = map['details'] ?? '';
    // Parse dose and unit from details like '50 mcg · Patch'
    final detailParts = details.split('·');
    String dose = '50';
    String unit = 'mcg';
    String applicationType = 'Patch';
    if (detailParts.isNotEmpty) {
      final doseStr = detailParts.first.trim();
      final doseMatch = RegExp(r'(\d+)\s*(\w+)').firstMatch(doseStr);
      if (doseMatch != null) {
        dose = doseMatch.group(1) ?? '50';
        unit = doseMatch.group(2) ?? 'mcg';
      }
    }
    if (detailParts.length > 1) {
      applicationType = detailParts[1].trim();
    }

    // Parse time from status like 'Taken 08:30'
    String timeTaken = '08:00';
    final statusStr = map['status'] ?? '';
    final timeMatch = RegExp(r'(\d{1,2}:\d{2})').firstMatch(statusStr);
    if (timeMatch != null) {
      timeTaken = timeMatch.group(1) ?? '08:00';
    }

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
    );
  }

  Map<String, String> toMap() {
    return {
      if (id != null) 'id': id!,
      'name': name,
      'details': '$dose $unit · $applicationType',
      'status': isTaken ? 'Taken $timeTaken' : 'Not taken',
      'isTaken': isTaken.toString(),
    };
  }
}

class CalendarHrtEditSheet extends ConsumerStatefulWidget {
  final List<Map<String, String>> initialHrt;
  final void Function(List<Map<String, String>> updated) onSave;

  const CalendarHrtEditSheet({
    super.key,
    required this.initialHrt,
    required this.onSave,
  });

  @override
  ConsumerState<CalendarHrtEditSheet> createState() => _CalendarHrtEditSheetState();
}

class _CalendarHrtEditSheetState extends ConsumerState<CalendarHrtEditSheet> {
  late List<HrtEditEntry> _entries;
  int? _expandedIndex; // which card is expanded for editing
  late Map<int, DateTime> _lastTakenDates;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialHrt.map(HrtEditEntry.fromMap).toList();
    _lastTakenDates = {
      0: DateTime.now().subtract(const Duration(days: 2)),
      1: DateTime.now().subtract(const Duration(days: 1)),
      2: DateTime.now().subtract(const Duration(days: 1)),
    };
  }

  String _formatDate(DateTime dt) {
    return "${dt.day} ${_getMonthName(dt.month)}";
  }

  bool _isScheduledToday(String name, DateTime? lastTaken) {
    String freq = 'daily';
    if (name.toLowerCase().contains('estradiol')) {
      freq = 'twice weekly';
    } else if (name.toLowerCase().contains('gel')) {
      freq = 'every 2 days';
    }

    if (freq == 'daily') {
      return true;
    }
    if (lastTaken == null) {
      return true;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(lastTaken.year, lastTaken.month, lastTaken.day);
    final daysDiff = today.difference(thatDay).inDays;

    if (freq.contains('twice weekly')) {
      return daysDiff >= 3;
    }
    if (freq.contains('every 2 days')) {
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
    final lastTaken = _lastTakenDates[index];
    final isScheduled = _isScheduledToday(entry.name, lastTaken);
    return isScheduled ? HrtLogStatus.pending : HrtLogStatus.skipped;
  }

  String _formatDateTime(DateTime dt, BuildContext context) {
    final dateStr = "${dt.day} ${_getMonthName(dt.month)}";
    if (context.mounted) {
      final timeStr = TimeOfDay(hour: dt.hour, minute: dt.minute).format(context);
      return "$dateStr, $timeStr";
    }
    return dateStr;
  }

  String _getMonthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
    });
  }

  void _setDose(int index, String dose) {
    setState(() {
      _entries[index].dose = dose;
    });
  }

  void _toggleExpanded(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  List<double> _getAvailableDoses(String unit) {
    final u = unit.toLowerCase();
    if (u == 'mcg') {
      return [12.5, 25.0, 37.5, 50.0, 62.5, 75.0, 87.5, 100.0, 112.5, 125.0, 150.0, 175.0, 200.0, 250.0];
    } else if (u == 'mg') {
      return [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 10.0, 20.0, 50.0, 100.0, 150.0, 200.0, 300.0, 400.0];
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
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: const Color(0xFF8A817C)),
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
                      final initialEntries = widget.initialHrt.map(HrtEditEntry.fromMap).toList();
                      double initialDose = 0;
                      if (index < initialEntries.length) {
                        initialDose = double.tryParse(initialEntries[index].dose) ?? 0;
                      }

                      if (initialDose > 0 && (tempDose - initialDose).abs() > 0.01) {
                        showDialog(
                          context: this.context,
                          barrierDismissible: false,
                          barrierColor: const Color(0xFF1D1B1A).withOpacity(0.4),
                          builder: (dialogContext) {
                            return DoseChangeAlert(
                              change: {
                                'name': _entries[index].name,
                                'oldDose': '${initialDose.toStringAsFixed(initialDose == initialDose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), '')} $unit',
                                'newDose': '${tempDose.toStringAsFixed(tempDose == tempDose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), '')} $unit',
                              },
                              onConfirm: () {
                                Navigator.pop(dialogContext);
                                onDoseChanged(tempDose);
                                Navigator.pop(context);
                              },
                              onCancel: () {
                                Navigator.pop(dialogContext);
                              },
                            );
                          },
                        );
                      } else {
                        onDoseChanged(tempDose);
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      'Done',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  itemExtent: 44,
                  onSelectedItemChanged: (index) {
                    tempDose = doses[index];
                  },
                  children: doses.map((d) {
                    return Center(
                      child: Text(
                        d.toStringAsFixed(d == d.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), ''),
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

  void _showDoseChangeWarningDialog(Map<String, dynamic> change) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF1D1B1A).withOpacity(0.4),
      builder: (context) {
        return DoseChangeAlert(
          change: change,
          onConfirm: () {
            Navigator.pop(context);
            widget.onSave(_entries.map((e) => e.toMap()).toList());
            Navigator.pop(this.context);
          },
          onCancel: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _save() {
    Map<String, dynamic>? primaryChange;
    final initialEntries = widget.initialHrt.map(HrtEditEntry.fromMap).toList();
    for (int i = 0; i < _entries.length; i++) {
      if (i < initialEntries.length) {
        if (_entries[i].dose != initialEntries[i].dose || _entries[i].unit != initialEntries[i].unit) {
          primaryChange = {
            'name': _entries[i].name,
            'oldDose': '${initialEntries[i].dose} ${initialEntries[i].unit}',
            'newDose': '${_entries[i].dose} ${_entries[i].unit}',
          };
          break;
        }
      }
    }

    if (primaryChange != null) {
      _showDoseChangeWarningDialog(primaryChange);
    } else {
      widget.onSave(_entries.map((e) => e.toMap()).toList());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically listen to medicationsProvider updates
    ref.listen(medicationsProvider, (previous, next) {
      if (previous != null) {
        // Detect newly added medications not already present in _entries
        for (final med in next.medications) {
          final exists = _entries.any((entry) => entry.name.toLowerCase() == med.name.toLowerCase());
          if (!exists) {
            final appType = med.type.displayName;
            setState(() {
              _entries.add(HrtEditEntry(
                name: med.name,
                details: '${med.dose.toStringAsFixed(0)} ${med.unit} · $appType',
                status: 'Not taken',
                isTaken: false,
                dose: med.dose.toStringAsFixed(0),
                unit: med.unit,
                applicationType: appType,
                timeTaken: '08:00',
              ));
              _lastTakenDates[_entries.length - 1] = DateTime.now().subtract(const Duration(days: 1));
            });
          }
        }
      }
    });

    return Container(
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
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EDEA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Color(0xFF9B8B7E), size: 20),
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

                  // Medication cards
                  ..._entries.asMap().entries.map((e) {
                    return _buildMedicationCard(e.key, e.value);
                  }),

                  const SizedBox(height: 12),

                  // Button to add custom HRT medications
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const AddMedicationModal(),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1.5),
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
                          const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 18),
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

                  const SizedBox(height: 16),

                  // Wellness tip box
                  _buildTipCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(int index, HrtEditEntry entry) {
    final isExpanded = _expandedIndex == index;
    final status = _getEntryStatus(entry, index);

    final icon = _getMedIcon(entry.name);
    final lastTaken = _lastTakenDates[index];
    final subtitle = entry.isTaken
        ? '${entry.dose} ${entry.unit} • ${entry.timeTaken}'
        : (lastTaken == null
            ? 'Not scheduled today'
            : 'Last taken: ${_formatDate(lastTaken)}');

    Color tileBgColor = Colors.white;
    Color tileBorderColor = const Color(0xFFF2EDEA);
    Color textColor = AppTheme.onSurface;
    Color subtitleColor = AppTheme.outline;
    Color iconColor = AppTheme.primary;
    Widget? trailingWidget;

    if (status == HrtLogStatus.taken) {
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
              'Taken',
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
    } else if (status == HrtLogStatus.pending) {
      tileBgColor = Colors.white;
      tileBorderColor = const Color(0xFFF2EDEA);
      textColor = AppTheme.onSurface;
      subtitleColor = AppTheme.outline;
      iconColor = AppTheme.primary;
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_calendar, color: AppTheme.primary, size: 10),
                const SizedBox(width: 4),
                Text(
                  'Ready to log',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
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
      tileBgColor = const Color(0xFFFFF6F4);
      tileBorderColor = const Color(0xFFFFE3DC);
      textColor = const Color(0xFF5A2518);
      subtitleColor = const Color(0xFF8C3A25).withValues(alpha: 0.7);
      iconColor = const Color(0xFF8C3A25);
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF8C3A25), size: 10),
                const SizedBox(width: 4),
                Text(
                  'Not scheduled today',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8C3A25),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF8C3A25)),
        ],
      );
    }

    Widget baseTile = Container(
      decoration: BoxDecoration(
        color: tileBgColor,
      ),
      child: ListTile(
        onTap: () => _toggleExpanded(index),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: status == HrtLogStatus.taken
                ? const Color(0xFFC7E8D5).withValues(alpha: 0.4)
                : status == HrtLogStatus.skipped
                    ? const Color(0xFFFFDAD3).withValues(alpha: 0.4)
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

    return Dismissible(
      key: Key('med_${entry.name}_$index'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left (endToStart): Mark HRT as not taken
          setState(() {
            _entries[index].isTaken = false;
            _entries[index].status = 'Not taken';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${entry.name} marked as not taken'),
              duration: const Duration(seconds: 1),
            ),
          );
          return false; // Don't actually dismiss (delete) the widget
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe right (startToEnd): Delete HRT medication
          final medName = entry.name;
          setState(() {
            _entries.removeAt(index);
            // Re-index remaining dates keys
            final Map<int, DateTime> newDates = {};
            _lastTakenDates.forEach((key, val) {
              if (key < index) {
                newDates[key] = val;
              } else if (key > index) {
                newDates[key - 1] = val;
              }
            });
            _lastTakenDates = newDates;
            if (_expandedIndex == index) {
              _expandedIndex = null;
            } else if (_expandedIndex != null && _expandedIndex! > index) {
              _expandedIndex = _expandedIndex! - 1;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$medName deleted'),
              duration: const Duration(seconds: 1),
            ),
          );
          return true; // Dismiss (delete) the widget
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.close, color: Colors.white),
      ),
      child: AnimatedContainer(
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
              if (isExpanded) ...[
                _buildExpandedPanel(index, entry),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(int index, HrtEditEntry entry) {
    final lastTaken = _lastTakenDates[index];
    final onboardingMeds = _entries;

    List<String> unitOptions = ['mg', 'mcg'];
    if (entry.name.toLowerCase().contains('gel')) {
      unitOptions = ['pumps', 'mg'];
    }
    if (!unitOptions.contains(entry.unit)) {
      unitOptions.add(entry.unit);
    }
    for (var m in onboardingMeds) {
      if (!unitOptions.contains(m.unit)) {
        unitOptions.add(m.unit);
      }
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Taken today?',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
              ),
              CupertinoSwitch(
                value: entry.isTaken,
                activeColor: AppTheme.primary,
                onChanged: (val) {
                  setState(() {
                    entry.isTaken = val;
                    if (val) {
                      final now = TimeOfDay.now();
                      entry.timeTaken = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                    }
                  });
                },
              ),
            ],
          ),
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
                        style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF8A817C), letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          final currentDose = double.tryParse(entry.dose) ?? 1.0;
                          _openDosePicker(
                            index: index,
                            unit: entry.unit,
                            currentDose: currentDose,
                            onDoseChanged: (newDose) {
                              _setDose(
                                index,
                                newDose.toStringAsFixed(newDose == newDose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), ''),
                              );
                            },
                          );
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD0C4BC).withValues(alpha: 0.4)),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            entry.dose,
                            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
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
                        style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF8A817C), letterSpacing: 1),
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
                        style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF8A817C), letterSpacing: 1),
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
                            border: Border.all(color: const Color(0xFFD0C4BC).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.schedule, size: 14, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.timeTaken,
                                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
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
                        'Not scheduled for today',
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF8A817C)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastTaken == null
                            ? 'No last taken date recorded'
                            : 'Last taken: ${_formatDateTime(lastTaken, context)} (${_daysAgo(lastTaken)})',
                        style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
          const Icon(Icons.lightbulb_outline,
              color: AppTheme.primary, size: 20),
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF2EDEA))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                ),
                child: Text(
                  'Save changes',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                    final formatted = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                    setState(() {
                      _entries[index].timeTaken = formatted;
                      _entries[index].isTaken = true;
                    });
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.flash_on, color: Colors.white, size: 18),
                  label: Text(
                    'Set to Now (${TimeOfDay.now().format(context)})',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 15),
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
                    Navigator.pop(context);
                    final current = _entries[index].timeTaken.split(':');
                    final hour = int.tryParse(current.first) ?? 8;
                    final minute = int.tryParse(current.last) ?? 0;
                    final picked = await showTimePicker(
                      context: this.context,
                      initialTime: TimeOfDay(hour: hour, minute: minute),
                    );
                    if (picked != null) {
                      setState(() {
                        final h = picked.hour.toString().padLeft(2, '0');
                        final m = picked.minute.toString().padLeft(2, '0');
                        _entries[index].timeTaken = '$h:$m';
                        _entries[index].isTaken = true;
                      });
                    }
                  },
                  icon: const Icon(Icons.schedule, color: AppTheme.primary, size: 18),
                  label: Text(
                    'Choose Custom Time...',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1.5),
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
