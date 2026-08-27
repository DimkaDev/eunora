import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/home/presentation/widgets/calendar_hrt_edit_sheet.dart';
import 'package:eunora/features/onboarding/presentation/widgets/add_medication_modal.dart';
import 'package:eunora/features/home/presentation/widgets/hrt_quick_edit_modal.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';

import 'package:eunora/features/home/presentation/widgets/hrt_tracker/hrt_adherence_card.dart';
import 'package:eunora/features/hrt_tracker/domain/adherence_constants.dart';
import 'package:eunora/features/hrt_tracker/domain/hrt_schedule_service.dart';
import 'package:eunora/features/hrt_tracker/presentation/widgets/still_taking_check_in_card.dart';

class HrtTrackerPage extends ConsumerStatefulWidget {
  const HrtTrackerPage({super.key});

  @override
  ConsumerState<HrtTrackerPage> createState() => _HrtTrackerPageState();
}

class _HrtTrackerPageState extends ConsumerState<HrtTrackerPage> {
  DateTime _focusedMonth = DateTime.now();
  late int _selectedDay;

  Map<int, DailyLog> _monthlyLogs = {};
  List<HrtDoseChange> _monthlyDoseChanges = [];
  bool _isLoadingLogs = false;

  // Swipe transition states
  bool _isSwiping = false;
  double _dragOffset = 0.0;

  // Cache for pre-fetched logs to ensure smooth side-by-side swipes
  final Map<String, Map<int, DailyLog>> _monthLogsCache = {};
  final Map<String, List<HrtDoseChange>> _monthDoseChangesCache = {};
  final Set<String> _dismissedCheckIns = {};

  final List<String> _monthsNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  Map<Medication, int> _getUnmarkedCheckInMedications(List<Medication> activeMedications) {
    final Map<Medication, int> checkIns = {};
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    for (final med in activeMedications) {
      if (med.endedAt != null) continue; // Already stopped medications NEVER trigger check-in
      if (_dismissedCheckIns.contains(med.id)) continue;

      // 1. Medication MUST have existed for at least 14 days
      if (med.startedAt == null) continue;
      final startOnly = DateTime(med.startedAt!.year, med.startedAt!.month, med.startedAt!.day);
      final daysExisted = todayOnly.difference(startOnly).inDays;

      if (daysExisted < AdherenceConstants.kUnmarkedDaysCheckInThreshold) {
        // Younger than 14 days -> NEVER render check-in banner
        continue;
      }

      int unmarkedStreak = 0;
      // 2. Check for a genuine 14-day gap in logged adherence
      for (int i = 1; i <= AdherenceConstants.kUnmarkedDaysCheckInThreshold; i++) {
        final date = todayOnly.subtract(Duration(days: i));
        if (date.isBefore(startOnly)) {
          break;
        }

        final monthKey = _monthKey(date);
        final monthLogs = _monthLogsCache[monthKey];
        final dayLog = monthLogs?[date.day];

        final intake = dayLog?.hrtIntakes.firstWhere(
          (h) => h.medicationId == med.id || h.name.toLowerCase() == med.name.toLowerCase(),
          orElse: () => HrtIntakeLog(medicationId: med.id, name: med.name, dose: med.dose, unit: med.unit, time: '', isTaken: false),
        );

        if (intake != null && intake.isTaken) {
          break; // Streak broken by taken intake
        } else {
          unmarkedStreak++;
        }
      }

      if (unmarkedStreak >= AdherenceConstants.kUnmarkedDaysCheckInThreshold) {
        checkIns[med] = unmarkedStreak;
      }
    }

    return checkIns;
  }

  List<Widget> _buildStillTakingCheckInBanners(List<Medication> activeMedications) {
    final checkIns = _getUnmarkedCheckInMedications(activeMedications);
    if (checkIns.isEmpty) return [];

    return checkIns.entries.map((entry) {
      final med = entry.key;
      final consecutiveDays = entry.value;

      return StillTakingCheckInCard(
        medication: med,
        consecutiveUnmarkedDays: consecutiveDays,
        onConfirmStillTaking: () {
          setState(() {
            _dismissedCheckIns.add(med.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Confirmed active for ${med.name}. Check-in reset.',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onConfirmStoppedTaking: () {
          final today = DateTime.now();
          final defaultStopDate = today.subtract(Duration(days: consecutiveDays));
          _showStopMedicationModalSheet(context, ref, med, defaultStopDate);
        },
      );
    }).toList();
  }

  void _showStopMedicationModalSheet(
    BuildContext context,
    WidgetRef ref,
    Medication medication,
    DateTime defaultStopDate,
  ) {
    final today = DateTime.now();
    DateTime selectedStopDate = defaultStopDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDefault = selectedStopDate.year == defaultStopDate.year &&
              selectedStopDate.month == defaultStopDate.month &&
              selectedStopDate.day == defaultStopDate.day;
          final isToday = selectedStopDate.year == today.year &&
              selectedStopDate.month == today.month &&
              selectedStopDate.day == today.day;
          final isCustom = !isDefault && !isToday;

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFEF8F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Stop Taking ${medication.name}',
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1D1B1A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF9B8B7E)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Select when you stopped taking this medication to archive it accurately.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF78716C),
                  ),
                ),
                const SizedBox(height: 20),
                _buildStopOptionTile(
                  title: 'When logging stopped (${_monthsNames[defaultStopDate.month - 1].substring(0, 3)} ${defaultStopDate.day}, ${defaultStopDate.year})',
                  isSelected: isDefault,
                  onTap: () => setModalState(() => selectedStopDate = defaultStopDate),
                ),
                const SizedBox(height: 10),
                _buildStopOptionTile(
                  title: 'Today (${_monthsNames[today.month - 1].substring(0, 3)} ${today.day}, ${today.year})',
                  isSelected: isToday,
                  onTap: () => setModalState(() => selectedStopDate = today),
                ),
                const SizedBox(height: 10),
                _buildStopOptionTile(
                  title: isCustom
                      ? 'Custom date (${_monthsNames[selectedStopDate.month - 1].substring(0, 3)} ${selectedStopDate.day}, ${selectedStopDate.year})'
                      : 'Pick a custom date...',
                  isSelected: isCustom,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: defaultStopDate,
                      firstDate: medication.startedAt ?? DateTime(2000),
                      lastDate: today,
                    );
                    if (picked != null) {
                      setModalState(() => selectedStopDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(medicationsProvider.notifier).endMedication(
                        medication.id,
                        endDate: selectedStopDate,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${medication.name} stopped as of ${_monthsNames[selectedStopDate.month - 1].substring(0, 3)} ${selectedStopDate.day}, ${selectedStopDate.year}',
                            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF67594E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Confirm Stop Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStopOptionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE7E5E4),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primary : const Color(0xFFA8A29E),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppTheme.primary : const Color(0xFF1D1B1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().day;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(medicationsProvider.notifier).loadFromFirestore();
      _fetchLogsForFocusedMonth();
    });
  }

