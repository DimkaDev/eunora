import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/home/presentation/widgets/calendar_hrt_edit_sheet.dart';
import 'package:eunora/features/onboarding/presentation/widgets/add_medication_modal.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';

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

  final List<String> _monthsNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

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
    if (_monthLogsCache.containsKey(key)) {
      if (targetMonth.year == _focusedMonth.year && targetMonth.month == _focusedMonth.month) {
        setState(() {
          _monthlyLogs = _monthLogsCache[key] ?? {};
          _monthlyDoseChanges = _monthDoseChangesCache[key] ?? [];
        });
      }
      return;
    }

    try {
      final daysInMonth = DateUtils.getDaysInMonth(targetMonth.year, targetMonth.month);
      final start = DateTime(targetMonth.year, targetMonth.month, 1);
      final end = DateTime(targetMonth.year, targetMonth.month, daysInMonth, 23, 59, 59);

      final dbLogs = await ref.read(firestoreServiceProvider).getDailyLogsHistory(user.uid, start, end);
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
        });
      }
    } catch (e) {
      debugPrint("Error fetching HRT logs for $key: $e");
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
    setState(() {
      _isSwiping = true;
      _dragOffset = 0.0;
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
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

  void _selectDay(int day) {
    setState(() {
      _selectedDay = day;
    });
  }

  Future<void> _saveTodayHrtLog(Medication med, bool isTaken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final currentLog = await ref.read(firestoreServiceProvider).getDailyLog(user.uid, dateStr);

    final nowTime = TimeOfDay.now();
    final timeStr = "${nowTime.hour.toString().padLeft(2, '0')}:${nowTime.minute.toString().padLeft(2, '0')}";

    DailyLog dailyLog;
    if (currentLog != null) {
      final updatedIntakes = List<HrtIntakeLog>.from(currentLog.hrtIntakes);
      final existingIndex = updatedIntakes.indexWhere((h) => h.medicationId == med.id);

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
        date: today,
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
    final targetLog = _monthlyLogs[_selectedDay];
    final hrtList = medications.map((med) {
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
          onSave: (updatedList) async {
            // Delete removed medications first
            final updatedIds = updatedList.map((e) => e['id']).where((id) => id != null).toSet();
            for (final med in medications) {
              if (!updatedIds.contains(med.id)) {
                ref.read(medicationsProvider.notifier).removeMedication(med.id);
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

  @override
  Widget build(BuildContext context) {
    final medicationsState = ref.watch(medicationsProvider);
    final medications = medicationsState.medications;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: medications.isEmpty 
          ? _buildEmptyState() 
          : _buildDashboard(medications),
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
  Widget _buildDashboard(List<Medication> medications) {
    final currentMonthLabel = '${_monthsNames[_focusedMonth.month - 1]} ${_focusedMonth.year}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
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
            const SizedBox(height: 24),

            // Today's Dose Section
            _buildTodayDoseSection(medications),
            const SizedBox(height: 28),

            // Monthly Schedule Section
            _buildMonthlyScheduleSection(currentMonthLabel),
            const SizedBox(height: 24),

            // Adherence Section
            _buildAdherenceCard(),
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

  Widget _buildTodayDoseSection(List<Medication> medications) {
    final selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay);
    final selectedLog = _monthlyLogs[_selectedDay];

    final weekdayName = _weekdays[selectedDate.weekday - 1];
    final monthName = _monthsNames[selectedDate.month - 1].substring(0, 3);
    final dateLabel = "$weekdayName, $monthName $_selectedDay";

    final today = DateTime.now();
    final isTodaySelected = today.year == selectedDate.year && today.month == selectedDate.month && today.day == selectedDate.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _showHrtLoggingSheet(medications),
              child: Text(
                isTodaySelected ? "TODAY'S DOSE" : "LOGGED DOSE",
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
        ...medications.map((med) {
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

          final icon = med.type == MedicationType.patch 
              ? Icons.water_drop 
              : Icons.medication;
          final iconColor = med.type == MedicationType.patch 
              ? const Color(0xFFE8A89B) 
              : const Color(0xFFD8C9E0);
          final iconBg = iconColor.withOpacity(0.12);

          return Container(
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
                GestureDetector(
                  onTap: () => _showHrtLoggingSheet(medications),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showHrtLoggingSheet(medications),
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
                          '${med.dose.toStringAsFixed(0)} ${med.unit} ${med.type.displayName.toLowerCase()} • Protocol dose',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF9B8B7E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isTaken)
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Color(0xFF2D5A3E),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Taken at $time',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: const Color(0xFF2D5A3E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Not logged yet',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: const Color(0xFF9B8B7E),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await _saveTodayHrtLog(med, !isTaken);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isTaken ? AppTheme.primary : const Color(0xFFEAE6E0),
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
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
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
                Container(
                  width: 36,
                  height: 36,
                  child: InkWell(
                    onTap: _nextMonth,
                    borderRadius: BorderRadius.circular(18),
                    child: const Center(
                      child: Icon(Icons.chevron_right, size: 22, color: Color(0xFF9B8B7E)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onHorizontalDragStart: (_) {
            setState(() {
              _isSwiping = true;
              _dragOffset = 0.0;
            });
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.primaryDelta ?? 0.0;
            });
          },
          onHorizontalDragEnd: (details) {
            if (_dragOffset.abs() > 80.0) {
              if (_dragOffset < 0) {
                _nextMonth();
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

    final today = DateTime.now();
    final targetMonthKey = _monthKey(targetMonth);
    final targetLogs = _monthLogsCache[targetMonthKey] ?? {};
    final targetChanges = _monthDoseChangesCache[targetMonthKey] ?? [];

    for (int day = 1; day <= totalDays; day++) {
      final isSelected = _selectedDay == day &&
          _focusedMonth.year == targetMonth.year &&
          _focusedMonth.month == targetMonth.month;
      final isToday = today.year == targetMonth.year && today.month == targetMonth.month && today.day == day;

      final dayLog = targetLogs[day];
      final isTaken = dayLog != null && dayLog.hrtIntakes.isNotEmpty && dayLog.hrtIntakes.any((h) => h.isTaken);

      final isDoseChange = targetChanges.any((change) => change.changeDate.day == day);

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            if (targetMonth.year == _focusedMonth.year && targetMonth.month == _focusedMonth.month) {
              _selectDay(day);
            }
          },
          child: Center(
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
                                  color: const Color(0xFFD8C9E0).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                )
                              : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: (isSelected || isToday || isDoseChange || isTaken)
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isToday && isSelected
                          ? Colors.white
                          : isDoseChange
                              ? AppTheme.primary
                              : (day > today.day && isToday)
                                  ? const Color(0xFF9B8B7E).withOpacity(0.4)
                                  : AppTheme.onSurface,
                    ),
                  ),
                  if (isTaken && !isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8C9E0),
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

    _monthlyLogs.forEach((day, log) {
      if (day != _selectedDay) return;
      final loggedMeds = log.hrtIntakes.where((h) => h.isTaken).map((h) => h.name).toList();
      if (loggedMeds.isNotEmpty) {
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
        final dateLabel = "${_weekdays[date.weekday - 1]}, ${_monthsNames[_focusedMonth.month - 1].substring(0, 3)} $day";

        activities.add({
          'day': day,
          'type': 'intake',
          'color': AppTheme.primary,
          'title': 'Intake: $dateLabel',
          'description': '${log.hrtIntakes.length} medications scheduled. ${loggedMeds.length} logged (${loggedMeds.join(', ')}).',
        });
      }
    });

    for (final change in _monthlyDoseChanges) {
      final day = change.changeDate.day;
      if (day != _selectedDay) continue;
      final date = change.changeDate;
      final dateLabel = "${_weekdays[date.weekday - 1]}, ${_monthsNames[_focusedMonth.month - 1].substring(0, 3)} $day";
      final direction = change.newDose > change.oldDose ? 'increased' : 'decreased';

      activities.add({
        'day': day,
        'type': 'dose_change',
        'color': const Color(0xFFE8A89B),
        'title': 'Dose Change: $dateLabel',
        'description': '${change.medicationName} $direction to ${change.newDose.toStringAsFixed(0)} ${change.unit}.',
      });
    }

    activities.sort((a, b) => (b['day'] as int).compareTo(a['day'] as int));

    if (activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No active logs for this day.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF9B8B7E),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: activities.map((act) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildActivityRow(
            color: act['color'] as Color,
            title: act['title'] as String,
            description: act['description'] as String,
            isActive: _selectedDay == act['day'] as int,
          ),
        );
      }).toList(),
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

  Widget _buildAdherenceCard() {
    final totalDays = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);

    final today = DateTime.now();
    final isCurrentMonth = today.year == _focusedMonth.year && today.month == _focusedMonth.month;
    final limitDay = isCurrentMonth ? today.day : totalDays;

    int totalScheduled = 0;
    int totalLogged = 0;

    for (int day = 1; day <= limitDay; day++) {
      final log = _monthlyLogs[day];
      if (log != null) {
        totalScheduled += log.hrtIntakes.length;
        totalLogged += log.hrtIntakes.where((h) => h.isTaken).length;
      }
    }

    int rate = 100;
    if (totalScheduled > 0) {
      rate = ((totalLogged / totalScheduled) * 100).round();
    } else {
      final hasMeds = ref.read(medicationsProvider).medications.isNotEmpty;
      rate = hasMeds ? 100 : 0;
    }

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
        border: Border.all(color: const Color(0xFF2D5A3E).withOpacity(0.08)),
      ),
      child: Row(
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
                  'Adherence this month: $rate%',
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
    );
  }
}
