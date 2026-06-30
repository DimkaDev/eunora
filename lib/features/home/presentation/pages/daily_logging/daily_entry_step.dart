import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/presentation/widgets/add_medication_modal.dart';
import 'package:eunora/features/onboarding/presentation/pages/other_medications_page.dart';
import 'package:eunora/features/onboarding/presentation/providers/other_medications_provider.dart';
import 'package:eunora/features/home/presentation/widgets/dose_change_alert.dart';

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

class DailyEntryStep extends ConsumerStatefulWidget {
  final bool estradiolChecked;
  final double estradiolDose;
  final String estradiolUnit;
  final String estradiolTime;
  final bool progesteroneChecked;
  final double progesteroneDose;
  final String progesteroneUnit;
  final String progesteroneTime;
  final bool vitaminDChecked;
  final bool magnesiumChecked;
  final double sleepDuration;
  final int hydrationCups;
  final String additionalNotes;

  final ValueChanged<bool> onEstradiolCheckedToggled;
  final ValueChanged<double> onEstradiolDoseChanged;
  final ValueChanged<String> onEstradiolUnitChanged;
  final ValueChanged<String> onEstradiolTimeChanged;
  final ValueChanged<bool> onProgesteroneCheckedToggled;
  final ValueChanged<double> onProgesteroneDoseChanged;
  final ValueChanged<String> onProgesteroneUnitChanged;
  final ValueChanged<String> onProgesteroneTimeChanged;
  final ValueChanged<bool> onVitaminDCheckedToggled;
  final ValueChanged<bool> onMagnesiumCheckedToggled;
  final ValueChanged<double> onSleepDurationChanged;
  final ValueChanged<int> onHydrationCupsChanged;
  final ValueChanged<String> onAdditionalNotesChanged;

  final Map<String, bool> otherMedsChecked;
  final ValueChanged<Map<String, bool>> onOtherMedsChanged;

  const DailyEntryStep({
    super.key,
    required this.estradiolChecked,
    required this.estradiolDose,
    required this.estradiolUnit,
    required this.estradiolTime,
    required this.progesteroneChecked,
    required this.progesteroneDose,
    required this.progesteroneUnit,
    required this.progesteroneTime,
    required this.vitaminDChecked,
    required this.magnesiumChecked,
    required this.sleepDuration,
    required this.hydrationCups,
    required this.additionalNotes,
    required this.otherMedsChecked,
    required this.onOtherMedsChanged,
    required this.onEstradiolCheckedToggled,
    required this.onEstradiolDoseChanged,
    required this.onEstradiolUnitChanged,
    required this.onEstradiolTimeChanged,
    required this.onProgesteroneCheckedToggled,
    required this.onProgesteroneDoseChanged,
    required this.onProgesteroneUnitChanged,
    required this.onProgesteroneTimeChanged,
    required this.onVitaminDCheckedToggled,
    required this.onMagnesiumCheckedToggled,
    required this.onSleepDurationChanged,
    required this.onHydrationCupsChanged,
    required this.onAdditionalNotesChanged,
  });

  @override
  ConsumerState<DailyEntryStep> createState() => _DailyEntryStepState();
}

class _DailyEntryStepState extends ConsumerState<DailyEntryStep> {
  int? _expandedIndex;
  DateTime? _estradiolLastTaken = DateTime.now().subtract(const Duration(days: 2));
  DateTime? _progesteroneLastTaken = DateTime.now().subtract(const Duration(days: 1));

  // 3rd element states (Estrogen Gel, Every 2 days, taken 1 day ago -> Not scheduled today)
  bool _estrogenGelChecked = false;
  double _estrogenGelDose = 2.0;
  String _estrogenGelUnit = 'pumps';
  String _estrogenGelTime = '09:00 AM';
  DateTime? _estrogenGelLastTaken = DateTime.now().subtract(const Duration(days: 1));
  double? _initialEstrogenGelDose = 2.0;