  String _monthKey(DateTime dt) => "${dt.year}-${dt.month}";

  Future<void> _fetchLogsForFocusedMonth() async {
    await _fetchLogsForMonth(_focusedMonth);
    // Prefetch surrounding months for seamless swiping
    _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month - 1));
    _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month + 1));
  }

  Future<void> _fetchLogsForMonth(DateTime targetMonth) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final key = _monthKey(targetMonth);
    final isFocusedMonth = targetMonth.year == _focusedMonth.year && targetMonth.month == _focusedMonth.month;

    if (_monthLogsCache.containsKey(key)) {
      if (isFocusedMonth) {
        setState(() {
          _monthlyLogs = _monthLogsCache[key] ?? {};
          _monthlyDoseChanges = _monthDoseChangesCache[key] ?? [];
          _isLoadingLogs = false;
        });
      }
      return;
    }

    if (isFocusedMonth && mounted) {
      setState(() {
        _isLoadingLogs = true;
      });
    }

    try {
      final daysInMonth = DateUtils.getDaysInMonth(targetMonth.year, targetMonth.month);
      final start = DateTime(targetMonth.year, targetMonth.month, 1);
      final end = DateTime(targetMonth.year, targetMonth.month, daysInMonth, 23, 59, 59);

      final rawDbLogs = await ref.read(firestoreServiceProvider).getDailyLogsHistory(user.uid, start, end);
      // Only show completed logs in the HRT tracker — drafts should not appear
      final dbLogs = rawDbLogs.where((l) => l.isCompleted).toList();
      final allDoseChanges = await ref.read(firestoreServiceProvider).getHrtDoseChanges(user.uid);

      final Map<int, DailyLog> fetchedLogs = {};
      for (final log in dbLogs) {
        fetchedLogs[log.date.day] = log;
      }

      final monthlyChanges = allDoseChanges.where((change) {
        return change.changeDate.year == targetMonth.year &&
               change.changeDate.month == targetMonth.month;
      }).toList();

      _monthLogsCache[key] = fetchedLogs;
      _monthDoseChangesCache[key] = monthlyChanges;

      if (mounted && targetMonth.year == _focusedMonth.year && targetMonth.month == _focusedMonth.month) {
        setState(() {
          _monthlyLogs = fetchedLogs;
          _monthlyDoseChanges = monthlyChanges;
          _isLoadingLogs = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching HRT logs for $key: $e");
      if (mounted && targetMonth.year == _focusedMonth.year && targetMonth.month == _focusedMonth.month) {
        setState(() {
          _isLoadingLogs = false;
        });
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _isSwiping = true;
      _dragOffset = 0.0;
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _selectedDay = 1;
    });
    _fetchLogsForFocusedMonth();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        setState(() {
          _isSwiping = false;
        });
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_focusedMonth.year > now.year || (_focusedMonth.year == now.year && _focusedMonth.month >= now.month)) {
      return; // Cannot navigate to future months
    }
    setState(() {
      _isSwiping = true;
      _dragOffset = 0.0;
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      final today = DateTime.now();
      if (_focusedMonth.year == today.year && _focusedMonth.month == today.month) {
        _selectedDay = math.min(_selectedDay, today.day);
      } else {
        _selectedDay = 1;
      }
    });
    _fetchLogsForFocusedMonth();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        setState(() {
          _isSwiping = false;
        });
      }
    });
  }

  void _selectDay(int day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    if (targetDate.isAfter(today)) return; // Disallow selecting future dates

    setState(() {
      _selectedDay = day;
    });
  }

  bool _isMedicationActiveOnDate(Medication med, DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    if (med.startedAt != null) {
      final start = DateTime(med.startedAt!.year, med.startedAt!.month, med.startedAt!.day);
      if (target.isBefore(start)) return false;
    }
    if (med.endedAt != null) {
      final end = DateTime(med.endedAt!.year, med.endedAt!.month, med.endedAt!.day);
      if (target.isAfter(end)) return false;
    }
    return true;
  }

  Future<void> _saveHrtLogForSelectedDate(Medication med, bool isTaken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetDate = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay);
    final dateStr = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

    final currentLog = await ref.read(firestoreServiceProvider).getDailyLog(user.uid, dateStr);

    final nowTime = TimeOfDay.now();
    final timeStr = "${nowTime.hour.toString().padLeft(2, '0')}:${nowTime.minute.toString().padLeft(2, '0')}";

    DailyLog dailyLog;
    if (currentLog != null) {
      final updatedIntakes = List<HrtIntakeLog>.from(currentLog.hrtIntakes);
      final existingIndex = updatedIntakes.indexWhere((h) => h.medicationId == med.id || h.name.toLowerCase() == med.name.toLowerCase());

      if (existingIndex != -1) {
        updatedIntakes[existingIndex] = updatedIntakes[existingIndex].copyWith(
          isTaken: isTaken,
          time: isTaken ? timeStr : updatedIntakes[existingIndex].time,
        );
      } else {
        updatedIntakes.add(HrtIntakeLog(
          medicationId: med.id,
          name: med.name,
          dose: med.dose,
          unit: med.unit,
          time: timeStr,
          isTaken: isTaken,
        ));
      }

      dailyLog = currentLog.copyWith(hrtIntakes: updatedIntakes);
    } else {
      final hrtIntake = HrtIntakeLog(
        medicationId: med.id,
        name: med.name,
        dose: med.dose,
        unit: med.unit,
        time: timeStr,
        isTaken: isTaken,
      );

      dailyLog = DailyLog(
        id: dateStr,
        userId: user.uid,
        date: targetDate,
        hrtIntakes: [hrtIntake],
        createdAt: DateTime.now(),
      );
    }

    await ref.read(firestoreServiceProvider).saveDailyLog(user.uid, dailyLog);
    _fetchLogsForFocusedMonth();
  }

  Future<void> _saveHrtLoggingSheet(List<Map<String, String>> updatedList) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetDate = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay);
    final dateStr = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

    final currentLog = await ref.read(firestoreServiceProvider).getDailyLog(user.uid, dateStr);

    final List<HrtIntakeLog> hrtIntakes = [];
    for (final updated in updatedList) {
      final name = updated['name'] ?? '';
      final isTaken = updated['isTaken'] == 'true';
      final status = updated['status'] ?? '';
      final details = updated['details'] ?? '';

      String time = '08:00';
      final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(status);
      if (match != null) {
        time = match.group(1) ?? '08:00';
      }

      double dose = 50.0;
      String unit = 'mcg';
      if (details.isNotEmpty) {
        final parts = details.split(' · ');
        if (parts.isNotEmpty) {
          final doseAndUnit = parts.first.trim().split(' ');
          if (doseAndUnit.isNotEmpty) {
            dose = double.tryParse(doseAndUnit.first) ?? 50.0;
            if (doseAndUnit.length > 1) {
              unit = doseAndUnit[1];
            }
          }
        }
      }

      final meds = ref.read(medicationsProvider).medications;
      final matchingMed = meds.firstWhere(
        (m) => m.name.toLowerCase() == name.toLowerCase(),
        orElse: () => Medication(name: name, type: MedicationType.other, dose: dose, unit: unit, frequency: ''),
      );

      hrtIntakes.add(HrtIntakeLog(
        medicationId: matchingMed.id,
        name: name,
        dose: dose,
        unit: unit,
        time: time,
        isTaken: isTaken,
      ));
    }

    DailyLog dailyLog;
    if (currentLog != null) {
      dailyLog = currentLog.copyWith(hrtIntakes: hrtIntakes);
    } else {
      dailyLog = DailyLog(
        id: dateStr,
        userId: user.uid,
        date: targetDate,
        hrtIntakes: hrtIntakes,
        createdAt: DateTime.now(),
      );
    }

    await ref.read(firestoreServiceProvider).saveDailyLog(user.uid, dailyLog);
    _fetchLogsForFocusedMonth();
  }

  void _showHrtLoggingSheet(List<Medication> medications) {
    final selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay);
    final allMeds = ref.read(medicationsProvider).medications;
    final relevantMeds = allMeds.where((m) => _isMedicationActiveOnDate(m, selectedDate)).toList();
    final targetLog = _monthlyLogs[_selectedDay];
    final hrtList = relevantMeds.map((med) {
      bool isTaken = false;
      String time = '08:00';

      if (targetLog != null) {
        final logged = targetLog.hrtIntakes.firstWhere(
          (h) => h.medicationId == med.id || h.name.toLowerCase() == med.name.toLowerCase(),
          orElse: () => HrtIntakeLog(medicationId: med.id, name: med.name, dose: med.dose, unit: med.unit, time: '08:00', isTaken: false),
        );
        isTaken = logged.isTaken;
        time = logged.time;
      }

      final appType = med.type.displayName;

      return {
        'id': med.id,
        'name': med.name,
        'details': '${med.dose.toStringAsFixed(0)} ${med.unit} · $appType',
        'status': isTaken ? 'Taken $time' : 'Not taken',
        'isTaken': isTaken.toString(),
        'dose': med.dose.toStringAsFixed(0),
        'unit': med.unit,
      };
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => CalendarHrtEditSheet(
          initialHrt: hrtList,
          selectedDate: DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay),
          onSave: (updatedList) async {
            // Delete removed medications first
            final updatedIds = updatedList.map((e) => e['id']).where((id) => id != null).toSet();
            for (final med in medications) {
              if (!updatedIds.contains(med.id)) {
                ref.read(medicationsProvider.notifier).removeOrStopMedication(
                  med: med,
                  logs: _monthlyLogs.values,
                );
              }
            }

            await _saveHrtLoggingSheet(updatedList);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Doses logged successfully!',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppTheme.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _addMockMedications() {
    final refNotifier = ref.read(medicationsProvider.notifier);

    final estradiol = Medication(
      name: 'Estradiol',
      type: MedicationType.patch,
      dose: 50,
      unit: 'mcg',
      frequency: 'Twice weekly',
    );
    final utrogestan = Medication(
      name: 'Utrogestan',
      type: MedicationType.pill,
      dose: 100,
      unit: 'mg',
      frequency: 'Bedtime',
    );

    refNotifier.addMedication(estradiol);
    refNotifier.addMedication(utrogestan);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added mock HRT medications protocol!',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF67594E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearMedications() {
    final refNotifier = ref.read(medicationsProvider.notifier);
    final meds = ref.read(medicationsProvider).medications;
    for (final med in meds) {
      refNotifier.removeMedication(med.id);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cleared all medications.',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8C3A25),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isArchivedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final medicationsState = ref.watch(medicationsProvider);
    final allMedications = medicationsState.medications;
    final activeMedications = allMedications.where((m) => m.endedAt == null).toList();
    final archivedMedications = allMedications.where((m) => m.endedAt != null).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: allMedications.isEmpty 
          ? _buildEmptyState() 
          : _buildDashboard(activeMedications, archivedMedications),
    );
  }

  // --- EMPTY STATE VIEW ---
  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glow Backdrop & Illustration
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFEDDDF5).withOpacity(0.5),
                          const Color(0xFFFEF8F6).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFE7E1DF),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.medication,
                      color: AppTheme.primary,
                      size: 64,
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9B7A9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 28,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8C9E0),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Welcoming Message
              Text(
                'Your HRT journey starts here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tracking your HRT helps Eunora find patterns in your cycle wellness.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Add First Medication Button
              ElevatedButton.icon(
                onPressed: _addMockMedications,
                icon: const Icon(Icons.add, size: 22),
                label: Text(
                  'Add Your First Medication',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppTheme.primary.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 16),
              
              // Manual configuration option
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddMedicationModal(),
                  );
                },
                child: Text(
                  'Configure manually',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DASHBOARD VIEW ---
  Widget _buildDashboard(List<Medication> activeMedications, List<Medication> archivedMedications) {
    final currentMonthLabel = '${_monthsNames[_focusedMonth.month - 1]} ${_focusedMonth.year}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HRT Tracker',
                        style: GoogleFonts.notoSerif(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your medications and see dose impact on symptoms.',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddMedicationModal(),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add Med', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Still Taking Check-In Prompts
            ..._buildStillTakingCheckInBanners(activeMedications),

            // Today's Dose Section (Active Medications)
            _buildTodayDoseSection(activeMedications),
            const SizedBox(height: 28),

            // Archived & Stopped Section
            if (archivedMedications.isNotEmpty) ...[
              _buildArchivedSection(archivedMedications),
              const SizedBox(height: 28),
            ],

            // Monthly Schedule Section
            _buildMonthlyScheduleSection(currentMonthLabel),
            const SizedBox(height: 24),

            // Adherence Section
            HrtAdherenceCard(
              focusedMonth: _focusedMonth,
              monthlyLogs: _monthlyLogs,
            ),
            const SizedBox(height: 32),

            // Quick tester reset option (Helper for reviewers)
            Center(
              child: TextButton.icon(
                onPressed: _clearMedications,
                icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF8C3A25)),
                label: Text(
                  'Reset to Empty State',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF8C3A25),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedSection(List<Medication> archivedMedications) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE6E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isArchivedExpanded = !_isArchivedExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B8B7E).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.archive_outlined, size: 18, color: Color(0xFF78716C)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Archived & Stopped (${archivedMedications.length})',
                        style: GoogleFonts.notoSerif(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4D453F),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isArchivedExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF9B8B7E),
                  ),
                ],
              ),
            ),
          ),
          if (_isArchivedExpanded) ...[
            const Divider(height: 1, color: Color(0xFFEAE6E0)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: archivedMedications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final med = archivedMedications[index];
                final stopDateStr = med.endedAt != null
                    ? '${_monthsNames[med.endedAt!.month - 1].substring(0, 3)} ${med.endedAt!.day}, ${med.endedAt!.year}'
                    : 'Stopped';
                return ListTile(
                  onTap: () => _openMedicationManagementSheet(med),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: const Color(0xFFF7F5F0),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAE6E0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history, color: Color(0xFF78716C), size: 20),
                  ),
                  title: Text(
                    med.name,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF4D453F),
                    ),
                  ),
                  subtitle: Text(
                    '${med.doseAndFrequency} • Stopped $stopDateStr',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF9B8B7E),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFA8A29E)),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _openMedicationManagementSheet(Medication med) {
    final hasHistory = HrtScheduleService.hasLoggedHistory(med, _monthlyLogs.values);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFEF8F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2D6C8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: GoogleFonts.notoSerif(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        '${med.doseAndFrequency}' +
                            (med.startedAt != null
                                ? ' • Started ${_monthsNames[med.startedAt!.month - 1].substring(0, 3)} ${med.startedAt!.day}, ${med.startedAt!.year}'
                                : ''),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: const Color(0xFF78716C),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Edit Details Option
            ListTile(
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => HrtQuickEditModal(
                    medication: med,
                    onNavigateToHrtTracker: () {
                      _openMedicationManagementSheet(med);
                    },
                  ),
                );
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Colors.white,
              leading: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              title: Text('Edit Dose & Schedule', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              subtitle: Text('Change dosage, unit, or intake frequency', style: GoogleFonts.manrope(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 18),
            ),
            const SizedBox(height: 12),

            // Stop vs Delete Action Card based on logged history
            if (!hasHistory) ...[
              ListTile(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Delete Medication?', style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
                      content: Text(
                        'This medication has zero logged history. It will be permanently removed from your account.',
                        style: GoogleFonts.manrope(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(color: Color(0xFF8C3A25), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    ref.read(medicationsProvider.notifier).removeMedication(med.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Medication permanently deleted.', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFF8C3A25),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: const Color(0xFFFFF6F4),
                leading: const Icon(Icons.delete_forever_outlined, color: Color(0xFF8C3A25)),
                title: Text('Delete Medication', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: const Color(0xFF8C3A25))),
                subtitle: Text('No logged history found • Permanent delete', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF8C3A25))),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF8C3A25), size: 18),
              ),
            ] else ...[
              ListTile(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: med.endedAt ?? DateTime.now(),
                    firstDate: med.startedAt ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null && mounted) {
                    ref.read(medicationsProvider.notifier).endMedication(med.id, endDate: pickedDate);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Medication discontinued. Past log history preserved!',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: const Color(0xFF67594E),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: const Color(0xFFFAF6F0),
                leading: const Icon(Icons.pause_circle_outline, color: Color(0xFF67594E)),
                title: Text(
                  med.endedAt != null ? 'Update Discontinuation Date' : 'Stop Taking Medication',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: const Color(0xFF4D453F)),
                ),
                subtitle: Text(
                  'Preserves past adherence history & logs',
                  style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF78716C)),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF67594E), size: 18),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F5F0),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Month (${_focusedMonth.year})',
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthVal = index + 1;
                    final isSelected = _focusedMonth.month == monthVal;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _focusedMonth = DateTime(_focusedMonth.year, monthVal);
                          _selectedDay = 1;
                        });
                        _fetchLogsForFocusedMonth();
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : const Color(0xFFE7E5E4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _monthsNames[index].substring(0, 3).toUpperCase(),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHrtDoseSkeleton(List<Medication> medications) {
    final count = medications.isNotEmpty ? medications.length : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFEAE6E0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFEAE6E0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(count, (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFEAE6E0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2EFEA),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EFEA),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 160,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3EF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EFEA),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTodayDoseSection(List<Medication> medications) {
    final isMonthLoaded = _monthLogsCache.containsKey(_monthKey(_focusedMonth));
    if (!isMonthLoaded || _isLoadingLogs) {
      return _buildHrtDoseSkeleton(medications);
    }

    final selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay);
    final selectedLog = _monthlyLogs[_selectedDay];

    final weekdayName = _weekdays[selectedDate.weekday - 1];
    final monthName = _monthsNames[selectedDate.month - 1].substring(0, 3);
    final dateLabel = "$weekdayName, $monthName $_selectedDay";

    final today = DateTime.now();
    final isTodaySelected = today.year == selectedDate.year && today.month == selectedDate.month && today.day == selectedDate.day;

    final scheduledMeds = medications.where((m) => !HrtScheduleService.isAsNeeded(m)).toList();
    final asNeededMeds = medications.where((m) => HrtScheduleService.isAsNeeded(m)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _showHrtLoggingSheet(medications),
              child: Text(
                isTodaySelected ? "TODAY'S SCHEDULED DOSES" : "SCHEDULED DOSES",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.primary,
                ),
              ),
            ),
            Text(
              dateLabel,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF9B8B7E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (scheduledMeds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'No scheduled medications configured.',
              style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF78716C), fontStyle: FontStyle.italic),
            ),
          )
        else
          ...scheduledMeds.map((med) => _buildMedicationDoseTile(med: med, selectedDate: selectedDate, selectedLog: selectedLog)),

        if (asNeededMeds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            "AS NEEDED MEDICATIONS",
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: const Color(0xFF67594E),
            ),
          ),
          const SizedBox(height: 12),
          ...asNeededMeds.map((med) => _buildAsNeededDoseTile(med: med, selectedDate: selectedDate, selectedLog: selectedLog)),
        ],
      ],
    );
  }

  Widget _buildMedicationDoseTile({
    required Medication med,
    required DateTime selectedDate,
    DailyLog? selectedLog,
  }) {
    final isActiveOnDate = _isMedicationActiveOnDate(med, selectedDate);
    HrtIntakeLog? loggedIntake;

    if (selectedLog != null) {
      loggedIntake = selectedLog.hrtIntakes.firstWhere(
        (h) => h.medicationId == med.id || h.name.toLowerCase() == med.name.toLowerCase(),
        orElse: () => HrtIntakeLog(medicationId: med.id, name: med.name, dose: med.dose, unit: med.unit, time: '', isTaken: false),
      );
    }

    final dailyState = HrtScheduleService.getDailyState(
      med: med,
      date: selectedDate,
      loggedIntake: loggedIntake,
    );

    final icon = med.type == MedicationType.patch ? Icons.water_drop : Icons.medication;
    final iconColor = med.type == MedicationType.patch ? const Color(0xFFE8A89B) : const Color(0xFFD8C9E0);
    final iconBg = iconColor.withOpacity(0.12);

    String statusText = '';
    Color statusColor = const Color(0xFF9B8B7E);
    Widget? statusIcon;

    if (!isActiveOnDate) {
      final target = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      if (med.startedAt != null && target.isBefore(DateTime(med.startedAt!.year, med.startedAt!.month, med.startedAt!.day))) {
        statusText = 'Not started yet';
      } else if (med.endedAt != null && target.isAfter(DateTime(med.endedAt!.year, med.endedAt!.month, med.endedAt!.day))) {
        statusText = 'Discontinued';
      } else {
        statusText = 'Inactive on this date';
      }
      statusColor = const Color(0xFF8C3A25);
    } else {
      switch (dailyState) {
        case DailyScheduledState.logged:
          final actionWord = med.type == MedicationType.patch ? 'Applied' : 'Taken';
          final timeVal = loggedIntake?.time ?? "";
          statusText = timeVal.isNotEmpty ? '$actionWord at $timeVal' : actionWord;
          statusColor = const Color(0xFF2D5A3E);
          statusIcon = const Icon(Icons.check_circle, size: 14, color: Color(0xFF2D5A3E));
          break;
        case DailyScheduledState.readyToLog:
          statusText = 'Ready to log';
          statusColor = const Color(0xFF817266);
          break;
        case DailyScheduledState.notScheduledToday:
          statusText = 'Not scheduled today';
          statusColor = const Color(0xFF9B8B7E);
          break;
        case DailyScheduledState.asNeeded:
          statusText = 'As Needed';
          statusColor = const Color(0xFF67594E);
          break;
      }
    }

    return Opacity(
      opacity: isActiveOnDate ? 1.0 : 0.45,
      child: InkWell(
        onTap: () => _openMedicationManagementSheet(med),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFEAE6E0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: GoogleFonts.notoSerif(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${med.dose.toStringAsFixed(med.dose == med.dose.toInt() ? 0 : 2)} ${med.unit} ${med.type.displayName.toLowerCase()} • ${med.formattedFrequency}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF9B8B7E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (statusIcon != null) ...[
                          statusIcon,
                          const SizedBox(width: 4),
                        ],
                        Text(
                          statusText,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9B8B7E),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAsNeededDoseTile({
    required Medication med,
    required DateTime selectedDate,
    DailyLog? selectedLog,
  }) {
    bool isTaken = false;
    String time = '';

    if (selectedLog != null) {
      final logged = selectedLog.hrtIntakes.firstWhere(
        (h) => h.medicationId == med.id || h.name.toLowerCase() == med.name.toLowerCase(),
        orElse: () => HrtIntakeLog(medicationId: med.id, name: med.name, dose: med.dose, unit: med.unit, time: '', isTaken: false),
      );
      isTaken = logged.isTaken;
      time = logged.time;
    }

    final iconColor = const Color(0xFFB5A79E);
    final iconBg = iconColor.withOpacity(0.12);

    return InkWell(
      onTap: () => _openMedicationManagementSheet(med),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAE6E0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medical_services, color: Color(0xFF67594E), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: GoogleFonts.notoSerif(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${med.dose.toStringAsFixed(med.dose == med.dose.toInt() ? 0 : 2)} ${med.unit} • As needed',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF9B8B7E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isTaken)
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Color(0xFF2D5A3E)),
                        const SizedBox(width: 4),
                        Text(
                          'Logged at $time',
                          style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF2D5A3E), fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Available on demand',
                      style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF67594E), fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showHrtLoggingSheet([med]),
              style: ElevatedButton.styleFrom(
                backgroundColor: isTaken ? const Color(0xFFEAE6E0) : const Color(0xFF67594E),
                foregroundColor: isTaken ? const Color(0xFF4D453F) : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isTaken ? 'Edit' : 'Log dose',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyScheduleSection(String currentMonth) {
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    final nextMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MONTHLY SCHEDULE",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    "Tap dates to view or log past doses",
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: const Color(0xFF9B8B7E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  child: InkWell(
                    onTap: _previousMonth,
                    borderRadius: BorderRadius.circular(18),
                    child: const Center(
                      child: Icon(Icons.chevron_left, size: 22, color: Color(0xFF9B8B7E)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showMonthPicker,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentMonth,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Builder(builder: (context) {
                  final now = DateTime.now();
                  final isCurrentOrFutureMonth = _focusedMonth.year > now.year ||
                      (_focusedMonth.year == now.year && _focusedMonth.month >= now.month);
                  return Container(
                    width: 36,
                    height: 36,
                    child: InkWell(
                      onTap: isCurrentOrFutureMonth ? null : _nextMonth,
                      borderRadius: BorderRadius.circular(18),
                      child: Center(
                        child: Icon(
                          Icons.chevron_right,
                          size: 22,
                          color: isCurrentOrFutureMonth
                              ? const Color(0xFF9B8B7E).withOpacity(0.3)
                              : const Color(0xFF9B8B7E),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onHorizontalDragStart: (_) {
            _dragOffset = 0.0;
          },
          onHorizontalDragUpdate: (details) {
            _dragOffset += details.primaryDelta ?? 0.0;
            if (_dragOffset.abs() > 10.0 && !_isSwiping) {
              setState(() {
                _isSwiping = true;
              });
            } else if (_isSwiping) {
              setState(() {});
            }
          },
          onHorizontalDragEnd: (details) {
            if (_dragOffset.abs() > 60.0) {
              if (_dragOffset < 0) {
                final now = DateTime.now();
                final isCurrentOrFutureMonth = _focusedMonth.year > now.year ||
                    (_focusedMonth.year == now.year && _focusedMonth.month >= now.month);
                if (!isCurrentOrFutureMonth) {
                  _nextMonth();
                } else {
                  setState(() {
                    _isSwiping = false;
                    _dragOffset = 0.0;
                  });
                }
              } else {
                _previousMonth();
              }
            } else {
              setState(() {
                _isSwiping = false;
                _dragOffset = 0.0;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFEAE6E0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                    return SizedBox(
                      width: 32,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF9B8B7E),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    // The actual cell size of a calendar day in HrtTrackerPage is 34px container + 8px vertical padding (4px top and 4px bottom)
                    const safetyCellHeight = 42.0;

                    int _getRowCountForMonth(DateTime month) {
                      final totalDays = DateUtils.getDaysInMonth(month.year, month.month);
                      final firstDay = DateTime(month.year, month.month, 1);
                      final prefix = firstDay.weekday - 1;
                      final totalCells = totalDays + prefix;
                      return (totalCells / 7).ceil();
                    }

                    final currentRows = _getRowCountForMonth(_focusedMonth);
                    final prevRows = _getRowCountForMonth(prevMonth);
                    final nextRows = _getRowCountForMonth(nextMonth);

                    double targetHeight = currentRows * safetyCellHeight;
                    if (_isSwiping && _dragOffset != 0.0) {
                      final progress = (_dragOffset.abs() / width).clamp(0.0, 1.0);
                      final adjacentRows = _dragOffset > 0 ? prevRows : nextRows;
                      targetHeight = currentRows * safetyCellHeight + (adjacentRows - currentRows) * safetyCellHeight * progress;
                    }

                    return ClipRect(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            height: targetHeight,
                            child: Stack(
                              children: [
                                // Previous Month
                                Transform.translate(
                                  offset: Offset(_dragOffset - width, 0),
                                  child: Container(
                                    width: width,
                                    height: prevRows * safetyCellHeight,
                                    child: _buildCalendarDaysGridForMonth(prevMonth),
                                  ),
                                ),
                                // Current Month
                                Transform.translate(
                                  offset: Offset(_dragOffset, 0),
                                  child: Container(
                                    width: width,
                                    height: currentRows * safetyCellHeight,
                                    child: _buildCalendarDaysGridForMonth(_focusedMonth),
                                  ),
                                ),
                                // Next Month
                                Transform.translate(
                                  offset: Offset(_dragOffset + width, 0),
                                  child: Container(
                                    width: width,
                                    height: nextRows * safetyCellHeight,
                                    child: _buildCalendarDaysGridForMonth(nextMonth),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IgnorePointer(
                            child: AnimatedOpacity(
                              opacity: _isSwiping ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  _monthsNames[_focusedMonth.month - 1],
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF2EDEA), height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVITY LOG',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.primary,
                      ),
                    ),
                    Row(
                      children: [
                        _buildLogTag('Meds', const Color(0xFFD8C9E0).withOpacity(0.3)),
                        const SizedBox(width: 6),
                        _buildLogTag('Dose \u2191', const Color(0xFFE8A89B).withOpacity(0.2)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActivityLogsForMonth(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildCalendarDaysGrid() {
    return _buildCalendarDaysGridForMonth(_focusedMonth);
  }

  Widget _buildCalendarDaysGridForMonth(DateTime targetMonth) {
    final List<Widget> dayWidgets = [];

    final totalDays = DateUtils.getDaysInMonth(targetMonth.year, targetMonth.month);
    final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
    final startWeekday = firstDayOfMonth.weekday;
    final startOffset = startWeekday - 1;

    for (int i = 0; i < startOffset; i++) {
      dayWidgets.add(const SizedBox(width: 32, height: 32));
    }

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final targetMonthKey = _monthKey(targetMonth);
    final targetLogs = _monthLogsCache[targetMonthKey] ?? {};
    final targetChanges = _monthDoseChangesCache[targetMonthKey] ?? [];

    for (int day = 1; day <= totalDays; day++) {
      final dayDate = DateTime(targetMonth.year, targetMonth.month, day);
      final isFuture = dayDate.isAfter(todayDate);

      final isSelected = _selectedDay == day &&
          _focusedMonth.year == targetMonth.year &&
          _focusedMonth.month == targetMonth.month;
      final isToday = todayDate.year == targetMonth.year && todayDate.month == targetMonth.month && todayDate.day == day;

      final dayLog = targetLogs[day];
      final hasLoggedMeds = dayLog != null && dayLog.hrtIntakes.isNotEmpty;
      final isTaken = hasLoggedMeds && dayLog.hrtIntakes.any((h) => h.isTaken);

      final isDoseChange = targetChanges.any((change) => change.changeDate.day == day);

      if (isFuture) {
        dayWidgets.add(
          Center(
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFFD9D1CB),
                ),
              ),
            ),
          ),
        );
        continue;
      }

      dayWidgets.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (targetMonth.year == _focusedMonth.year && targetMonth.month == _focusedMonth.month) {
              _selectDay(day);
            }
          },
          child: Container(
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: isToday && isSelected
                  ? const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    )
                  : isDoseChange
                      ? BoxDecoration(
                          color: const Color(0xFFE8A89B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE8A89B).withOpacity(0.4)),
                        )
                      : isSelected
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primary, width: 1.5),
                            )
                          : isTaken
                              ? BoxDecoration(
                                  color: const Color(0xFFD8C9E0).withOpacity(0.22),
                                  shape: BoxShape.circle,
                                )
                              : hasLoggedMeds
                                  ? BoxDecoration(
                                      color: const Color(0xFFEAE6E0),
                                      shape: BoxShape.circle,
                                    )
                                  : BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE6E0D6), width: 1),
                                    ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: (isSelected || isToday || isDoseChange || hasLoggedMeds)
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isToday && isSelected
                          ? Colors.white
                          : isDoseChange
                              ? AppTheme.primary
                              : AppTheme.onSurface,
                    ),
                  ),
                  if (hasLoggedMeds && !isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      width: 3.5,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: isTaken ? const Color(0xFF67594E) : const Color(0xFF9B8B7E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (isDoseChange)
                    const Icon(
                      Icons.north,
                      size: 8,
                      color: Color(0xFFE8A89B),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final rowsCount = (dayWidgets.length / 7).ceil();
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rowsCount, (rowIndex) {
          final start = rowIndex * 7;
          final end = (start + 7 < dayWidgets.length) ? start + 7 : dayWidgets.length;
          final rowWidgets = dayWidgets.sublist(start, end);

          while (rowWidgets.length < 7) {
            rowWidgets.add(const SizedBox(width: 32, height: 32));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: rowWidgets.map((w) => Expanded(child: w)).toList(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActivityLogsForMonth() {
    final List<Map<String, dynamic>> activities = [];
    final selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay);
    final targetMonthKey = _monthKey(_focusedMonth);
    final targetLogs = _monthLogsCache[targetMonthKey] ?? {};
    final targetChanges = _monthDoseChangesCache[targetMonthKey] ?? [];
    final allMeds = ref.watch(medicationsProvider).medications;

    // 1. Medication Starts / Discontinuations
    for (final med in allMeds) {
      if (med.startedAt != null) {
        final s = med.startedAt!;
        if (s.year == selectedDate.year && s.month == selectedDate.month && s.day == selectedDate.day) {
          activities.add({
            'day': _selectedDay,
            'isClinical': true,
            'color': const Color(0xFF4A6B5D),
            'title': 'Medication Started',
            'description': '${med.name} (${med.doseAndFrequency}) started.',
          });
        }
      }
      if (med.endedAt != null) {
        final e = med.endedAt!;
        if (e.year == selectedDate.year && e.month == selectedDate.month && e.day == selectedDate.day) {
          activities.add({
            'day': _selectedDay,
            'isClinical': true,
            'color': const Color(0xFF8C3A25),
            'title': 'Medication Discontinued',
            'description': '${med.name} discontinued.',
          });
        }
      }
    }

    // 2. Regimen Changes (Dose, Frequency, Schedule Day)
    for (final change in targetChanges) {
      if (change.changeDate.year == selectedDate.year &&
          change.changeDate.month == selectedDate.month &&
          change.changeDate.day == selectedDate.day) {
        final isClinical = change.isClinicalChange;
        final title = change.changeType == RegimenChangeType.frequencyChange
            ? 'Frequency Change'
            : change.changeType == RegimenChangeType.scheduleDayChange
                ? 'Schedule Change (Administrative)'
                : 'Dose Change';

        activities.add({
          'day': _selectedDay,
          'isClinical': isClinical,
          'color': isClinical ? const Color(0xFFE8A89B) : const Color(0xFF9B8B7E),
          'title': title,
          'description': '${change.medicationName}: ${change.previousValue} → ${change.newValue}',
        });
      }
    }

    // 3. Adherence for active medications on selectedDate
    final dayLog = targetLogs[_selectedDay];
    final activeMedsOnDate = allMeds.where((m) {
      if (m.startedAt != null && selectedDate.isBefore(DateTime(m.startedAt!.year, m.startedAt!.month, m.startedAt!.day))) return false;
      if (m.endedAt != null && selectedDate.isAfter(DateTime(m.endedAt!.year, m.endedAt!.month, m.endedAt!.day))) return false;
      return true;
    }).toList();

    for (final med in activeMedsOnDate) {
      final isScheduled = HrtScheduleService.isScheduledOnDate(med, selectedDate, doseChanges: targetChanges);
      final intake = dayLog?.hrtIntakes.firstWhere(
        (i) => (i.medicationId.isNotEmpty && i.medicationId == med.id) || i.name.toLowerCase() == med.name.toLowerCase(),
        orElse: () => HrtIntakeLog(medicationId: med.id, name: med.name, dose: med.dose, unit: med.unit, time: '', isTaken: false),
      );
      final hasLog = intake != null && (intake.isTaken || intake.time.isNotEmpty);
      final taken = intake?.isTaken ?? false;

      if (isScheduled || hasLog) {
        final isPatch = med.type == MedicationType.patch;
        final statusLabel = taken ? (isPatch ? 'Applied' : 'Taken') : 'Not taken';

        activities.add({
          'day': _selectedDay,
          'isClinical': true,
          'color': taken ? const Color(0xFF4A6B5D) : const Color(0xFFC47B62),
          'title': '${med.name}: $statusLabel',
          'description': '${med.doseAndFrequency}',
        });
      }
    }

    final bool isDayLogged = dayLog != null && (
      dayLog.isCompleted ||
      dayLog.hrtIntakes.isNotEmpty ||
      dayLog.symptoms.isNotEmpty ||
      dayLog.triggers.isNotEmpty
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDayLogged) ...[
          // Retrospective Logging CTA Button
          InkWell(
            onTap: () {
              context.go('/calendar', extra: selectedDate);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_calendar, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Log this day',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (activities.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No activity recorded for this day.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: const Color(0xFF9B8B7E),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ...activities.map((act) {
            final isClinical = act['isClinical'] as bool? ?? true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActivityRow(
                color: act['color'] as Color,
                title: act['title'] as String,
                description: act['description'] as String,
                isActive: isClinical,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildActivityRow({
    required Color color,
    required String title,
    required String description,
    required bool isActive,
  }) {
    return Container(
      padding: EdgeInsets.all(isActive ? 12 : 0),
      decoration: isActive
          ? BoxDecoration(
              color: const Color(0xFFF2EDEA).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE6E0)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppTheme.primary : AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: const Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
