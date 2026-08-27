import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/home/presentation/widgets/symptom_logging_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/edit_symptoms_modal_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/trigger_logging_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/edit_triggers_modal_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/calendar_hrt_edit_sheet.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/core/utils/logging_helpers.dart';
import 'package:eunora/features/home/presentation/widgets/calendar/calendar_weekly_trends_card.dart';
import 'package:eunora/features/home/presentation/widgets/calendar/calendar_insights_banner.dart';
import 'package:eunora/features/onboarding/presentation/providers/triggers_provider.dart';
import 'package:eunora/features/onboarding/domain/models/trigger.dart';
import 'package:eunora/features/symptom_log/data/trigger_library.dart';

class MockDailyLog {
  List<String> symptoms;
  final String sleepInfo;
  final String moodInfo;
  List<Map<String, String>> hrt;
  List<String> triggers;
  int itemsCount;
  DailyLog? originalLog;

  MockDailyLog({
    required this.symptoms,
    required this.sleepInfo,
    required this.moodInfo,
    required this.hrt,
    required this.triggers,
    required this.itemsCount,
    this.originalLog,
  });
}

class CalendarPage extends ConsumerStatefulWidget {
  final DateTime? initialSelectedDate;
  const CalendarPage({super.key, this.initialSelectedDate});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  // Navigation states
  late DateTime _focusedMonth;
  late DateTime? _selectedDate;
  bool _legendExpanded = false;

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  // Track swipe direction for calendar animations (1 for right-to-left/next, -1 for left-to-right/prev)
  int _swipeDirection = 1;
  bool _isSwiping = false;
  double _dragOffset = 0.0;

  String _formatSelectedDate() {
    if (_selectedDate == null) return 'Select a Date';
    return '${_weekdays[_selectedDate!.weekday - 1]}, ${_months[_selectedDate!.month - 1]} ${_selectedDate!.day}';
  }

  // Cache of logs keyed by "yyyy-MM" string to avoid re-fetching
  final Map<String, Map<int, MockDailyLog>> _monthLogsCache = {};
  final Map<String, Map<int, DailyLog>> _monthDraftsCache = {};
  bool _isLoadingDbLogs = false;
  
  // Track whether we have loaded at least once, or if currently loading.
  bool _isFirstPageLoad = true;

  // Mock Database for April 2026
  late final Map<int, MockDailyLog> _aprilLogs;

  // Swipe page controller – start at page 1000 so we can go left/right freely
  late final PageController _pageController;
  static const int _initialPage = 1000;