  double? _initialEstradiolDose;
  double? _initialProgesteroneDose;

  bool _isScheduledToday(String frequency, DateTime? lastTaken) {
    if (frequency.toLowerCase() == 'daily') {
      return true;
    }
    if (lastTaken == null) {
      return true;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(lastTaken.year, lastTaken.month, lastTaken.day);
    final daysDiff = today.difference(thatDay).inDays;

    if (frequency.toLowerCase().contains('twice weekly')) {
      return daysDiff >= 3;
    }
    if (frequency.toLowerCase().contains('every 2 days')) {
      return daysDiff >= 2;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _initialEstradiolDose = widget.estradiolDose;
    _initialProgesteroneDose = widget.progesteroneDose;
  }

  String _formatDate(DateTime dt) {
    return "${dt.day} ${_getMonthName(dt.month)}";
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

  List<double> _getAvailableDoses(String unit) {
    final u = unit.toLowerCase();
    if (u == 'mcg') {
      return [12.5, 25.0, 37.5, 50.0, 62.5, 75.0, 87.5, 100.0, 112.5, 125.0, 150.0, 175.0, 200.0, 250.0];
    } else if (u == 'mg') {
      return [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 10.0, 20.0, 50.0, 100.0, 150.0, 200.0, 300.0, 400.0];
    } else {
      return List.generate(10, (i) => (i + 1).toDouble());
    }
  }

  void _openDosePicker({
    required String medName,
    required String unit,
    required double initialDose,
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
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD0C4BC).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(100),
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
                      if ((tempDose - initialDose).abs() > 0.01) {
                        showDialog(
                          context: this.context,
                          barrierDismissible: false,
                          barrierColor: const Color(0xFF1D1B1A).withOpacity(0.4),
                          builder: (dialogContext) {
                            return DoseChangeAlert(
                              change: {
                                'name': medName,
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

  void _openTimeSelector({
    required BuildContext context,
    required String currentTime,
    required ValueChanged<String> onTimeChanged,
  }) {
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
                    final formatted = now.format(context);
                    onTimeChanged(formatted);
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
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      if (context.mounted) {
                        onTimeChanged(picked.format(context));
                      }
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

  Widget _buildInlineMedicationDetails(String medKey) {
    bool isEstradiol = medKey == 'estradiol';
    bool isProgesterone = medKey == 'progesterone';

    bool checked;
    double dose;
    String unit;
    String time;
    DateTime? lastTaken;
    double initialDose;
    String medName;

    if (isEstradiol) {
      checked = widget.estradiolChecked;
      dose = widget.estradiolDose;
      unit = widget.estradiolUnit;
      time = widget.estradiolTime;
      lastTaken = _estradiolLastTaken;
      initialDose = _initialEstradiolDose ?? dose;
      final medications = ref.read(medicationsProvider).medications;
      final med = medications.firstWhere((m) => m.name.toLowerCase().contains('estradiol') || m.name.toLowerCase().contains('estrogen') || m.name.toLowerCase().contains('estradot'), orElse: () => Medication(name: 'Estradiol Patch', type: MedicationType.patch, dose: 0.05, unit: 'mg', frequency: 'Daily'));
      medName = med.name;
    } else if (isProgesterone) {
      checked = widget.progesteroneChecked;
      dose = widget.progesteroneDose;
      unit = widget.progesteroneUnit;
      time = widget.progesteroneTime;
      lastTaken = _progesteroneLastTaken;
      initialDose = _initialProgesteroneDose ?? dose;
      final medications = ref.read(medicationsProvider).medications;
      final med = medications.firstWhere((m) => m.name.toLowerCase().contains('progesterone') || m.name.toLowerCase().contains('utrogestan'), orElse: () => Medication(name: 'Progesterone', type: MedicationType.pill, dose: 100, unit: 'mg', frequency: 'Daily'));
      medName = med.name;
    } else {
      checked = _estrogenGelChecked;
      dose = _estrogenGelDose;
      unit = _estrogenGelUnit;
      time = _estrogenGelTime;
      lastTaken = _estrogenGelLastTaken;
      initialDose = _initialEstrogenGelDose ?? dose;
      medName = 'Estrogen Gel';
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
                value: checked,
                activeColor: AppTheme.primary,
                onChanged: (val) {
                  if (isEstradiol) {
                    widget.onEstradiolCheckedToggled(val);
                  } else if (isProgesterone) {
                    widget.onProgesteroneCheckedToggled(val);
                  } else {
                    setState(() {
                      _estrogenGelChecked = val;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (checked) ...[
            Row(
              children: [
                // Dose selection field
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
                        onTap: () => _openDosePicker(
                          medName: medName,
                          unit: unit,
                          initialDose: initialDose,
                          currentDose: dose,
                          onDoseChanged: (newDose) {
                            if (isEstradiol) {
                              widget.onEstradiolDoseChanged(newDose);
                            } else if (isProgesterone) {
                              widget.onProgesteroneDoseChanged(newDose);
                            } else {
                              setState(() {
                                _estrogenGelDose = newDose;
                              });
                            }
                          },
                        ),
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
                            dose.toStringAsFixed(dose == dose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), ''),
                            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Unit selection field
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
                          unit,
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
                // Time selection field
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
                        onTap: () => _openTimeSelector(
                          context: context,
                          currentTime: time,
                          onTimeChanged: (formattedTime) {
                            if (isEstradiol) {
                              widget.onEstradiolTimeChanged(formattedTime);
                            } else if (isProgesterone) {
                              widget.onProgesteroneTimeChanged(formattedTime);
                            } else {
                              setState(() {
                                _estrogenGelTime = formattedTime;
                              });
                            }
                          },
                        ),
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
                                  time,
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

  Widget _buildMedRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required HrtLogStatus status,
    required VoidCallback onTap,
  }) {
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

    return Container(
      decoration: BoxDecoration(
        color: tileBgColor,
      ),
      child: ListTile(
        onTap: onTap,
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
          title,
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
  }

  Widget _buildSupplementRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool checked,
    required ValueChanged<bool?> onCheckedChange,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: const Color(0xFFEDDDF5).withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
      subtitle: Text(subtitle, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.outline)),
      trailing: AnimatedCheckbox(
        value: checked,
        onChanged: (val) => onCheckedChange(val),
        activeColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medications = ref.watch(medicationsProvider).medications;
    final otherMedications = ref.watch(otherMedicationsProvider).medications;

    final isEstradiolScheduled = _isScheduledToday('Twice weekly', _estradiolLastTaken);
    final estradiolStatus = widget.estradiolChecked
        ? HrtLogStatus.taken
        : (isEstradiolScheduled ? HrtLogStatus.pending : HrtLogStatus.skipped);

    final isProgesteroneScheduled = _isScheduledToday('Daily', _progesteroneLastTaken);
    final progesteroneStatus = widget.progesteroneChecked
        ? HrtLogStatus.taken
        : (isProgesteroneScheduled ? HrtLogStatus.pending : HrtLogStatus.skipped);

    final isEstrogenGelScheduled = _isScheduledToday('Every 2 days', _estrogenGelLastTaken);
    final estrogenGelStatus = _estrogenGelChecked
        ? HrtLogStatus.taken
        : (isEstrogenGelScheduled ? HrtLogStatus.pending : HrtLogStatus.skipped);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Log HRT, Sleep & Hydration',
          style: GoogleFonts.notoSerif(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Record your hormone replacement therapy, sleep duration, and water intake for today.',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppTheme.outline,
          ),
        ),
        const SizedBox(height: 28),

        // HRT SECTION
        Text(
          'HRT MEDICATIONS',
          style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Column(
              children: [
                if (medications.any((m) => m.name.toLowerCase().contains('estradiol') || m.name.toLowerCase().contains('estrogen') || m.name.toLowerCase().contains('estradot'))) ...[
                  (() {
                    final med = medications.firstWhere((m) => m.name.toLowerCase().contains('estradiol') || m.name.toLowerCase().contains('estrogen') || m.name.toLowerCase().contains('estradot'));
                    return Column(
                      children: [
                        _buildMedRow(
                          title: med.name,
                          subtitle: widget.estradiolChecked
                              ? '${widget.estradiolDose.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} ${widget.estradiolUnit} • ${widget.estradiolTime}'
                              : (_estradiolLastTaken == null
                                  ? 'Not scheduled today'
                                  : 'Last taken: ${_formatDate(_estradiolLastTaken!)}'),
                          icon: Icons.medication,
                          status: estradiolStatus,
                          onTap: () {
                            setState(() {
                              _expandedIndex = _expandedIndex == 0 ? null : 0;
                            });
                          },
                        ),
                        if (_expandedIndex == 0) _buildInlineMedicationDetails('estradiol'),
                        const Divider(color: Color(0xFFF2EDEA), height: 1),
                      ],
                    );
                  })(),
                ],
                if (medications.any((m) => m.name.toLowerCase().contains('progesterone') || m.name.toLowerCase().contains('utrogestan'))) ...[
                  (() {
                    final med = medications.firstWhere((m) => m.name.toLowerCase().contains('progesterone') || m.name.toLowerCase().contains('utrogestan'));
                    return Column(
                      children: [
                        _buildMedRow(
                          title: med.name,
                          subtitle: widget.progesteroneChecked
                              ? '${widget.progesteroneDose.toStringAsFixed(0)} ${widget.progesteroneUnit} • ${widget.progesteroneTime}'
                              : (_progesteroneLastTaken == null
                                  ? 'Not scheduled today'
                                  : 'Last taken: ${_formatDate(_progesteroneLastTaken!)}'),
                          icon: Icons.medication,
                          status: progesteroneStatus,
                          onTap: () {
                            setState(() {
                              _expandedIndex = _expandedIndex == 1 ? null : 1;
                            });
                          },
                        ),
                        if (_expandedIndex == 1) _buildInlineMedicationDetails('progesterone'),
                        const Divider(color: Color(0xFFF2EDEA), height: 1),
                      ],
                    );
                  })(),
                ],
                if (medications.isEmpty || medications.any((m) => !m.name.toLowerCase().contains('estradiol') && !m.name.toLowerCase().contains('estrogen') && !m.name.toLowerCase().contains('estradot') && !m.name.toLowerCase().contains('progesterone') && !m.name.toLowerCase().contains('utrogestan'))) ...[
                  (() {
                    final med = medications.firstWhere(
                      (m) => !m.name.toLowerCase().contains('estradiol') && !m.name.toLowerCase().contains('estrogen') && !m.name.toLowerCase().contains('estradot') && !m.name.toLowerCase().contains('progesterone') && !m.name.toLowerCase().contains('utrogestan'),
                      orElse: () => Medication(name: 'Estrogen Gel', type: MedicationType.gel, dose: 1, unit: 'g', frequency: 'Every 2 days'),
                    );
                    return Column(
                      children: [
                        _buildMedRow(
                          title: med.name,
                          subtitle: _estrogenGelChecked
                              ? '${_estrogenGelDose.toStringAsFixed(0)} $_estrogenGelUnit • $_estrogenGelTime'
                              : (_estrogenGelLastTaken == null
                                  ? 'Not scheduled today'
                                  : 'Last taken: ${_formatDate(_estrogenGelLastTaken!)}'),
                          icon: Icons.opacity,
                          status: estrogenGelStatus,
                          onTap: () {
                            setState(() {
                              _expandedIndex = _expandedIndex == 2 ? null : 2;
                            });
                          },
                        ),
                        if (_expandedIndex == 2) _buildInlineMedicationDetails('estrogen_gel'),
                      ],
                    );
                  })(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
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
                Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 18),
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
        const SizedBox(height: 24),

        // SUPPLEMENTS SECTION
        Text(
          'OTHER DAILY SUPPLEMENTS',
          style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Column(
              children: [
                if (otherMedications.isEmpty) ...[
                  _buildSupplementRow(
                    title: 'Daily Vitamin D',
                    subtitle: '2000 IU • With Food',
                    icon: Icons.spa,
                    checked: widget.vitaminDChecked,
                    onCheckedChange: (val) => widget.onVitaminDCheckedToggled(val!),
                  ),
                  const Divider(color: Color(0xFFF2EDEA), height: 1),
                  _buildSupplementRow(
                    title: 'Magnesium Glycinate',
                    subtitle: '200 mg • Before Sleep',
                    icon: Icons.spa,
                    checked: widget.magnesiumChecked,
                    onCheckedChange: (val) => widget.onMagnesiumCheckedToggled(val!),
                  ),
                ] else ...[
                  for (int i = 0; i < otherMedications.length; i++) ...[
                    (() {
                      final med = otherMedications[i];
                      return _buildSupplementRow(
                        title: med.name,
                        subtitle: '${med.dose ?? ''} • ${med.frequency ?? ''}',
                        icon: Icons.spa,
                        checked: widget.otherMedsChecked[med.id] ?? false,
                        onCheckedChange: (val) {
                          final newMap = Map<String, bool>.from(widget.otherMedsChecked);
                          newMap[med.id] = val!;
                          widget.onOtherMedsChanged(newMap);

                          // Also sync with parent default checks if names match
                          final nameLower = med.name.toLowerCase();
                          if (nameLower.contains('vitamin d')) {
                            widget.onVitaminDCheckedToggled(val);
                          } else if (nameLower.contains('magnesium')) {
                            widget.onMagnesiumCheckedToggled(val);
                          }
                        },
                      );
                    })(),
                    if (i < otherMedications.length - 1)
                      const Divider(color: Color(0xFFF2EDEA), height: 1),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddOtherMedicationModal(),
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
                Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Add Supplement',
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
        const SizedBox(height: 24),

        // SLIDERS SECTION (Sleep & Hydration)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.surfaceContainer),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.brightness_3, color: Color(0xFF8B5CF6), size: 18),
                      const SizedBox(width: 8),
                      Text('Sleep Duration', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('${widget.sleepDuration}', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                      const SizedBox(width: 4),
                      Text('hrs', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.outline)),
                    ],
                  )
                ],
              ),
              Slider(
                value: widget.sleepDuration,
                min: 0,
                max: 12,
                divisions: 24,
                activeColor: AppTheme.primary,
                onChanged: widget.onSleepDurationChanged,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Color(0xFF0EA5E9), size: 18),
                      const SizedBox(width: 8),
                      Text('Hydration', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('${widget.hydrationCups}', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                      const SizedBox(width: 4),
                      Text('cups', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.outline)),
                    ],
                  )
                ],
              ),
              Slider(
                value: widget.hydrationCups.toDouble(),
                min: 0,
                max: 15,
                divisions: 15,
                activeColor: AppTheme.primary,
                onChanged: (val) => widget.onHydrationCupsChanged(val.toInt()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // NOTES
        Text(
          'ADDITIONAL NOTES',
          style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: widget.additionalNotes,
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFD0C4BC))),
            hintText: 'How are you feeling today? Any specific symptoms?',
            hintStyle: GoogleFonts.notoSerif(fontStyle: FontStyle.italic, color: Colors.grey.withOpacity(0.6)),
          ),
          style: GoogleFonts.manrope(fontSize: 14),
          onChanged: widget.onAdditionalNotesChanged,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
