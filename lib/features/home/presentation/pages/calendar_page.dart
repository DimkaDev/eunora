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
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  // Navigation states
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate = DateTime.now();
  bool _legendExpanded = false;

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  String _formatSelectedDate() {
    if (_selectedDate == null) return 'Select a Date';
    return '${_weekdays[_selectedDate!.weekday - 1]}, ${_months[_selectedDate!.month - 1]} ${_selectedDate!.day}';
  }

  // Cache of logs keyed by "yyyy-MM" string to avoid re-fetching
  final Map<String, Map<int, MockDailyLog>> _monthLogsCache = {};
  bool _isLoadingDbLogs = false;
  
  // Track whether we have loaded at least once, or if currently loading.
  // Instead of simple _isLoadingDbLogs, we separate cache states.
  bool _isFirstPageLoad = true;

  // Mock Database for April 2026
  late final Map<int, MockDailyLog> _aprilLogs;

  // Swipe page controller – start at page 1000 so we can go left/right freely
  late final PageController _pageController;
  static const int _initialPage = 1000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
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
    // Fetch logs from firestore post build phase and trigger prefetching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLogsForMonth(_focusedMonth).then((_) {
        setState(() {
          _isFirstPageLoad = false;
        });
      });
      _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month - 1));
      _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month + 1));
    });
  }

  String _monthKey(DateTime m) => "${m.year}-${m.month.toString().padLeft(2, '0')}";

  Future<void> _fetchLogsForMonth(DateTime targetMonth) async {
    final key = _monthKey(targetMonth);
    // If already loading or cached, skip double fetching
    if (_monthLogsCache.containsKey(key)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final daysInMonth = DateUtils.getDaysInMonth(targetMonth.year, targetMonth.month);
      final start = DateTime(targetMonth.year, targetMonth.month, 1);
      final end = DateTime(targetMonth.year, targetMonth.month, daysInMonth, 23, 59, 59);

      final dbLogs = await ref.read(firestoreServiceProvider).getDailyLogsHistory(user.uid, start, end);

      final Map<int, MockDailyLog> fetchedMap = {};
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
            hrtList.add({
              'id': intake.medicationId,
              'name': intake.name,
              'details': '${intake.dose.toStringAsFixed(0)} ${intake.unit}',
              'status': intake.isTaken ? 'Taken ${intake.time}' : 'Not taken',
              'isTaken': intake.isTaken.toString(),
            });
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

      setState(() {
        _monthLogsCache[key] = fetchedMap;
      });
    } catch (e) {
      debugPrint("Error fetching logs for $key: $e");
    }
  }

  // Legacy wrapper used by existing save calls
  Future<void> _fetchLogsForFocusedMonth() => _fetchLogsForMonth(_focusedMonth);

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


  Future<void> _saveLogToFirestore(int day, MockDailyLog mockLog) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    final dateStr = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

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
        return LoggedSymptom(
          symptom: Symptom(
            id: 's_${name.toLowerCase().replaceAll(' ', '_')}',
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
            id: 's_${name.toLowerCase().replaceAll(' ', '_')}',
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
        caffeineCups: 0,
        alcoholGlasses: 0,
        stressLevel: 'Moderate',
        foodsTriggered: false,
        foodsNotes: '',
        customTriggerCounters: {},
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
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    _fetchLogsForMonth(_focusedMonth);
    _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month - 1));
    _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month + 1));
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    _fetchLogsForMonth(_focusedMonth);
    _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month - 1));
    _fetchLogsForMonth(DateTime(_focusedMonth.year, _focusedMonth.month + 1));
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


  List<Map<String, String>> _convertToEditSymptoms(List<String> list) {
    return list.map((s) {
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
      return {
        'name': name,
        'severity': severity,
        'duration': '30',
      };
    }).toList();
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
    final triggerCatalog = {
      'Caffeine': {'icon': Icons.local_cafe, 'defaultValue': '1 cup'},
      'Stress': {'icon': Icons.psychology, 'defaultValue': 'Level: Moderate'},
      'Alcohol': {'icon': Icons.wine_bar, 'defaultValue': '1 glass'},
      'Red wine': {'icon': Icons.wine_bar, 'defaultValue': '1 glass'},
      'Exercise': {'icon': Icons.fitness_center, 'defaultValue': 'Logged'},
      'Weather': {'icon': Icons.cloud, 'defaultValue': 'Logged'},
      'Poor sleep': {'icon': Icons.bedtime, 'defaultValue': 'Logged'},
      'Poor Sleep': {'icon': Icons.bedtime, 'defaultValue': 'Logged'},
      'Specific Foods': {'icon': Icons.restaurant, 'defaultValue': 'Logged'},
    };

    return list.map((name) {
      final catalog = triggerCatalog[name] ?? {'icon': Icons.bolt, 'defaultValue': 'Logged'};
      return {
        'name': name,
        'value': catalog['defaultValue'],
        'icon': catalog['icon'],
      };
    }).toList();
  }

  List<String> _convertFromEditTriggers(List<Map<String, dynamic>> list) {
    return list.map((t) => t['name'] as String).toList();
  }

  void _showAddSymptomSheet(MockDailyLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SymptomLoggingSheet(
        loggedSymptoms: _convertToEditSymptoms(log.symptoms),
        onSave: (name, severity, duration) {
          setState(() {
            final editList = _convertToEditSymptoms(log.symptoms);
            final existingIndex = editList.indexWhere((s) => s['name'] == name);
            if (existingIndex != -1) {
              editList[existingIndex]['severity'] = severity;
              editList[existingIndex]['duration'] = duration.toString();
            } else {
              editList.add({
                'name': name,
                'severity': severity,
                'duration': duration.toString(),
              });
            }
            log.symptoms = _convertFromEditSymptoms(editList);
            log.itemsCount = log.symptoms.length + log.hrt.length + log.triggers.length;
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
        initialSymptoms: _convertToEditSymptoms(log.symptoms),
        onSave: (newSymptoms) {
          setState(() {
            log.symptoms = _convertFromEditSymptoms(newSymptoms);
            log.itemsCount = log.symptoms.length + log.hrt.length + log.triggers.length;
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
              editList.add({'name': name, 'value': value, 'icon': icon});
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
          onSave: (updated) {
            // Delete removed medications first
            final updatedIds = updated.map((e) => e['id']).where((id) => id != null).toSet();
            final medications = ref.read(medicationsProvider).medications;
            for (final med in medications) {
              if (!updatedIds.contains(med.id)) {
                ref.read(medicationsProvider.notifier).removeMedication(med.id);
              }
            }

            setState(() {
              log.hrt.clear();
              log.hrt.addAll(updated);
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
    final isCurrentMonthLoaded = _monthLogsCache.containsKey(_monthKey(_focusedMonth));

    return Container(
      color: AppTheme.background,
      child: SafeArea(
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
              const SizedBox(height: 24),
              _buildMonthNavigation(),
              const SizedBox(height: 16),
              _buildCalendarCard(),
              const SizedBox(height: 24),
              // Show skeleton while initial load or current month fetching, logged state otherwise
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: (!isCurrentMonthLoaded && _isFirstPageLoad)
                    ? _buildDayDetailSkeleton()
                    : (_selectedDate == null
                        ? _buildNoDaySelectedState()
                        : (activeLog == null
                            ? _buildUnloggedState()
                            : _buildLoggedDetailsState(activeLog))),
              ),
            ],
          ),
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
        GestureDetector(
          onTap: () {
            setState(() { _focusedMonth = prevMonth; });
            _fetchLogsForFocusedMonth();
          },
          child: Row(
            children: [
              const Icon(Icons.chevron_left, size: 20, color: AppTheme.primary),
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
        GestureDetector(
          onTap: _showMonthPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
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
        GestureDetector(
          onTap: () {
            setState(() { _focusedMonth = nextMonth; });
            _fetchLogsForFocusedMonth();
          },
          child: Row(
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
              const Icon(Icons.chevron_right, size: 20, color: AppTheme.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    final isApril = _focusedMonth.year == 2026 && _focusedMonth.month == 4;
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0) {
            // Swiped Left: Go to next month
            _nextMonth();
          } else if (details.primaryVelocity! > 0) {
            // Swiped Right: Go to previous month
            _previousMonth();
          }
        }
      },
      child: Container(
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
            _buildDaysGrid(isApril),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysGrid(bool isApril) {
    final totalDays = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    
    // weekday is 1 (Monday) to 7 (Sunday)
    final startWeekday = firstDayOfMonth.weekday;
    final prefixDaysCount = startWeekday - 1; // days to show from previous month
    
    final List<Widget> dayWidgets = [];
    
    // Previous month overflow days
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    final prevMonthTotalDays = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    for (int i = prefixDaysCount - 1; i >= 0; i--) {
      final dayNum = prevMonthTotalDays - i;
      dayWidgets.add(_buildOverflowDay('$dayNum'));
    }
    
    // Current month days
    final cachedLogsForMonth = _monthLogsCache[_monthKey(_focusedMonth)] ?? {};
    for (int day = 1; day <= totalDays; day++) {
      MockDailyLog? logForDay = cachedLogsForMonth[day];
      if (logForDay == null && isApril) {
        logForDay = _aprilLogs[day];
      }
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == _focusedMonth.year &&
          _selectedDate!.month == _focusedMonth.month &&
          _selectedDate!.day == day;
      final hasData = logForDay != null;
      
      Color? backgroundIntensity;
      if (hasData && logForDay != null) {
        if (logForDay.symptoms.isNotEmpty) {
          final firstSymptom = logForDay.symptoms.first.toLowerCase();
          if (firstSymptom.contains('severe') || firstSymptom.contains('5/5') || firstSymptom.contains('4/5')) {
            backgroundIntensity = const Color(0xFFF9B7A9).withValues(alpha: 0.6); // Reddish orange for severe
          } else {
            backgroundIntensity = const Color(0xFFEDDDF5).withValues(alpha: 0.6); // Purple for general logs
          }
        } else {
          backgroundIntensity = const Color(0xFFEDDDF5).withValues(alpha: 0.4);
        }
      }
      
      dayWidgets.add(
        _buildCalendarDay(
          day: day,
          isSelected: isSelected,
          hasData: hasData,
          backgroundColor: backgroundIntensity,
          onTap: () => setState(() => _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, day)),
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
    return Column(
      children: List.generate(rowsCount, (rowIndex) {
        final start = rowIndex * 7;
        final end = start + 7;
        final rowWidgets = dayWidgets.sublist(start, end);
        return Row(
          children: rowWidgets.map((w) => Expanded(child: AspectRatio(aspectRatio: 1, child: w))).toList(),
        );
      }),
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
    required VoidCallback onTap,
  }) {
    if (isSelected) {
      if (hasData) {
        // Today Selected (Solid circle)
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
        // Unlogged day selected (Outline circle + Ring shadow)
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

    // Default unselected days
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: hasData ? FontWeight.bold : FontWeight.w400,
                  color: hasData ? AppTheme.onSurface : const Color(0xFFB0A89E),
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
                    Text(
                      'No data recorded for this day.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
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
                              _fetchLogsForFocusedMonth();
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
                              'LOG RETROACTIVELY',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
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
        _buildWeeklyTrendsCard(),
        const SizedBox(height: 24),
        _buildInsightsBanner(),
        const SizedBox(height: 16),
        _buildLegendAccordion(),
      ],
    );
  }

  Widget _buildWeeklyTrendsCard() {
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
          Text(
            'Weekly Trends',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendRow(
            title: 'Symptom Intensity',
            value: 'Avg 4.2',
            change: '↓ 12%',
            isGood: true,
            sparklineHeights: [0.4, 0.6, 0.8, 0.3, 0.5, 0.45, 0.0],
          ),
          const Divider(height: 24, color: Color(0xFFF2EDEA)),
          _buildTrendRow(
            title: 'Sleep Quality',
            value: '6.5 hrs',
            change: '↓ 4%',
            isGood: false,
            sparklineHeights: [0.7, 0.65, 0.9, 0.55, 0.6, 0.4, 0.0],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendRow({
    required String title,
    required String value,
    required String change,
    required bool isGood,
    required List<double> sparklineHeights,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    change,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isGood ? Colors.green[600] : Colors.red[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildSparkline(sparklineHeights),
        ],
      ),
    );
  }

  Widget _buildSparkline(List<double> heights) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(heights.length, (index) {
          final h = heights[index];
          // Sparkline highlights active column (index 5)
          final isHighlighted = index == 5;
          return Container(
            width: 4,
            height: 24 * h,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: h == 0
                  ? Colors.transparent
                  : (isHighlighted ? AppTheme.primary : const Color(0xFFD0C1D8)),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInsightsBanner() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: const BorderSide(color: AppTheme.tertiaryFixed, width: 4),
          top: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
          right: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
          bottom: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_alt,
                color: Color(0xFF814F45),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Personalized Insights',
                style: GoogleFonts.notoSerif(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your hot flashes correlate with caffeine intake recorded 4 hours prior. Consider switching to herbal tea after 12 PM.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE7E1DF)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actionable takeaway',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.outline,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Text('LEARN MORE'),
                label: const Icon(Icons.open_in_new, size: 14),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF814F45),
                  padding: EdgeInsets.zero,
                  textStyle: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
          InkWell(
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

  Map<String, Color> _getTriggerColorsForDisplay(String name) {
    Color bg;
    Color border;
    Color text;

    switch (name.toLowerCase()) {
      case 'stress':
        bg = const Color(0xFFF3E8FF);
        border = const Color(0xFFE9D5FF);
        text = const Color(0xFF7E22CE);
        break;
      case 'caffeine':
        bg = const Color(0xFFFDF8F5);
        border = const Color(0xFFEDD8CE);
        text = const Color(0xFF854D0E);
        break;
      case 'alcohol':
      case 'red wine':
        bg = const Color(0xFFFFF1F2);
        border = const Color(0xFFFECDD3);
        text = const Color(0xFFBE123C);
        break;
      case 'sugar':
      case 'sugar & sweets':
        bg = const Color(0xFFF7FEE7);
        border = const Color(0xFFE2F9B8);
        text = const Color(0xFF4D7C0F);
        break;
      case 'lack of sleep':
      case 'poor sleep':
        bg = const Color(0xFFF0F9FF);
        border = const Color(0xFFBAE6FD);
        text = const Color(0xFF0369A1);
        break;
      case 'spicy food':
      case 'foods':
        bg = const Color(0xFFFFF1F0);
        border = const Color(0xFFFFCCC7);
        text = const Color(0xFFCF1322);
        break;
      default:
        bg = const Color(0xFFF0FDFA);
        border = const Color(0xFFCCFBF1);
        text = const Color(0xFF0F766E);
        break;
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
              InkWell(
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
              InkWell(
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
              InkWell(
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