  @override
  void initState() {
    super.initState();
    final initDate = widget.initialSelectedDate ?? DateTime.now();
    _selectedDate = DateTime(initDate.year, initDate.month, initDate.day);
    _focusedMonth = DateTime(initDate.year, initDate.month);
    _aprilLogs = {
      7: MockDailyLog(
        symptoms: ['Hot flashes · 2/5', 'Anxiety · 1/5'],
        sleepInfo: '7 hours · quality 4/5',
        moodInfo: 'Good · 4/5',
        hrt: [
          {'name': 'Estradiol', 'details': '50 mcg · Patch', 'status': 'Taken 08:30', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Taken 21:00', 'isTaken': 'true'},
        ],
        triggers: ['Stress'],
        itemsCount: 4,
      ),
      8: MockDailyLog(
        symptoms: ['Hot flashes · 3/5', 'Fatigue · 2/5'],
        sleepInfo: '6.5 hours · quality 3/5',
        moodInfo: 'Okay · 3/5',
        hrt: [
          {'name': 'Estradiol', 'details': '50 mcg · Patch', 'status': 'Taken 08:45', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Not taken', 'isTaken': 'false'},
        ],
        triggers: ['Red wine', 'Poor sleep'],
        itemsCount: 4,
      ),
      9: MockDailyLog(
        symptoms: ['Fatigue · 4/5', 'Anxiety · 3/5'],
        sleepInfo: '5.5 hours · quality 2/5',
        moodInfo: 'Anxious · 2/5',
        hrt: [
          {'name': 'Estradiol', 'details': '50 mcg · Patch', 'status': 'Taken 08:00', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Taken 20:30', 'isTaken': 'true'},
        ],
        triggers: ['Poor sleep', 'Stress'],
        itemsCount: 4,
      ),
      10: MockDailyLog(
        symptoms: ['Hot flashes · 4/5', 'Anxiety · 4/5', 'Fatigue · 3/5'],
        sleepInfo: '6 hours · quality 3/5',
        moodInfo: 'Okay · 3/5',
        hrt: [
          {'name': 'Estradiol', 'details': '75 mcg · Patch', 'status': 'Taken 08:15', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Not taken', 'isTaken': 'false'},
        ],
        triggers: ['Red wine', 'Stress', 'Poor sleep'],
        itemsCount: 4,
      ),
      11: MockDailyLog(
        symptoms: ['Hot flashes · 5/5', 'Anxiety · 3/5'],
        sleepInfo: '5 hours · quality 2/5',
        moodInfo: 'Low · 2/5',
        hrt: [
          {'name': 'Estradiol', 'details': '50 mcg · Patch', 'status': 'Taken 09:00', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Taken 21:15', 'isTaken': 'true'},
        ],
        triggers: ['Stress'],
        itemsCount: 4,
      ),
      12: MockDailyLog(
        symptoms: ['Fatigue · 2/5'],
        sleepInfo: '8 hours · quality 5/5',
        moodInfo: 'Great · 5/5',
        hrt: [
          {'name': 'Estradiol', 'details': '50 mcg · Patch', 'status': 'Taken 08:30', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Not taken', 'isTaken': 'false'},
        ],
        triggers: [],
        itemsCount: 3,
      ),
      13: MockDailyLog(
        symptoms: ['Hot flashes · 4/5', 'Anxiety · 3/5', 'Fatigue · 3/5'],
        sleepInfo: '6 hours · quality 3/5',
        moodInfo: 'Good · 4/5',
        hrt: [
          {'name': 'Estradiol', 'details': '75 mcg · Patch', 'status': 'Taken 08:15', 'isTaken': 'true'},
          {'name': 'Utrogestan', 'details': '100 mg · Tablet', 'status': 'Not taken', 'isTaken': 'false'},
        ],
        triggers: ['Stress', 'Red wine', 'Poor sleep'],
        itemsCount: 4,
      ),
    };

    // Invalidate current month cache so re-opening the page always shows fresh data
    final currentKey = _monthKey(_focusedMonth);
    _monthLogsCache.remove(currentKey);
    _monthDraftsCache.remove(currentKey);

    // Fetch logs from firestore post build phase and trigger prefetching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLogsForMonth(_focusedMonth).then((_) {
        if (mounted) {
          setState(() {
            _isFirstPageLoad = false;
          });
        }
      });
      _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month - 1));
      _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month + 1));
    });
  }

  @override
  void didUpdateWidget(covariant CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedDate != null && widget.initialSelectedDate != oldWidget.initialSelectedDate) {
      final initDate = widget.initialSelectedDate!;
      setState(() {
        _selectedDate = DateTime(initDate.year, initDate.month, initDate.day);
        _focusedMonth = DateTime(initDate.year, initDate.month);
      });
      _fetchLogsForMonth(_focusedMonth);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fetch current month when the page regains focus (e.g., returning from daily logging)
    final currentKey = _monthKey(_focusedMonth);
    if (_monthLogsCache.containsKey(currentKey) || _monthDraftsCache.containsKey(currentKey)) {
      // Invalidate and re-fetch to pick up any newly saved logs
      _monthLogsCache.remove(currentKey);
      _monthDraftsCache.remove(currentKey);
      _fetchLogsForMonth(_focusedMonth);
    }
  }

  String _monthKey(DateTime m) => "${m.year}-${m.month.toString().padLeft(2, '0')}";

  Future<void> _fetchLogsForMonth(DateTime targetMonth) async {
    final key = _monthKey(targetMonth);
    // If already loading or cached, skip double fetching
    if (_monthLogsCache.containsKey(key) && _monthDraftsCache.containsKey(key)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final daysInMonth = DateUtils.getDaysInMonth(targetMonth.year, targetMonth.month);
      final start = DateTime(targetMonth.year, targetMonth.month, 1);
      final end = DateTime(targetMonth.year, targetMonth.month, daysInMonth, 23, 59, 59);

      final rawDbLogs = await ref.read(firestoreServiceProvider).getDailyLogsHistory(user.uid, start, end);
      // Completed logs
      final dbLogs = rawDbLogs.where((l) => l.isCompleted).toList();
      // Draft logs (incomplete with step progress)
      final draftLogs = rawDbLogs.where((l) => !l.isCompleted && l.lastCompletedStep > 0).toList();

      final Map<int, MockDailyLog> fetchedMap = {};
      final Map<int, DailyLog> fetchedDraftsMap = {};

      for (final log in dbLogs) {
        final day = log.date.day;

        final symptomsList = log.symptoms.map((s) {
          final sev = s.severity == 'Mild'
              ? '1/5'
              : s.severity == 'Moderate'
                  ? '3/5'
                  : '5/5';
          return '${s.symptom.name} · $sev';
        }).toList();

        final List<Map<String, String>> hrtList = [];
        if (log.hrtIntakes.isNotEmpty) {
          for (final intake in log.hrtIntakes) {
            if (intake.isTaken) {
              hrtList.add({
                'id': intake.medicationId,
                'name': intake.name,
                'details': '${intake.dose.toStringAsFixed(0)} ${intake.unit}',
                'status': 'Taken ${intake.time}',
                'isTaken': 'true',
              });
            }
          }
        } else {
          if (log.estradiolChecked) {
            hrtList.add({
              'name': 'Estradiol',
              'details': '${log.estradiolDose.toStringAsFixed(0)} ${log.estradiolUnit} · Patch',
              'status': 'Taken ${log.estradiolTime}',
              'isTaken': 'true',
            });
          }
          if (log.progesteroneChecked) {
            hrtList.add({
              'name': 'Progesterone',
              'details': '${log.progesteroneDose.toStringAsFixed(0)} ${log.progesteroneUnit} · Tablet',
              'status': 'Taken ${log.progesteroneTime}',
              'isTaken': 'true',
            });
          }
        }

        fetchedMap[day] = MockDailyLog(
          symptoms: symptomsList,
          sleepInfo: '${log.sleepDuration} hours',
          moodInfo: 'Logged',
          hrt: hrtList,
          triggers: log.triggers,
          itemsCount: symptomsList.length + hrtList.length + log.triggers.length,
          originalLog: log,
        );
      }

      for (final draft in draftLogs) {
        fetchedDraftsMap[draft.date.day] = draft;
      }

      setState(() {
        _monthLogsCache[key] = fetchedMap;
        _monthDraftsCache[key] = fetchedDraftsMap;
      });
    } catch (e) {
      debugPrint("Error fetching logs for $key: $e");
    }
  }

  // Legacy wrapper used by existing save calls
  Future<void> _fetchLogsForFocusedMonth() {
    final key = _monthKey(_focusedMonth);
    setState(() {
      _monthLogsCache.remove(key);
      _monthDraftsCache.remove(key);
    });
    return _fetchLogsForMonth(_focusedMonth);
  }

  MockDailyLog? _getLogForDay(int day) {
    final cached = _monthLogsCache[_monthKey(_focusedMonth)];
    if (cached != null && cached.containsKey(day)) {
      return cached[day];
    }
    final isApril = _focusedMonth.year == 2026 && _focusedMonth.month == 4;
    if (isApril && _aprilLogs.containsKey(day)) {
      return _aprilLogs[day];
    }
    return null;
  }

  MockDailyLog? _getLogForSelectedDate() {
    if (_selectedDate == null) return null;
    final cached = _monthLogsCache[_monthKey(_selectedDate!)];
    if (cached != null && cached.containsKey(_selectedDate!.day)) {
      return cached[_selectedDate!.day];
    }
    final isApril = _selectedDate!.year == 2026 && _selectedDate!.month == 4;
    if (isApril && _aprilLogs.containsKey(_selectedDate!.day)) {
      return _aprilLogs[_selectedDate!.day];
    }
    return null;
  }

  DailyLog? _getDraftForSelectedDate() {
    if (_selectedDate == null) return null;
    final cached = _monthDraftsCache[_monthKey(_selectedDate!)];
    if (cached != null && cached.containsKey(_selectedDate!.day)) {
      return cached[_selectedDate!.day];
    }
    return null;
  }

  MockDailyLog? _getLogForDayAndMonth(DateTime date) {
    final cached = _monthLogsCache[_monthKey(date)];
    if (cached != null && cached.containsKey(date.day)) {
      return cached[date.day];
    }
    final isApril = date.year == 2026 && date.month == 4;
    if (isApril && _aprilLogs.containsKey(date.day)) {
      return _aprilLogs[date.day];
    }
    return null;
  }

  Map<String, dynamic> _getWeeklyTrendsData() {
    if (_selectedDate == null) {
      return {
        'avgIntensity': 0.0,
        'avgSleep': 0.0,
        'intensityHeights': <double>[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        'sleepHeights': <double>[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        'intensityChange': '↓ 0%',
        'sleepChange': '↓ 0%',
        'isIntensityGood': true,
        'isSleepGood': true,
      };
    }

    // Find the Monday of the week containing _selectedDate
    final weekday = _selectedDate!.weekday;
    final monday = _selectedDate!.subtract(Duration(days: weekday - 1));

    final List<double> intensities = [];
    final List<double> sleepHours = [];

    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final log = _getLogForDayAndMonth(date);

      if (log != null) {
        // Parse sleep
        double sleepVal = 0.0;
        if (log.originalLog != null) {
          sleepVal = log.originalLog!.sleepDuration;
        } else {
          final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(log.sleepInfo);
          if (match != null) {
            sleepVal = double.tryParse(match.group(1) ?? '0.0') ?? 0.0;
          }
        }
        if (sleepVal > 0.0) {
          sleepHours.add(sleepVal);
        } else {
          sleepHours.add(0.0);
        }

        // Parse intensity
        double maxIntensity = 0.0;
        for (final s in log.symptoms) {
          final parts = s.split(' · ');
          if (parts.length > 1) {
            final scoreStr = parts[1].split('/').first.trim();
            final score = double.tryParse(scoreStr) ?? 0.0;
            if (score > maxIntensity) {
              maxIntensity = score;
            }
          }
        }
        intensities.add(maxIntensity);
      } else {
        sleepHours.add(0.0);
        intensities.add(0.0);
      }
    }

    final totalIntensity = intensities.reduce((a, b) => a + b);
    final totalSleep = sleepHours.reduce((a, b) => a + b);

    final loggedDaysIntensity = intensities.where((v) => v > 0).length;
    final loggedDaysSleep = sleepHours.where((v) => v > 0).length;

    final avgIntensity = loggedDaysIntensity > 0 ? totalIntensity / loggedDaysIntensity : 0.0;
    final avgSleep = loggedDaysSleep > 0 ? totalSleep / loggedDaysSleep : 0.0;

    int loggedDaysThisWeek = 0;
    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final log = _getLogForDayAndMonth(date);
      if (log != null) {
        loggedDaysThisWeek++;
      }
    }

    // Scale heights to [0.0, 1.0] for sparklines (intensity scale max is 5, sleep max is 10)
    final intensityHeights = intensities.map((v) => (v / 5.0).clamp(0.0, 1.0)).toList();
    final sleepHeights = sleepHours.map((v) => (v / 10.0).clamp(0.0, 1.0)).toList();

    return {
      'avgIntensity': avgIntensity,
      'avgSleep': avgSleep,
      'intensityHeights': intensityHeights,
      'sleepHeights': sleepHeights,
      'intensityChange': avgIntensity > 3.0 ? '↑ 14%' : '↓ 12%',
      'sleepChange': avgSleep < 6.0 ? '↓ 8%' : '↑ 4%',
      'isIntensityGood': avgIntensity <= 3.0,
      'isSleepGood': avgSleep >= 7.0,
      'hasEnoughData': loggedDaysThisWeek >= 3,
    };
  }


  Future<void> _saveLogToFirestore(int day, MockDailyLog mockLog) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    final dateStr = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

    int caffeineCups = 0;
    int alcoholGlasses = 0;
    String stressLevel = 'Moderate';
    bool foodsTriggered = false;
    String foodsNotes = '';
    final Map<String, int> customCounters = Map<String, int>.from(mockLog.originalLog?.customTriggerCounters ?? {});

    for (final t in mockLog.triggers) {
      if (t.startsWith('Caffeine:')) {
        final val = t.replaceAll('Caffeine:', '').trim();
        caffeineCups = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      } else if (t.startsWith('Alcohol:')) {
        final val = t.replaceAll('Alcohol:', '').trim();
        alcoholGlasses = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      } else if (t.startsWith('Stress:')) {
        final val = t.replaceAll('Stress:', '').trim();
        stressLevel = val;
      } else if (t.startsWith('Foods:')) {
        foodsTriggered = true;
        foodsNotes = t.replaceAll('Foods:', '').trim();
      } else if (t.startsWith('Exercise:')) {
        final val = t.replaceAll('Exercise:', '').trim();
        final mins = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
        if (mins != null && mins > 0) {
          customCounters['t_exercise'] = mins;
          customCounters['exercise'] = mins;
        } else {
          customCounters.remove('t_exercise');
          customCounters.remove('exercise');
        }
      } else if (t.trim().toLowerCase() == 'exercise') {
        customCounters.remove('t_exercise');
        customCounters.remove('exercise');
      }
    }

    final List<HrtIntakeLog> hrtIntakes = [];
    for (final h in mockLog.hrt) {
      final name = h['name'] ?? '';
      final isTaken = h['isTaken'] == 'true';
      final details = h['details'] ?? '';
      final status = h['status'] ?? '';

      String time = '08:30 AM';
      if (status.toLowerCase().contains('taken') && !status.toLowerCase().contains('not')) {
        time = status.replaceAll(RegExp(r'taken\s*', caseSensitive: false), '').trim();
        if (!time.contains('AM') && !time.contains('PM')) {
          time = '$time AM';
        }
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
    if (mockLog.originalLog != null) {
      final orig = mockLog.originalLog!;
      final List<LoggedSymptom> loggedSymptoms = mockLog.symptoms.map((s) {
        final parts = s.split(' · ');
        final name = parts.first.trim();
        String severityStr = 'Moderate';
        if (parts.length > 1) {
          final scoreStr = parts[1].split('/').first.trim();
          final score = int.tryParse(scoreStr);
          if (score != null) {
            if (score <= 2) {
              severityStr = 'Mild';
            } else if (score <= 3) {
              severityStr = 'Moderate';
            } else {
              severityStr = 'Severe';
            }
          }
        }
        final origMatching = orig.symptoms.where(
          (ls) => ls.symptom.name.toLowerCase() == name.toLowerCase(),
        ).firstOrNull;

        return LoggedSymptom(
          symptom: Symptom(
            id: origMatching?.symptom.id ?? sanitizeSymptomId('s_${name.toLowerCase().replaceAll(' ', '_')}'),
            name: name,
            iconName: origMatching?.symptom.iconName ??
                (name.toLowerCase().contains('flash')
                    ? 'thermostat'
                    : name.toLowerCase().contains('mood')
                        ? 'mood'
                        : name.toLowerCase().contains('sleep')
                            ? 'dark_mode'
                            : name.toLowerCase().contains('dry')
                                ? 'opacity'
                                : 'accessibility_new'),
            category: origMatching?.symptom.category ?? 'General',
          ),
          severity: severityStr,
          durationMinutes: origMatching?.durationMinutes,
        );
      }).toList();

      bool estradiolChecked = false;
      double estradiolDose = 50.0;
      String estradiolUnit = 'mcg';
      String estradiolTime = '08:30 AM';

      bool progesteroneChecked = false;
      double progesteroneDose = 100.0;
      String progesteroneUnit = 'mg';
      String progesteroneTime = '08:00 PM';

      for (final h in mockLog.hrt) {
        final name = h['name']?.toLowerCase() ?? '';
        final isTaken = h['isTaken'] == 'true';
        final details = h['details'] ?? '';
        final status = h['status'] ?? '';

        String time = '08:30 AM';
        if (status.toLowerCase().contains('taken') && !status.toLowerCase().contains('not')) {
          time = status.replaceAll(RegExp(r'taken\s*', caseSensitive: false), '').trim();
          if (!time.contains('AM') && !time.contains('PM')) {
            time = '$time AM';
          }
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

        if (name.contains('estradiol') || name.contains('estrogen') || name.contains('estradot')) {
          estradiolChecked = isTaken;
          estradiolDose = dose;
          estradiolUnit = unit;
          estradiolTime = time;
        } else if (name.contains('progesterone') || name.contains('utrogestan')) {
          progesteroneChecked = isTaken;
          progesteroneDose = dose;
          progesteroneUnit = unit;
          progesteroneTime = time;
        }
      }

      dailyLog = orig.copyWith(
        symptoms: loggedSymptoms,
        triggers: mockLog.triggers,
        caffeineCups: caffeineCups,
        alcoholGlasses: alcoholGlasses,
        stressLevel: stressLevel,
        foodsTriggered: foodsTriggered,
        foodsNotes: foodsNotes,
        customTriggerCounters: customCounters,
        estradiolChecked: estradiolChecked,
        estradiolDose: estradiolDose,
        estradiolUnit: estradiolUnit,
        estradiolTime: estradiolTime,
        progesteroneChecked: progesteroneChecked,
        progesteroneDose: progesteroneDose,
        progesteroneUnit: progesteroneUnit,
        progesteroneTime: progesteroneTime,
        hrtIntakes: hrtIntakes,
      );
    } else {
      final List<LoggedSymptom> loggedSymptoms = mockLog.symptoms.map((s) {
        final parts = s.split(' · ');
        final name = parts.first.trim();
        String severityStr = 'Moderate';
        if (parts.length > 1) {
          final scoreStr = parts[1].split('/').first.trim();
          final score = int.tryParse(scoreStr);
          if (score != null) {
            if (score <= 2) {
              severityStr = 'Mild';
            } else if (score <= 3) {
              severityStr = 'Moderate';
            } else {
              severityStr = 'Severe';
            }
          }
        }
        return LoggedSymptom(
          symptom: Symptom(
            id: sanitizeSymptomId('s_${name.toLowerCase().replaceAll(' ', '_')}'),
            name: name,
            iconName: name.toLowerCase().contains('flash')
                ? 'thermostat'
                : name.toLowerCase().contains('mood')
                    ? 'mood'
                    : name.toLowerCase().contains('sleep')
                        ? 'dark_mode'
                        : name.toLowerCase().contains('dry')
                            ? 'opacity'
                            : 'accessibility_new',
            category: 'General',
          ),
          severity: severityStr,
          durationMinutes: null,
        );
      }).toList();

      bool estradiolChecked = false;
      double estradiolDose = 50.0;
      String estradiolUnit = 'mcg';
      String estradiolTime = '08:30 AM';

      bool progesteroneChecked = false;
      double progesteroneDose = 100.0;
      String progesteroneUnit = 'mg';
      String progesteroneTime = '08:00 PM';

      for (final h in mockLog.hrt) {
        final name = h['name']?.toLowerCase() ?? '';
        final isTaken = h['isTaken'] == 'true';
        final details = h['details'] ?? '';
        final status = h['status'] ?? '';

        String time = '08:30 AM';
        if (status.toLowerCase().contains('taken') && !status.toLowerCase().contains('not')) {
          time = status.replaceAll(RegExp(r'taken\s*', caseSensitive: false), '').trim();
          if (!time.contains('AM') && !time.contains('PM')) {
            time = '$time AM';
          }
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

        if (name.contains('estradiol') || name.contains('estrogen') || name.contains('estradot')) {
          estradiolChecked = isTaken;
          estradiolDose = dose;
          estradiolUnit = unit;
          estradiolTime = time;
        } else if (name.contains('progesterone') || name.contains('utrogestan')) {
          progesteroneChecked = isTaken;
          progesteroneDose = dose;
          progesteroneUnit = unit;
          progesteroneTime = time;
        }
      }

      dailyLog = DailyLog(
        id: dateStr,
        userId: user.uid,
        date: targetDate,
        symptoms: loggedSymptoms,
        triggers: mockLog.triggers,
        caffeineCups: caffeineCups,
        alcoholGlasses: alcoholGlasses,
        stressLevel: stressLevel,
        foodsTriggered: foodsTriggered,
        foodsNotes: foodsNotes,
        customTriggerCounters: customCounters,
        customTriggerTexts: {},
        estradiolChecked: estradiolChecked,
        estradiolDose: estradiolDose,
        estradiolUnit: estradiolUnit,
        estradiolTime: estradiolTime,
        progesteroneChecked: progesteroneChecked,
        progesteroneDose: progesteroneDose,
        progesteroneUnit: progesteroneUnit,
        progesteroneTime: progesteroneTime,
        vitaminDChecked: false,
        magnesiumChecked: false,
        sleepDuration: 7.0,
        hydrationCups: 0,
        weight: null,
        additionalNotes: '',
        hrtIntakes: hrtIntakes,
        createdAt: DateTime.now(),
      );
    }

    mockLog.originalLog = dailyLog;
    setState(() {
      final cacheKey = _monthKey(targetDate);
      if (!_monthLogsCache.containsKey(cacheKey)) {
        _monthLogsCache[cacheKey] = {};
      }
      _monthLogsCache[cacheKey]![day] = mockLog;
    });

    ref.read(firestoreServiceProvider).saveDailyLog(user.uid, dailyLog).catchError((e) {
      debugPrint("Error saving daily log: $e");
    });
  }

  void _previousMonth() {
    setState(() {
      _isSwiping = true;
      _swipeDirection = 1; // Slide in from left to right (natural for going to previous month)
      _dragOffset = 0.0;
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    _fetchLogsForMonth(_focusedMonth);
    _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month - 1));
    _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month + 1));
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
      _swipeDirection = -1; // Slide in from right to left (natural for going to next month)
      _dragOffset = 0.0;
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    _fetchLogsForMonth(_focusedMonth);
    _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month - 1));
    _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month + 1));
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        setState(() {
          _isSwiping = false;
        });
      }
    });
  }

  void _onPageChanged(int page) {
    final delta = page - _initialPage;
    final now = DateTime.now();
    final newMonth = DateTime(now.year, now.month + delta);
    setState(() {
      _focusedMonth = newMonth;
    });
    // Fetch logs for the current page, and prefetch adjacent pages
    _fetchLogsForMonth(newMonth);
    _fetchLogsForMonth(DateTime(newMonth.year, newMonth.month - 1));
    _fetchLogsForMonth(DateTime(newMonth.year, newMonth.month + 1));
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    });
  }


  List<Map<String, String>> _convertToEditSymptoms(MockDailyLog log) {
    return log.symptoms.map<Map<String, String>>((s) {
      final parts = s.split(' · ');
      final name = parts.first.trim();
      String severity = 'Moderate';
      if (parts.length > 1) {
        final scoreStr = parts[1].split('/').first.trim();
        final score = int.tryParse(scoreStr);
        if (score != null) {
          if (score <= 2) {
            severity = 'Mild';
          } else if (score <= 3) {
            severity = 'Moderate';
          } else {
            severity = 'Severe';
          }
        } else {
          severity = parts[1].trim();
        }
      }

      int? duration;
      if (log.originalLog != null) {
        final matching = log.originalLog!.symptoms.where(
          (ls) => ls.symptom.name.toLowerCase() == name.toLowerCase(),
        ).firstOrNull;
        if (matching != null && matching.durationMinutes != null && matching.durationMinutes! > 0) {
          duration = matching.durationMinutes;
        }
      }

      return <String, String>{
        'name': name,
        'severity': severity,
        'duration': duration != null ? duration.toString() : '',
      };
    }).toList();
  }

  void _updateLogSymptoms(MockDailyLog log, List<Map<String, String>> newSymptoms) {
    log.symptoms = _convertFromEditSymptoms(newSymptoms);
    log.itemsCount = log.symptoms.length + log.hrt.length + log.triggers.length;

    if (log.originalLog != null) {
      final List<LoggedSymptom> updatedLoggedSymptoms = [];
      for (final s in newSymptoms) {
        final name = s['name'] ?? '';
        final severity = s['severity'] ?? 'Moderate';
        final rawDuration = int.tryParse(s['duration'] ?? '');
        final durationMinutes = (rawDuration != null && rawDuration > 0) ? rawDuration : null;

        final existing = log.originalLog!.symptoms.where(
          (ls) => ls.symptom.name.toLowerCase() == name.toLowerCase(),
        ).firstOrNull;

        final id = existing?.symptom.id ?? sanitizeSymptomId('s_${name.toLowerCase().replaceAll(' ', '_')}');

        updatedLoggedSymptoms.add(
          LoggedSymptom(
            symptom: Symptom(
              id: id,
              name: name,
              iconName: existing?.symptom.iconName ?? 'medical_services',
              category: existing?.symptom.category ?? 'General',
            ),
            severity: severity,
            durationMinutes: durationMinutes,
          ),
        );
      }

      log.originalLog = log.originalLog!.copyWith(
        symptoms: updatedLoggedSymptoms,
      );
    }
  }

  List<String> _convertFromEditSymptoms(List<Map<String, String>> list) {
    return list.map((s) {
      final name = s['name'] ?? '';
      final severity = s['severity'] ?? 'Moderate';
      int score = 3;
      if (severity == 'Mild') {
        score = 1;
      } else if (severity == 'Moderate') {
        score = 3;
      } else if (severity == 'Severe') {
        score = 5;
      }
      return '$name · $score/5';
    }).toList();
  }

  List<Map<String, dynamic>> _convertToEditTriggers(List<String> list) {
    return list.map<Map<String, dynamic>>((t) {
      final parsed = parseTriggerString(t);
      final triggerLib = ref.read(triggerLibraryProvider);
      final trigger = triggerLib.firstWhere(
        (tr) => tr.id == parsed.id,
        orElse: () => TriggerOption(
          id: parsed.id,
          name: parsed.label,
          description: '',
          iconName: 'spa',
          category: 'Other',
        ),
      );

      return <String, dynamic>{
        'name': parsed.label,
        'value': parsed.value ?? 'Logged',
        'icon': trigger.getIconData(),
      };
    }).toList();
  }

  List<String> _convertFromEditTriggers(List<Map<String, dynamic>> list) {
    return list.map<String>((t) {
      final name = t['name'] as String;
      final val = t['value'] ?? 'Logged';

      final def = kTriggerLibrary.firstWhere(
        (tr) => tr.label.toLowerCase() == name.toLowerCase() || tr.id.toLowerCase() == name.toLowerCase(),
        orElse: () => TriggerDefinition(
          id: name.toLowerCase().replaceAll(' ', '_'),
          label: name,
          category: TriggerCategory.lifestyle,
          tier: TriggerTier.extended,
        ),
      );

      if (val != 'Logged' && val != 'None' && val != '') {
        return '${def.label}: $val';
      } else {
        return def.label;
      }
    }).toList();
  }

  void _showAddSymptomSheet(MockDailyLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SymptomLoggingSheet(
        loggedSymptoms: _convertToEditSymptoms(log),
        onSave: (name, severity, duration) {
          setState(() {
            final editList = _convertToEditSymptoms(log);
            final existingIndex = editList.indexWhere((s) => s['name'] == name);
            if (existingIndex != -1) {
              editList[existingIndex]['severity'] = severity;
              editList[existingIndex]['duration'] = duration.toString();
            } else {
              editList.add(<String, String>{
                'name': name,
                'severity': severity,
                'duration': duration.toString(),
              });
            }
            _updateLogSymptoms(log, editList);
          });
          _saveLogToFirestore(_selectedDate!.day, log);
        },
      ),
    );
  }

  void _showSymptomEditSheet(MockDailyLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSymptomsModalSheet(
        initialSymptoms: _convertToEditSymptoms(log),
        onSave: (newSymptoms) {
          setState(() {
            _updateLogSymptoms(log, newSymptoms);
          });
          _saveLogToFirestore(_selectedDate!.day, log);
        },
      ),
    );
  }

  void _showAddTriggerSheet(MockDailyLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TriggerLoggingSheet(
        loggedTriggers: _convertToEditTriggers(log.triggers),
        onSave: (name, value, icon) {
          setState(() {
            final editList = _convertToEditTriggers(log.triggers);
            final existingIndex = editList.indexWhere((t) => t['name'] == name);
            if (existingIndex != -1) {
              editList[existingIndex]['value'] = value;
            } else {
              editList.add(<String, dynamic>{'name': name, 'value': value, 'icon': icon});
            }
            log.triggers = _convertFromEditTriggers(editList);
            log.itemsCount = log.symptoms.length + log.hrt.length + log.triggers.length;
          });
          _saveLogToFirestore(_selectedDate!.day, log);
        },
      ),
    );
  }

  void _showTriggerEditSheet(MockDailyLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTriggersModalSheet(
        initialTriggers: _convertToEditTriggers(log.triggers),
        onSave: (newTriggers) {
          setState(() {
            log.triggers = _convertFromEditTriggers(newTriggers);
            log.itemsCount = log.symptoms.length + log.hrt.length + log.triggers.length;
          });
          _saveLogToFirestore(_selectedDate!.day, log);
        },
      ),
    );
  }

  void _showHrtEditSheet(MockDailyLog log) {
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
          initialHrt: log.hrt.map((e) => Map<String, String>.from(e)).toList(),
          selectedDate: _selectedDate,
          onSave: (updated) {
            final now = DateTime.now();
            final isToday = _selectedDate == null ||
                (_selectedDate!.year == now.year &&
                 _selectedDate!.month == now.month &&
                 _selectedDate!.day == now.day);

            if (isToday) {
              final updatedIds = updated.map((e) => e['id']).where((id) => id != null).toSet();
              final medications = ref.read(medicationsProvider).medications;
              for (final med in medications) {
                if (!updatedIds.contains(med.id)) {
                  ref.read(medicationsProvider.notifier).removeMedication(med.id);
                }
              }
            }

            final takenOnly = updated.where((e) => e['isTaken'] == 'true').toList();
            setState(() {
              log.hrt.clear();
              log.hrt.addAll(takenOnly);
            });
            _saveLogToFirestore(_selectedDate!.day, log);
          },
        ),
      ),
    );
  }



  Widget _buildCalendarSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((d) {
              return Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.85,
              mainAxisSpacing: 6,
            ),
            itemCount: 35,
            itemBuilder: (_, i) => Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder skeleton shown below the calendar while day data is loading
  Widget _buildDayDetailSkeleton() {
    return Column(
      children: List.generate(3, (i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLog = _getLogForSelectedDate();
    final activeDraft = _getDraftForSelectedDate();
    final isCurrentMonthLoaded = _monthLogsCache.containsKey(_monthKey(_focusedMonth));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isSelectedFuture = _selectedDate != null && _selectedDate!.isAfter(today);

    return Container(
      color: AppTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cycle Tracker',
              style: GoogleFonts.notoSerif(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Track your cycle, symptoms, and daily logs.",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            _buildMonthNavigation(),
            const SizedBox(height: 16),
            _buildCalendarCard(),
            const SizedBox(height: 16),
            _buildLegendAccordion(),
            const SizedBox(height: 24),
            // Show skeleton while initial load or current month fetching, logged state otherwise
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: (!isCurrentMonthLoaded && _isFirstPageLoad)
                  ? _buildDayDetailSkeleton()
                  : (_selectedDate == null
                      ? _buildNoDaySelectedState()
                      : (isSelectedFuture
                          ? _buildFutureDateState()
                          : (activeLog != null
                              ? _buildLoggedDetailsState(activeLog)
                              : (activeDraft != null
                                  ? _buildDraftInProgressState(activeDraft)
                                  : _buildUnloggedState())))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDaySelectedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.touch_app_outlined,
            size: 40,
            color: Color(0xFF9B8B7E),
          ),
          const SizedBox(height: 12),
          Text(
            'Select a Day',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose any day on the calendar to view its logged symptoms, triggers, and medications.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureDateState() {
    return Container(
      key: const ValueKey('future_date'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 40,
            color: Color(0xFFBBB0A8),
          ),
          const SizedBox(height: 12),
          Text(
            'Future Date',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You cannot log data for a future date. Please select today or a past day.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftInProgressState(DailyLog draftLog) {
    final step = draftLog.lastCompletedStep.clamp(1, 5);
    final progress = step / 5.0;
    final percent = (progress * 100).toInt();

    return Container(
      key: ValueKey('draft_${draftLog.id}_$step'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Log: ${_months[_selectedDate!.month - 1]} ${_selectedDate!.day}',
                style: GoogleFonts.notoSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2DFD0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'IN PROGRESS',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2DFD0).withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pending_actions,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Logging in Progress',
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF51443A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$step/5 pages logged ($percent%)',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEADBCE),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () async {
                      final targetDate = _selectedDate!;
                      await context.push('/daily-logging', extra: targetDate);
                      final targetMonth = DateTime(targetDate.year, targetDate.month);
                      final key = _monthKey(targetMonth);
                      setState(() {
                        _monthLogsCache.remove(key);
                        _monthDraftsCache.remove(key);
                      });
                      _fetchLogsForMonth(targetMonth);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'CONTINUE',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
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
                'Select Month (2026)',
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
                    final isSelected = _focusedMonth.month == monthVal && _focusedMonth.year == 2026;
                    return GestureDetector(
                      onTap: () {
                        final now = DateTime.now();
                        final selectedMonth = DateTime(2026, monthVal);
                        final monthsDiff = ((selectedMonth.year - now.year) * 12) + (selectedMonth.month - now.month);
                        _pageController.animateToPage(
                          _initialPage + monthsDiff,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
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
                          monthNames[index].substring(0, 3).toUpperCase(),
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

  Widget _buildMonthNavigation() {
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    final nextMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    
    final monthsShort = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthNamesFull = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final prevLabel = monthsShort[prevMonth.month - 1];
    final nextLabel = monthsShort[nextMonth.month - 1];
    final currentMonthLabel = '${monthNamesFull[_focusedMonth.month - 1]} ${_focusedMonth.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 40,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _previousMonth,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left, size: 22, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      prevLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.outline,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          height: 36,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showMonthPicker,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentMonthLabel.toUpperCase(),
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          height: 40,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _nextMonth,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nextLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.outline,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 22, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    final monthNamesFull = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final currentMonthLabel = monthNamesFull[_focusedMonth.month - 1];

    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    final nextMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);

    final isApril = _focusedMonth.year == 2026 && _focusedMonth.month == 4;
    final isPrevApril = prevMonth.year == 2026 && prevMonth.month == 4;
    final isNextApril = nextMonth.year == 2026 && nextMonth.month == 4;

    return GestureDetector(
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.outlineVariant.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[300]!.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((day) {
                    return Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary.withValues(alpha: 0.6),
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final cellWidth = width / 7;

                    // Dynamically calculate row counts for the months to adapt height exactly
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

                    // Interpolate the height smoothly during swipe between current and adjacent month
                    // Each row cell is a square (aspectRatio: 1) with height equal to cellWidth.
                    // Each row has a vertical padding of 4.0 (symmetric 2.0). 
                    // The selected week container introduces a 1.0px border (top/bottom = 2.0px).
                    // We add a safety margin of 6.0px per row dynamically to prevent clipping across all screen sizes.
                    final safetyCellHeight = cellWidth + 6.0;
                    double targetHeight = currentRows * safetyCellHeight;
                    if (_isSwiping && _dragOffset != 0.0) {
                      final progress = (_dragOffset.abs() / width).clamp(0.0, 1.0);
                      final adjacentRows = _dragOffset > 0 ? prevRows : nextRows;
                      targetHeight = (currentRows * safetyCellHeight) + (adjacentRows - currentRows) * safetyCellHeight * progress;
                    }

                    return ClipRect(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height: targetHeight,
                        child: Stack(
                          children: [
                            // Previous Month (Slides in from the left when dragging right)
                            Transform.translate(
                              offset: Offset(_dragOffset - width, 0),
                              child: Container(
                                width: width,
                                height: prevRows * safetyCellHeight,
                                child: _buildDaysGridForMonth(prevMonth, isPrevApril),
                              ),
                            ),
                            // Current Month
                            Transform.translate(
                              offset: Offset(_dragOffset, 0),
                              child: Container(
                                width: width,
                                height: currentRows * safetyCellHeight,
                                child: _buildDaysGridForMonth(_focusedMonth, isApril),
                              ),
                            ),
                            // Next Month (Slides in from the right when dragging left)
                            Transform.translate(
                              offset: Offset(_dragOffset + width, 0),
                              child: Container(
                                width: width,
                                height: nextRows * safetyCellHeight,
                                child: _buildDaysGridForMonth(nextMonth, isNextApril),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
                  currentMonthLabel,
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
  }

  Widget _buildDaysGrid(bool isApril) {
    return _buildDaysGridForMonth(_focusedMonth, isApril);
  }

  Widget _buildDaysGridForMonth(DateTime targetMonth, bool isApril) {
    final totalDays = DateUtils.getDaysInMonth(targetMonth.year, targetMonth.month);
    final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
    
    // weekday is 1 (Monday) to 7 (Sunday)
    final startWeekday = firstDayOfMonth.weekday;
    final prefixDaysCount = startWeekday - 1; // days to show from previous month
    
    final List<Widget> dayWidgets = [];
    
    // Previous month overflow days
    final prevMonth = DateTime(targetMonth.year, targetMonth.month - 1);
    final prevMonthTotalDays = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    for (int i = prefixDaysCount - 1; i >= 0; i--) {
      final dayNum = prevMonthTotalDays - i;
      dayWidgets.add(_buildOverflowDay('$dayNum'));
    }
    
    // Target month days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cachedLogsForMonth = _monthLogsCache[_monthKey(targetMonth)] ?? {};
    final cachedDraftsForMonth = _monthDraftsCache[_monthKey(targetMonth)] ?? {};
    for (int day = 1; day <= totalDays; day++) {
      MockDailyLog? logForDay = cachedLogsForMonth[day];
      DailyLog? draftForDay = cachedDraftsForMonth[day];
      if (logForDay == null && isApril) {
        logForDay = _aprilLogs[day];
      }
      final dayDate = DateTime(targetMonth.year, targetMonth.month, day);
      final isFuture = dayDate.isAfter(today);
      final isToday = dayDate.isAtSameMomentAs(today);
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == targetMonth.year &&
          _selectedDate!.month == targetMonth.month &&
          _selectedDate!.day == day;
      final hasData = logForDay != null;
      final hasDraft = !hasData && draftForDay != null;
      
      Color? backgroundIntensity;
      if (hasData && logForDay != null) {
        if (logForDay.symptoms.isNotEmpty) {
          final firstSymptom = logForDay.symptoms.first.toLowerCase();
          if (firstSymptom.contains('severe') || firstSymptom.contains('5/5') || firstSymptom.contains('4/5')) {
            backgroundIntensity = const Color(0xFFF9B7A9).withValues(alpha: 0.6);
          } else {
            backgroundIntensity = const Color(0xFFEDDDF5).withValues(alpha: 0.6);
          }
        } else {
          backgroundIntensity = const Color(0xFFEDDDF5).withValues(alpha: 0.4);
        }
      } else if (hasDraft) {
        backgroundIntensity = const Color(0xFFF2DFD0).withValues(alpha: 0.6);
      }
      
      dayWidgets.add(
        _buildCalendarDay(
          day: day,
          isSelected: isSelected,
          hasData: hasData,
          isFuture: isFuture,
          isToday: isToday,
          backgroundColor: backgroundIntensity,
          onTap: isFuture ? null : () => setState(() => _selectedDate = dayDate),
        ),
      );
    }
    
    // Next month overflow days to pad to a multiple of 7
    final remaining = dayWidgets.length % 7;
    if (remaining > 0) {
      final suffixDaysCount = 7 - remaining;
      for (int i = 1; i <= suffixDaysCount; i++) {
        dayWidgets.add(_buildOverflowDay('$i'));
      }
    }
    
    // Grid layout with 7 items per row
    final rowsCount = (dayWidgets.length / 7).ceil();
    
    // Find the row index of the selected date
    int? selectedRowIndex;
    if (_selectedDate != null &&
        _selectedDate!.year == targetMonth.year &&
        _selectedDate!.month == targetMonth.month) {
      final selectedDayIndex = prefixDaysCount + _selectedDate!.day - 1;
      selectedRowIndex = selectedDayIndex ~/ 7;
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rowsCount, (rowIndex) {
          final start = rowIndex * 7;
          final end = start + 7;
          final rowWidgets = dayWidgets.sublist(start, end);
          final isWeekSelected = selectedRowIndex == rowIndex;

          Widget rowContent = Row(
            children: rowWidgets.map((w) => Expanded(child: AspectRatio(aspectRatio: 1, child: w))).toList(),
          );

          if (isWeekSelected) {
            rowContent = Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryFixed,
                  width: 1,
                ),
              ),
              child: rowContent,
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: rowContent,
          );
        }),
      ),
    );
  }

  Widget _buildOverflowDay(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: const Color(0xFFD8D0C8),
        ),
      ),
    );
  }

  Widget _buildCalendarDay({
    required int day,
    required bool isSelected,
    required bool hasData,
    required Color? backgroundColor,
    required VoidCallback? onTap,
    bool isFuture = false,
    bool isToday = false,
  }) {
    // Future dates — non-interactive, visually dimmed
    if (isFuture) {
      return Center(
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: const Color(0xFFD9D1CB),
            ),
          ),
        ),
      );
    }

    // Today indicator (small dot below number when not selected)
    if (isToday && !isSelected) {
      return GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 1),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isSelected) {
      if (hasData) {
        // Selected + logged (Solid filled circle)
        return GestureDetector(
          onTap: onTap,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // Selected + unlogged (Outline circle)
        return GestureDetector(
          onTap: onTap,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Default unselected past/present days (matching Severity Legend: white for No Data)
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: backgroundColor != null
                  ? Colors.transparent
                  : const Color(0xFFE5DFD7),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              if (hasData && backgroundColor == null) ...[
                const SizedBox(height: 1),
                Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- STATE 1: EMPTY STATE ---
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_calendar,
              color: AppTheme.outline,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No logs for this month yet.',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tracking daily helps you discover patterns in your wellness.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final totalDays = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
              final day = _selectedDate == null ? DateTime.now().day.clamp(1, totalDays) : (_selectedDate!.day > totalDays ? totalDays : _selectedDate!.day);
              final targetDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              await context.push('/daily-logging', extra: targetDate);
              _fetchLogsForFocusedMonth();
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Start Today\'s Log'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STATE 2: UNLOGGED STATE ---
  Widget _buildUnloggedState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Log: ${_months[_selectedDate!.month - 1]} ${_selectedDate!.day}',
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SELECTED',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_busy,
                        color: AppTheme.outline,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final isToday = _selectedDate!.year == now.year &&
                            _selectedDate!.month == now.month &&
                            _selectedDate!.day == now.day;
                        return Text(
                          isToday
                              ? 'No data recorded for today.'
                              : 'No data recorded for this day.',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () async {
                              final targetDate = _selectedDate!;
                              await context.push('/daily-logging', extra: targetDate);
                              final targetMonth = DateTime(targetDate.year, targetDate.month);
                              final key = _monthKey(targetMonth);
                              setState(() {
                                _monthLogsCache.remove(key);
                                _monthDraftsCache.remove(key);
                              });
                              _fetchLogsForMonth(targetMonth);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Builder(
                              builder: (context) {
                                final now = DateTime.now();
                                final isToday = _selectedDate!.year == now.year &&
                                    _selectedDate!.month == now.month &&
                                    _selectedDate!.day == now.day;
                                return Text(
                                  isToday ? 'LOG DAILY ENTRY' : 'LOG RETROACTIVELY',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                );
                              }
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final isToday = _selectedDate!.year == now.year &&
                                _selectedDate!.month == now.month &&
                                _selectedDate!.day == now.day;
                            if (isToday) return const SizedBox.shrink();
                            return TextButton(
                              onPressed: () {
                                setState(() {
                                  _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
                                  _selectedDate = DateTime.now();
                                });
                                _fetchLogsForFocusedMonth();
                              },
                              child: Text(
                                'BACK TO TODAY',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Builder(
          builder: (context) {
            final trends = _getWeeklyTrendsData();
            final hasData = trends['hasEnoughData'] as bool? ?? false;
            return CalendarWeeklyTrendsCard(
              averageIntensity: trends['avgIntensity'],
              averageSleep: trends['avgSleep'],
              intensityHeights: trends['intensityHeights'],
              sleepHeights: trends['sleepHeights'],
              intensityChangeLabel: trends['intensityChange'],
              sleepChangeLabel: trends['sleepChange'],
              isIntensityChangeGood: trends['isIntensityGood'],
              isSleepChangeGood: trends['isSleepGood'],
              isInsufficientData: !hasData,
            );
          },
        ),
        const SizedBox(height: 24),
        Builder(
          builder: (context) {
            final trends = _getWeeklyTrendsData();
            final hasData = trends['hasEnoughData'] as bool? ?? false;
            return CalendarInsightsBanner(isInsufficientData: !hasData);
          },
        ),
      ],
    );
  }

  Widget _buildLegendAccordion() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _legendExpanded = !_legendExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.outline, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'SEVERITY LEGEND',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.outline,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _legendExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.outline,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_legendExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFD0C4BC)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _buildLegendItem(Colors.white, 'No Data', hasBorder: true),
                      _buildLegendItem(const Color(0xFFEDDDF5).withValues(alpha: 0.4), 'Mild (1-3)'),
                      _buildLegendItem(const Color(0xFFEDDDF5).withValues(alpha: 0.8), 'Moderate (4-6)'),
                      _buildLegendItem(const Color(0xFFF9B7A9).withValues(alpha: 0.6), 'Severe (7-10)'),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder
                ? Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5))
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.outline,
          ),
        ),
      ],
    );
  }

  // --- STATE 3: LOGGED STATE ---
  Widget _buildLoggedDetailsState(MockDailyLog log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatSelectedDate(),
                style: GoogleFonts.notoSerif(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${log.itemsCount} items logged',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildLoggedSymptomsCard(log),
        const SizedBox(height: 20),
        _buildLoggedHrtCard(log),
        const SizedBox(height: 20),
        _buildLoggedTriggersCard(log),
        const SizedBox(height: 20),
        _buildPremiumPatternsCard(),
        const SizedBox(height: 20),
        _buildTrendsChartCard(),
        const SizedBox(height: 24),
        Builder(
          builder: (context) {
            final trends = _getWeeklyTrendsData();
            final hasData = trends['hasEnoughData'] as bool? ?? false;
            return CalendarWeeklyTrendsCard(
              averageIntensity: trends['avgIntensity'],
              averageSleep: trends['avgSleep'],
              intensityHeights: trends['intensityHeights'],
              sleepHeights: trends['sleepHeights'],
              intensityChangeLabel: trends['intensityChange'],
              sleepChangeLabel: trends['sleepChange'],
              isIntensityChangeGood: trends['isIntensityGood'],
              isSleepChangeGood: trends['isSleepGood'],
              isInsufficientData: !hasData,
            );
          },
        ),
        const SizedBox(height: 24),
        Builder(
          builder: (context) {
            final trends = _getWeeklyTrendsData();
            final hasData = trends['hasEnoughData'] as bool? ?? false;
            return CalendarInsightsBanner(isInsufficientData: !hasData);
          },
        ),
      ],
    );
  }

  Map<String, Color> _getSymptomColorsForDisplay(String s) {
    final parts = s.split(' · ');
    String severity = 'Moderate';
    if (parts.length > 1) {
      final scoreStr = parts[1].split('/').first.trim();
      final score = int.tryParse(scoreStr);
      if (score != null) {
        if (score <= 2) {
          severity = 'Mild';
        } else if (score <= 3) {
          severity = 'Moderate';
        } else {
          severity = 'Severe';
        }
      }
    }

    switch (severity) {
      case 'Mild':
        return {
          'bg': const Color(0xFFF6FFED),
          'border': const Color(0xFFD9F7BE),
          'text': const Color(0xFF389E0D),
        };
      case 'Severe':
        return {
          'bg': const Color(0xFFFFF1F0),
          'border': const Color(0xFFFFCCC7),
          'text': const Color(0xFFCF1322),
        };
      case 'Moderate':
      default:
        return {
          'bg': const Color(0xFFFFF7E6),
          'border': const Color(0xFFFFE7BA),
          'text': const Color(0xFFD48806),
        };
    }
  }

  Map<String, Color> _getTriggerColorsForDisplay(String fullName) {
    Color bg;
    Color border;
    Color text;

    final name = fullName.toLowerCase();

    if (name.startsWith('stress')) {
      bg = const Color(0xFFF3E8FF);
      border = const Color(0xFFE9D5FF);
      text = const Color(0xFF7E22CE);
    } else if (name.startsWith('caffeine') || name.startsWith('coffee')) {
      bg = const Color(0xFFFDF8F5);
      border = const Color(0xFFEDD8CE);
      text = const Color(0xFF854D0E);
    } else if (name.startsWith('alcohol') || name.startsWith('red wine')) {
      bg = const Color(0xFFFFF1F2);
      border = const Color(0xFFFECDD3);
      text = const Color(0xFFBE123C);
    } else if (name.startsWith('sugar')) {
      bg = const Color(0xFFF7FEE7);
      border = const Color(0xFFE2F9B8);
      text = const Color(0xFF4D7C0F);
    } else if (name.startsWith('lack of sleep') || name.startsWith('poor sleep')) {
      bg = const Color(0xFFF0F9FF);
      border = const Color(0xFFBAE6FD);
      text = const Color(0xFF0369A1);
    } else if (name.startsWith('spicy food') || name.startsWith('foods')) {
      bg = const Color(0xFFFFF1F0);
      border = const Color(0xFFFFCCC7);
      text = const Color(0xFFCF1322);
    } else {
      bg = const Color(0xFFF0FDFA);
      border = const Color(0xFFCCFBF1);
      text = const Color(0xFF0F766E);
    }

    return {
      'bg': bg,
      'border': border,
      'text': text,
    };
  }

  Widget _buildLoggedSymptomsCard(MockDailyLog log) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Symptoms',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showSymptomEditSheet(log),
                  child: Row(
                    children: [
                      Text(
                        'Edit',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...log.symptoms.map((s) {
                final colors = _getSymptomColorsForDisplay(s);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors['bg'],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors['border']!),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors['text'],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () => _showAddSymptomSheet(log),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD0C4BC).withValues(alpha: 0.6),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Color(0xFFA8A29E), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFA8A29E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF2EDEA)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bedtime, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Sleep',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                log.sleepInfo,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mood',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                log.moodInfo,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedHrtCard(MockDailyLog log) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA8D5BA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HRT',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showHrtEditSheet(log),
                  child: Row(
                    children: [
                      Text(
                        'Edit',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: log.hrt.map((h) {
              final isTaken = h['isTaken'] == 'true';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h['name']!,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          h['details']!,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTaken ? const Color(0xFFE8F5ED) : const Color(0xFFFFF1ED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        h['status']!.toUpperCase(),
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isTaken ? const Color(0xFF2D5A3E) : const Color(0xFF8C3A25),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedTriggersCard(MockDailyLog log) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8A89B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Triggers',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showTriggerEditSheet(log),
                  child: Row(
                    children: [
                      Text(
                        'Edit',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...log.triggers.map((t) {
                final colors = _getTriggerColorsForDisplay(t);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors['bg'],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors['border']!),
                  ),
                  child: Text(
                    t,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors['text'],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () => _showAddTriggerSheet(log),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD0C4BC).withValues(alpha: 0.6),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Color(0xFFA8A29E), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFA8A29E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPatternsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 154,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Patterns',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDDDF5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock, size: 12, color: Color(0xFF6C6074)),
                            const SizedBox(width: 4),
                            Text(
                              'PREMIUM',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6C6074),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Red wine (evening)',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              Text(
                                '→ Hot flashes +4.2 next day',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '79% correlation',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Correlation meter bar
                        Container(
                          width: 8,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.outlineVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 64 * 0.79,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Insights are based on your personal historical data over the last 90 days.',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChartCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly trends',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      '30d',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 14, color: AppTheme.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'HOT FLASH FREQUENCY — LAST 7 DAYS',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          // Curved Path Custom Painter
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: FrequencyCurvePainter(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
              return Text(
                day.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF2EDEA)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLEEP QUALITY',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildTrendBar(0.6),
                        _buildTrendBar(0.8),
                        _buildTrendBar(0.4),
                        _buildTrendBar(1.0),
                        _buildTrendBar(0.6),
                        _buildTrendBar(0.8),
                        _buildTrendBar(0.6),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MOOD',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildTrendBar(0.8, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(1.0, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(0.6, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(0.8, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(1.0, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(0.6, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                        _buildTrendBar(0.8, color: const Color(0xFFA8D5BA).withValues(alpha: 0.6)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBar(double factor, {Color color = const Color(0xFFEDDDF5)}) {
    return Expanded(
      child: Container(
        height: 48 * factor,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(2),
          ),
        ),
      ),
    );
  }
}

class FrequencyCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // We map relative coordinates (0-100 x, 0-40 y) to actual size.width and size.height
    double getX(double p) => p * size.width / 100;
    double getY(double p) => p * size.height / 40;

    path.moveTo(getX(0), getY(35));
    path.quadraticBezierTo(getX(7.5), getY(32.5), getX(15), getY(30));
    path.quadraticBezierTo(getX(20), getY(34), getX(25), getY(38));
    path.quadraticBezierTo(getX(32.5), getY(24), getX(40), getY(10));
    path.quadraticBezierTo(getX(47.5), getY(17.5), getX(55), getY(25));
    path.quadraticBezierTo(getX(62.5), getY(15), getX(70), getY(5));
    path.quadraticBezierTo(getX(77.5), getY(10), getX(85), getY(15));
    path.quadraticBezierTo(getX(92.5), getY(13.5), getX(100), getY(12));

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
