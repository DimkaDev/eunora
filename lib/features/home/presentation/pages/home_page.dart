import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/home/presentation/widgets/dashboard_header.dart';
import 'package:eunora/features/home/presentation/widgets/insight_card.dart';
import 'package:eunora/features/home/presentation/widgets/weekly_patterns_card.dart';
import 'package:eunora/features/home/presentation/widgets/insight_teaser_card.dart';
import 'package:eunora/features/home/presentation/widgets/passport_dashboard_card.dart';
import 'package:eunora/features/home/presentation/widgets/daily_log_card.dart';
import 'package:eunora/features/home/presentation/widgets/medication_hrt_card.dart';
import 'package:eunora/features/home/presentation/widgets/today_symptoms_card.dart';
import 'package:eunora/features/home/presentation/widgets/daily_triggers_card.dart';
import 'package:eunora/features/home/presentation/widgets/symptom_logging_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/trigger_logging_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/edit_symptoms_modal_sheet.dart';
import 'package:eunora/features/home/presentation/widgets/edit_triggers_modal_sheet.dart';
import 'package:eunora/features/home/presentation/pages/calendar_page.dart';
import 'package:eunora/features/home/presentation/pages/analytics_page.dart';
import 'package:eunora/features/home/presentation/pages/passport_page.dart';
import 'package:eunora/features/home/presentation/pages/hrt_tracker_page.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/core/utils/logging_helpers.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/home/presentation/widgets/calendar_hrt_edit_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';
import 'package:eunora/core/services/premium_guard_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/triggers_provider.dart';
import 'package:eunora/features/onboarding/domain/models/trigger.dart';
import 'package:eunora/features/symptom_log/data/trigger_library.dart';



import 'package:eunora/features/home/presentation/widgets/home/premium_toggle_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;
  late final InsightType _insightType;
  bool _isLoading = true;
  int _loggedDaysCountThisWeek = 0;

  // Daily Logging States
  bool _isLogCompleted = false;
  int _todayDraftStep = 0;
  final Map<String, bool> _takenStatus = {};
  final Map<String, String> _takenTime = {};
  final List<Map<String, String>> _loggedSymptoms = [];
  final List<Map<String, dynamic>> _loggedTriggers = [];

  @override
  void initState() {
    super.initState();
    // Choose a random InsightType once during load/initialization
    const types = InsightType.values;
    _insightType = types[Random().nextInt(types.length)];

    // Initialize with standard logs for default mock medications
    _takenStatus['Estradiol Patch'] = false;
    _takenTime['Estradiol Patch'] = '08:30';
    _takenStatus['Progesterone'] = false;
    _takenTime['Progesterone'] = '21:00';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTodayLog();
    });
  }

  Future<void> _fetchTodayLog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final date = DateTime.now();
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      // Query log count for the last 7 days to evaluate if we have enough data for insights
      final start = date.subtract(const Duration(days: 7));
      final logsThisWeek = await ref.read(firestoreServiceProvider).getDailyLogsHistory(user.uid, start, date);
      
      final log = await ref.read(firestoreServiceProvider).getDailyLog(user.uid, dateStr);
      if (mounted) {
        setState(() {
          _loggedDaysCountThisWeek = logsThisWeek.where((l) => l.isCompleted).length;
        });
      }

      if (log != null && mounted) {
        setState(() {
          _isLogCompleted = log.isCompleted;
          _todayDraftStep = log.isCompleted ? 5 : log.lastCompletedStep;

          // Only populate home page cards with data from COMPLETED logs.
          // Draft/incomplete logs should NOT leak data into symptoms, triggers, or HRT cards.
          if (log.isCompleted) {
            _loggedSymptoms.clear();
            for (final s in log.symptoms) {
              _loggedSymptoms.add({
                'name': s.symptom.name,
                'severity': s.severity ?? 'Moderate',
              });
            }

            _loggedTriggers.clear();
            for (final t in log.triggers) {
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

              _loggedTriggers.add({
                'name': parsed.label,
                'value': parsed.value ?? 'Logged',
                'icon': trigger.getIconData(),
              });
            }

            _takenStatus['Estradiol Patch'] = log.estradiolChecked;
            _takenStatus['Estradiol'] = log.estradiolChecked;
            _takenTime['Estradiol Patch'] = log.estradiolTime.isEmpty ? '08:30' : log.estradiolTime;
            _takenStatus['Progesterone'] = log.progesteroneChecked;
            _takenStatus['Utrogestan'] = log.progesteroneChecked;
            _takenTime['Progesterone'] = log.progesteroneTime.isEmpty ? '21:00' : log.progesteroneTime;

            for (final intake in log.hrtIntakes) {
              _takenStatus[intake.name] = intake.isTaken;
              _takenTime[intake.name] = intake.time;
            }
          } else {
            // Draft exists but is not completed — clear displayed data
            _loggedSymptoms.clear();
            _loggedTriggers.clear();
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isLogCompleted = false;
            _todayDraftStep = 0;
            _loggedSymptoms.clear();
            _loggedTriggers.clear();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching daily log: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTodayLogToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final date = DateTime.now();
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final List<LoggedSymptom> symptomsList = _loggedSymptoms.map((s) {
      final name = s['name'] ?? '';
      final severity = s['severity'] ?? 'Moderate';
      final id = sanitizeSymptomId('s_${name.toLowerCase().replaceAll(' ', '_')}');
      return LoggedSymptom(
        symptom: Symptom(
          id: id,
          name: name,
          iconName: 'medical_services',
          category: 'General',
        ),
        severity: severity,
      );
    }).toList();

    final List<String> triggerNames = _loggedTriggers.map<String>((t) {
      final name = t['name'] ?? '';
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

    int caffeineCups = 0;
    int alcoholGlasses = 0;
    String stressLevel = 'Moderate';
    bool foodsTriggered = false;
    String foodsNotes = '';
    final Map<String, int> customTriggerCounters = {};
    final Map<String, String> customTriggerTexts = {};

    for (final t in _loggedTriggers) {
      final name = t['name'] ?? '';
      final val = (t['value'] ?? 'Logged').toString();
      final fullStr = val != 'Logged' ? '$name: $val' : name;
      final parsed = parseTriggerString(fullStr);
      final prefixId = 't_${parsed.id}';

      if (parsed.id == 'coffee' || parsed.id == 'caffeine') {
        caffeineCups = int.tryParse(parsed.value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
      } else if (parsed.id == 'alcohol') {
        alcoholGlasses = int.tryParse(parsed.value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
      } else if (parsed.id == 'stress') {
        stressLevel = parsed.value ?? 'Moderate';
      } else if (parsed.id == 'foods') {
        foodsTriggered = true;
        foodsNotes = parsed.value ?? '';
      } else {
        if (parsed.value != null) {
          final counterVal = int.tryParse(parsed.value!.replaceAll(RegExp(r'[^0-9]'), ''));
          if (counterVal != null && parsed.value!.contains('times')) {
            customTriggerCounters[prefixId] = counterVal;
            customTriggerCounters[parsed.id] = counterVal;
          } else {
            customTriggerTexts[prefixId] = parsed.value!;
            customTriggerTexts[parsed.id] = parsed.value!;
          }
        }
      }
    }

    final estradiolChecked = _takenStatus['Estradiol Patch'] ?? _takenStatus['Estradiol'] ?? false;
    final progesteroneChecked = _takenStatus['Progesterone'] ?? _takenStatus['Utrogestan'] ?? false;

    final meds = ref.read(medicationsProvider).medications;
    double estradiolDose = 50.0;
    String estradiolUnit = 'mcg';
    double progesteroneDose = 100.0;
    String progesteroneUnit = 'mg';

    final List<HrtIntakeLog> hrtIntakes = [];
    for (final med in meds) {
      final name = med.name.toLowerCase();
      final isTaken = _takenStatus[med.name] ?? false;
      final time = _takenTime[med.name] ?? (name.contains('estradiol') ? '08:30' : '21:00');

      if (name.contains('estradiol') || name.contains('estrogen') || name.contains('estradot')) {
        estradiolDose = med.dose;
        estradiolUnit = med.unit;
        hrtIntakes.add(HrtIntakeLog(
          medicationId: med.id,
          name: med.name,
          dose: med.dose,
          unit: med.unit,
          time: time,
          isTaken: isTaken,
        ));
      } else if (name.contains('progesterone') || name.contains('utrogestan')) {
        progesteroneDose = med.dose;
        progesteroneUnit = med.unit;
        hrtIntakes.add(HrtIntakeLog(
          medicationId: med.id,
          name: med.name,
          dose: med.dose,
          unit: med.unit,
          time: time,
          isTaken: isTaken,
        ));
      } else {
        hrtIntakes.add(HrtIntakeLog(
          medicationId: med.id,
          name: med.name,
          dose: med.dose,
          unit: med.unit,
          time: time,
          isTaken: isTaken,
        ));
      }
    }

    if (hrtIntakes.isEmpty) {
      if (estradiolChecked) {
        hrtIntakes.add(HrtIntakeLog(
          medicationId: 'estradiol_default',
          name: 'Estradiol',
          dose: estradiolDose,
          unit: estradiolUnit,
          time: '08:30',
          isTaken: true,
        ));
      }
      if (progesteroneChecked) {
        hrtIntakes.add(HrtIntakeLog(
          medicationId: 'progesterone_default',
          name: 'Progesterone',
          dose: progesteroneDose,
          unit: progesteroneUnit,
          time: '21:00',
          isTaken: true,
        ));
      }
    }

    final dailyLog = DailyLog(
      id: dateStr,
      userId: user.uid,
      date: date,
      symptoms: symptomsList,
      triggers: triggerNames,
      caffeineCups: caffeineCups,
      alcoholGlasses: alcoholGlasses,
      stressLevel: stressLevel,
      foodsTriggered: foodsTriggered,
      foodsNotes: foodsNotes,
      estradiolChecked: estradiolChecked,
      estradiolDose: estradiolDose,
      estradiolUnit: estradiolUnit,
      estradiolTime: _takenTime['Estradiol Patch'] ?? '08:30',
      progesteroneChecked: progesteroneChecked,
      progesteroneDose: progesteroneDose,
      progesteroneUnit: progesteroneUnit,
      progesteroneTime: _takenTime['Progesterone'] ?? '21:00',
      customTriggerCounters: customTriggerCounters,
      customTriggerTexts: customTriggerTexts,
      hrtIntakes: hrtIntakes,
      isCompleted: true,
      lastCompletedStep: 5,
      createdAt: DateTime.now(),
    );

    await ref.read(firestoreServiceProvider).saveDailyLog(user.uid, dailyLog);
  }


  double _getLoggingProgress(List<Medication> medications) {
    double progress = 0.0;

    // Check mandatory medications (daily or bedtime)
    final mandatoryMeds = medications.where((med) {
      final freq = med.frequency.toLowerCase();
      return freq.contains('daily') || freq.contains('bedtime');
    }).toList();

    if (mandatoryMeds.isEmpty) {
      progress += 0.4;
    } else {
      int takenCount = 0;
      for (final med in mandatoryMeds) {
        if (_takenStatus[med.name] ?? false) {
          takenCount++;
        }
      }
      progress += (0.4 * takenCount) / mandatoryMeds.length;
    }

    if (_loggedSymptoms.isNotEmpty) progress += 0.3;
    if (_loggedTriggers.isNotEmpty) progress += 0.3;
    return progress;
  }

  void _showAddSymptomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SymptomLoggingSheet(
        loggedSymptoms: _loggedSymptoms,
        onSave: (name, severity, duration) {
          setState(() {
            final existingIndex = _loggedSymptoms.indexWhere((s) => s['name'] == name);
            if (existingIndex != -1) {
              _loggedSymptoms[existingIndex]['severity'] = severity;
              _loggedSymptoms[existingIndex]['duration'] = duration.toString();
            } else {
              _loggedSymptoms.add({
                'name': name,
                'severity': severity,
                'duration': duration.toString(),
              });
            }
          });
          _saveTodayLogToFirestore();
        },
      ),
    );
  }

  void _showAddTriggerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TriggerLoggingSheet(
        loggedTriggers: _loggedTriggers,
        onSave: (name, value, icon) {
          setState(() {
            final existingIndex = _loggedTriggers.indexWhere((t) => t['name'] == name);
            if (existingIndex != -1) {
              _loggedTriggers[existingIndex]['value'] = value;
            } else {
              _loggedTriggers.add({'name': name, 'value': value, 'icon': icon});
            }
          });
          _saveTodayLogToFirestore();
        },
      ),
    );
  }

  void _showEditSymptomsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSymptomsModalSheet(
        initialSymptoms: _loggedSymptoms,
        onSave: (newSymptoms) {
          setState(() {
            _loggedSymptoms.clear();
            _loggedSymptoms.addAll(newSymptoms);
          });
          _saveTodayLogToFirestore();
        },
      ),
    );
  }

  void _showEditTriggersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTriggersModalSheet(
        initialTriggers: _loggedTriggers,
        onSave: (newTriggers) {
          setState(() {
            _loggedTriggers.clear();
            _loggedTriggers.addAll(newTriggers);
          });
          _saveTodayLogToFirestore();
        },
      ),
    );
  }


  void _showHrtLoggingSheet(List<Medication> medications) {
    final hrtList = medications.map((med) {
      final isTaken = _takenStatus[med.name] ?? false;
      final time = _takenTime[med.name] ?? '08:00';
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
          onSave: (updatedList) {
            setState(() {
              // 1. Identify and delete medications deleted in the modal list
              final updatedIds = updatedList.map((e) => e['id']).where((id) => id != null).toSet();
              for (final med in medications) {
                if (!updatedIds.contains(med.id)) {
                  ref.read(medicationsProvider.notifier).removeMedication(med.id);
                  _takenStatus.remove(med.name);
                  _takenTime.remove(med.name);
                }
              }

              // 2. Update status and time for remaining medications
              for (final updated in updatedList) {
                final name = updated['name'] ?? '';
                final isTaken = updated['isTaken'] == 'true';
                final status = updated['status'] ?? '';
                
                String time = '08:00';
                final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(status);
                if (match != null) {
                  time = match.group(1) ?? '08:00';
                }

                _takenStatus[name] = isTaken;
                _takenTime[name] = time;
              }
            });
            _saveTodayLogToFirestore();
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
          },
        ),
      ),
    );
  }

  void _handleStartOrResumeLogging() async {
    final result = await context.push<Map<String, dynamic>>('/daily-logging');
    if (result != null) {
      setState(() {
        _loggedSymptoms.clear();
        if (result['symptoms'] != null) {
          _loggedSymptoms.addAll(
            (result['symptoms'] as List).map((e) => Map<String, String>.from(e as Map)),
          );
        }
        _loggedTriggers.clear();
        if (result['triggers'] != null) {
          _loggedTriggers.addAll(
            (result['triggers'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
        final est = result['estradiolTaken'] as bool? ?? false;
        final prog = result['progesteroneTaken'] as bool? ?? false;
        _takenStatus['Estradiol Patch'] = est;
        _takenStatus['Estradiol'] = est;
        _takenStatus['Progesterone'] = prog;
        _takenStatus['Utrogestan'] = prog;
      });
    }
    await _fetchTodayLog();
  }

  Widget _buildHomeDashboard(double progress, List<Medication> medications) {
    final userProfile = ref.watch(onboardingProfileProvider);
    
    final firebaseUser = FirebaseAuth.instance.currentUser;
    String userName = 'Sarah';
    if (userProfile != null && userProfile.email.isNotEmpty) {
      final emailName = userProfile.email.split('@').first;
      if (emailName.isNotEmpty) {
        userName = emailName[0].toUpperCase() + emailName.substring(1);
      }
    } else if (firebaseUser != null && firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
      final emailName = firebaseUser.email!.split('@').first;
      if (emailName.isNotEmpty) {
        userName = emailName[0].toUpperCase() + emailName.substring(1);
      }
    }

    final date = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdayStr = weekdays[date.weekday - 1];
    final monthStr = months[date.month - 1];
    final dateString = '$weekdayStr, $monthStr ${date.day}';

    String cycleInfo = '1 week in cycle';
    if (userProfile != null) {
      switch (userProfile.menopauseStage) {
        case MenopauseStage.irregular:
          cycleInfo = 'Irregular Cycle';
          break;
        case MenopauseStage.noPeriod12Months:
          cycleInfo = 'No Period > 12 Mos';
          break;
        case MenopauseStage.postmenopause:
          cycleInfo = 'Postmenopause';
          break;
        case MenopauseStage.surgical:
          cycleInfo = 'Surgical Menopause';
          break;
        case MenopauseStage.pcos:
          cycleInfo = 'PCOS';
          break;
      }
    }

    return Column(
      children: [
        DashboardHeader(
          userName: userName,
          date: dateString,
          cycleInfo: cycleInfo,
          profileImageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCcyvRmigFQWEnghTEoPCUvu6Lls83qWwGf81JXXAHmxs_PI1albuWzfyX8hJHYDK2oDWVWOWPMCqACZzrOSiUrEriDUDMizBdlzmoikkKEMsviNymTb1SmeDL2M5mjpE7ZBB0lVSTa1Di99-xd5i_L5XTTvhH9uNbS-BEM4dPF7EevWWNXW_jzlWxSVjPjBZ3OPwiDpUtKeUmcOYd5ry2dtceFPJ-WL6Bp-ZEtlShywIcbEgix84xxFqoBGr1QXN6ehV00Hjb-W4c',
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  child: Column(
                    children: [
                      // 🔧 DEV TOOL: Premium toggle
                      PremiumToggleWidget(
                        isPremium: ref.watch(premiumGuardProvider),
                        onTap: () {
                          final isPremium = ref.read(premiumGuardProvider);
                          ref.read(premiumGuardProvider.notifier).state = !isPremium;
                        },
                      ),
                      const SizedBox(height: 12),
                      FadeInEntrance(
                        delay: Duration.zero,
                        child: DailyLogCard(
                          progress: progress,
                          onStartLog: _handleStartOrResumeLogging,
                        ),
                      ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 30),
                  child: MedicationHrtCard(
                    medications: medications,
                    takenStatus: _takenStatus,
                    takenTime: _takenTime,
                    onTakenStatusChanged: (newStatus) {
                      setState(() {
                        _takenStatus.clear();
                        _takenStatus.addAll(newStatus);
                      });
                      _saveTodayLogToFirestore();
                    },
                    onManageTap: () => _showHrtLoggingSheet(medications),
                  ),
                ),

                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 60),
                  child: TodaySymptomsCard(
                    loggedSymptoms: _loggedSymptoms,
                    onAddSymptom: _showAddSymptomSheet,
                    onEditSymptom: _showEditSymptomsSheet,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 90),
                  child: DailyTriggersCard(
                    loggedTriggers: _loggedTriggers,
                    onAddTrigger: _showAddTriggerSheet,
                    onEditTrigger: _showEditTriggersSheet,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 120),
                  child: InsightCard(
                    type: _insightType,
                    isInsufficientData: _loggedDaysCountThisWeek < 3,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 150),
                  child: PassportDashboardCard(
                    onGeneratePassport: () => setState(() => _selectedIndex = 3),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 180),
                  child: const InsightTeaserCard(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedTab(double progress, List<Medication> medications) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeDashboard(progress, medications);
      case 1:
        return const CalendarPage();
      case 2:
        return const AnalyticsPage();
      case 3:
        return const PassportPage();
      case 4:
        return const HrtTrackerPage();
      default:
        return _buildHomeDashboard(progress, medications);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicationsState = ref.watch(medicationsProvider);
    final medications = medicationsState.medications.where((m) => m.endedAt == null).toList();

    // Auto-populate default medications if completely empty
    if (medications.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(medicationsProvider).medications.isEmpty) {
          final refNotifier = ref.read(medicationsProvider.notifier);
          refNotifier.addMedication(Medication(
            name: 'Estradiol Patch',
            type: MedicationType.patch,
            dose: 50,
            unit: 'mcg',
            frequency: 'Twice weekly',
          ));
          refNotifier.addMedication(Medication(
            name: 'Progesterone',
            type: MedicationType.pill,
            dose: 100,
            unit: 'mg',
            frequency: 'Bedtime',
          ));
        }
      });
    }

    final double progress;
    if (_isLogCompleted) {
      progress = 1.0;
    } else if (_todayDraftStep > 0) {
      progress = (_todayDraftStep / 5.0).clamp(0.1, 0.99);
    } else {
      progress = _getLoggingProgress(medications);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: _buildSelectedTab(progress, medications),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavBar(),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0).withOpacity(0.9),
        border: const Border(top: BorderSide(color: Color(0xFFE7E5E4))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home, 'Home'),
          _buildNavItem(1, Icons.edit_calendar, 'Tracker'),
          _buildNavItem(2, Icons.insights, 'Analytics'),
          _buildNavItem(3, Icons.assignment_ind, 'Passport'),
          _buildNavItem(4, Icons.medication_liquid, 'HRT'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Bounceable(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 0) {
          _fetchTodayLog();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : const Color(0xFFA8A29E),
              size: 24,
              shadows: isSelected ? [const Shadow(color: AppTheme.primary, blurRadius: 2)] : null,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: isSelected ? AppTheme.primary : const Color(0xFFA8A29E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

