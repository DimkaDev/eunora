import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:eunora/core/utils/animation_system.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptoms_provider.dart';
import 'package:eunora/features/onboarding/domain/models/trigger.dart';
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/triggers_provider.dart';

import 'package:eunora/features/onboarding/presentation/providers/onboarding_profile_provider.dart';
import 'package:eunora/features/onboarding/presentation/providers/other_medications_provider.dart';
import 'package:eunora/core/utils/logging_helpers.dart';

import 'package:eunora/features/home/presentation/pages/daily_logging/symptoms_step.dart';
import 'package:eunora/features/home/presentation/pages/daily_logging/severity_step.dart';
import 'package:eunora/features/home/presentation/pages/daily_logging/triggers_step.dart';
import 'package:eunora/features/home/presentation/pages/daily_logging/trigger_details_step.dart';
import 'package:eunora/features/home/presentation/pages/daily_logging/daily_entry_step.dart';
import 'package:eunora/features/home/presentation/widgets/dose_change_alert.dart';
import 'package:eunora/features/onboarding/presentation/providers/symptom_quick_access_provider.dart';
import 'package:eunora/features/home/presentation/widgets/success_animation_widget.dart';

import 'package:eunora/features/home/presentation/widgets/daily_logging/daily_logging_success_screen.dart';

class DailyLoggingPage extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  const DailyLoggingPage({super.key, this.initialDate});

  @override
  ConsumerState<DailyLoggingPage> createState() => _DailyLoggingPageState();
}

class _DailyLoggingPageState extends ConsumerState<DailyLoggingPage> {
  int _currentStep = 0; // 0 to 5 (Step 1 to Step 6)
  int _maxStepReached = 0; // Highest step reached during logging session

  // Step 1: Symptoms Selection
  final Set<String> _selectedSymptomIds = {};
  final List<String> _customSymptoms = [];

  // Step 2: Symptom Severities & Durations
  final Map<String, String> _symptomSeverities = {};
  final Map<String, int> _symptomDurations = {};

  // Step 3: Trigger Selection
  final Set<String> _selectedTriggerIds = {};
  final List<String> _customTriggers = [];

  // Step 4: Trigger Details
  int _caffeineCups = 2;
  int _alcoholGlasses = 1;
  String _stressLevel = 'Moderate'; // Calm, Moderate, High
  bool _foodsTriggered = true;
  String _foodsNotes = 'Spicy food in evening';
  final Map<String, int> _customTriggerCounters = {};
  final Map<String, String> _customTriggerTexts = {};

  // Step 5: Medications & Supplements (Fully dynamic maps keyed by medication ID)
  final Map<String, bool> _hrtChecked = {};
  final Map<String, double> _hrtDoses = {};
  final Map<String, String> _hrtUnits = {};
  final Map<String, String> _hrtTimes = {};
  final Map<String, double> _initialHrtDoses = {};
  final Map<String, String> _initialHrtUnits = {};

  bool _vitaminDChecked = false;
  bool _magnesiumChecked = false;

  double _sleepDuration = 7.5;
  int _hydrationCups = 4;
  String _additionalNotes = '';
  final Map<String, bool> _otherMedsChecked = {};

  bool _isMedsInitialized = false;
  bool _isSymptomsInitialized = false;
  /// True after _loadExistingLog successfully populated state from Firestore.
  /// Prevents reactive listeners from overwriting the loaded selection.
  bool _existingLogLoaded = false;
  bool _isLoadingLog = true;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep);
    _loadExistingLog();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingLog = false;
        });
      }
      return;
    }

    final date = widget.initialDate ?? DateTime.now();
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      final existingLog = await ref.read(firestoreServiceProvider).getDailyLog(user.uid, dateStr);
      if (existingLog != null && mounted) {
        setState(() {
          _isMedsInitialized = true;
          _isSymptomsInitialized = true;
          _existingLogLoaded = true;

          // Populate symptoms
          _selectedSymptomIds.clear();
          for (final s in existingLog.symptoms) {
            final sanitizedId = sanitizeSymptomId(s.symptom.id);
            _selectedSymptomIds.add(sanitizedId);
            _symptomSeverities[sanitizedId] = s.severity ?? 'Mild';
            if (s.durationMinutes != null) {
              _symptomDurations[sanitizedId] = s.durationMinutes!;
            }
          }

          // Populate triggers
          _selectedTriggerIds.clear();
          for (final t in existingLog.triggers) {
            final parsed = parseTriggerString(t);
            final prefixId = 't_${parsed.id}';
            _selectedTriggerIds.add(prefixId);

            if (parsed.id == 'coffee' || parsed.id == 'caffeine') {
              if (parsed.value != null) {
                _caffeineCups = int.tryParse(parsed.value!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
              }
            } else if (parsed.id == 'alcohol') {
              if (parsed.value != null) {
                _alcoholGlasses = int.tryParse(parsed.value!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
              }
            } else if (parsed.id == 'stress') {
              if (parsed.value != null) {
                _stressLevel = parsed.value!;
              }
            } else {
              // Custom trigger text or counter
              if (parsed.value != null) {
                final counterVal = int.tryParse(parsed.value!.replaceAll(RegExp(r'[^0-9]'), ''));
                if (counterVal != null && parsed.value!.contains('times')) {
                  _customTriggerCounters[prefixId] = counterVal;
                  _customTriggerCounters[parsed.id] = counterVal;
                } else {
                  _customTriggerTexts[prefixId] = parsed.value!;
                  _customTriggerTexts[parsed.id] = parsed.value!;
                }
              }
            }
          }

          _caffeineCups = existingLog.caffeineCups;
          _alcoholGlasses = existingLog.alcoholGlasses;
          _stressLevel = existingLog.stressLevel;
          _foodsTriggered = existingLog.foodsTriggered;
          _foodsNotes = existingLog.foodsNotes ?? '';
          _customTriggerCounters.clear();
          _customTriggerCounters.addAll(existingLog.customTriggerCounters ?? {});
          _customTriggerTexts.clear();
          _customTriggerTexts.addAll(existingLog.customTriggerTexts ?? {});

          // Populate medications
          if (existingLog.hrtIntakes.isNotEmpty) {
            for (final intake in existingLog.hrtIntakes) {
              _hrtChecked[intake.medicationId] = intake.isTaken;
              _hrtDoses[intake.medicationId] = intake.dose;
              _hrtUnits[intake.medicationId] = intake.unit;
              _hrtTimes[intake.medicationId] = intake.time;
              _initialHrtDoses[intake.medicationId] = intake.dose;
              _initialHrtUnits[intake.medicationId] = intake.unit;
            }
          } else {
            // Backwards compatibility fallback from flat fields
            final meds = ref.read(medicationsProvider).medications;
            for (final med in meds) {
              final name = med.name.toLowerCase();
              if (name.contains('estradiol') || name.contains('estrogen') || name.contains('estradot')) {
                _hrtChecked[med.id] = existingLog.estradiolChecked;
                _hrtDoses[med.id] = existingLog.estradiolDose;
                _hrtUnits[med.id] = existingLog.estradiolUnit;
                _hrtTimes[med.id] = existingLog.estradiolTime;
                _initialHrtDoses[med.id] = existingLog.estradiolDose;
                _initialHrtUnits[med.id] = existingLog.estradiolUnit;
              } else if (name.contains('progesterone') || name.contains('utrogestan')) {
                _hrtChecked[med.id] = existingLog.progesteroneChecked;
                _hrtDoses[med.id] = existingLog.progesteroneDose;
                _hrtUnits[med.id] = existingLog.progesteroneUnit;
                _hrtTimes[med.id] = existingLog.progesteroneTime;
                _initialHrtDoses[med.id] = existingLog.progesteroneDose;
                _initialHrtUnits[med.id] = existingLog.progesteroneUnit;
              }
            }
          }

          _vitaminDChecked = existingLog.vitaminDChecked;
          _magnesiumChecked = existingLog.magnesiumChecked;
          _sleepDuration = existingLog.sleepDuration;
          _hydrationCups = existingLog.hydrationCups;

          // Parse other medications from additional notes
          _otherMedsChecked.clear();
          if (existingLog.additionalNotes.contains('Supplements taken today:')) {
            final parts = existingLog.additionalNotes.split('Supplements taken today:');
            _additionalNotes = parts[0].trim();
            final medsPart = parts[1].trim();
            final list = medsPart.split(',').map((e) => e.trim());
            final otherMeds = ref.read(otherMedicationsProvider).medications;
            for (final med in otherMeds) {
              if (list.any((element) => element.contains(med.name))) {
                _otherMedsChecked[med.id] = true;
              }
            }
          _additionalNotes = existingLog.additionalNotes;
          }
          // Cache the original database log so we can restore it if the user cancels
          _originalLog = existingLog;

          // If the log is incomplete/draft, set current step to the last completed step
          if (!existingLog.isCompleted && existingLog.lastCompletedStep > 0 && existingLog.lastCompletedStep <= 5) {
            _currentStep = existingLog.lastCompletedStep;
            _maxStepReached = existingLog.lastCompletedStep;
            _pageController.dispose();
            _pageController = PageController(initialPage: _currentStep);
          }
        });
      } else {
        _originalLog = null;
      }
    } catch (e) {
      debugPrint("Error loading existing daily log: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLog = false;
        });
      }
    }
  }

  // To support restoring on cancel/pop without saving
  DailyLog? _originalLog;

  DailyLog _buildDailyLog({bool isCompleted = false, int? lastCompletedStep}) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final date = widget.initialDate ?? DateTime.now();
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final List<HrtIntakeLog> hrtIntakes = [];
    final meds = ref.read(medicationsProvider).medications;
    
    bool estradiolChecked = false;
    double estradiolDose = 50.0;
    String estradiolUnit = 'mcg';
    String estradiolTime = '08:30 AM';
    bool progesteroneChecked = false;
    double progesteroneDose = 100.0;
    String progesteroneUnit = 'mg';
    String progesteroneTime = '08:00 PM';

    for (final med in meds) {
      final checked = _hrtChecked[med.id] ?? false;
      final dose = _hrtDoses[med.id] ?? med.dose;
      final unit = _hrtUnits[med.id] ?? med.unit;
      final time = _hrtTimes[med.id] ?? '08:00 AM';

      hrtIntakes.add(HrtIntakeLog(
        medicationId: med.id,
        name: med.name,
        dose: dose,
        unit: unit,
        time: time,
        isTaken: checked,
      ));

      final name = med.name.toLowerCase();
      if (name.contains('estradiol') || name.contains('estrogen') || name.contains('estradot')) {
        estradiolChecked = checked;
        estradiolDose = dose;
        estradiolUnit = unit;
        estradiolTime = time;
      } else if (name.contains('progesterone') || name.contains('utrogestan')) {
        progesteroneChecked = checked;
        progesteroneDose = dose;
        progesteroneUnit = unit;
        progesteroneTime = time;
      }
    }

    final List<LoggedSymptom> loggedSymptoms = [];
    for (final id in _selectedSymptomIds) {
      final sanitizedId = sanitizeSymptomId(id);
      final name = _getSymptomName(sanitizedId);
      final severityStr = _symptomSeverities[sanitizedId] ?? 'Mild';
      final duration = _symptomDurations[sanitizedId];
      
      loggedSymptoms.add(
        LoggedSymptom(
          symptom: Symptom(id: sanitizedId, name: name, iconName: 'medical_services', category: 'General'),
          severity: severityStr,
          durationMinutes: duration,
        ),
      );
    }

    final List<String> triggerNames = [];
    for (final id in _selectedTriggerIds) {
      final formatted = formatTriggerString(
        id,
        caffeineCups: _caffeineCups,
        alcoholGlasses: _alcoholGlasses,
        stressLevel: _stressLevel,
        foodsNotes: _foodsNotes,
        customTriggerTexts: _customTriggerTexts,
        customTriggerCounters: _customTriggerCounters,
      );
      triggerNames.add(formatted);
    }

    final List<String> loggedOtherMeds = [];
    _otherMedsChecked.forEach((key, checked) {
      if (checked) {
        try {
          final med = ref.read(otherMedicationsProvider).medications.firstWhere((m) => m.id == key);
          loggedOtherMeds.add("${med.name}${med.dose != null ? ' (${med.dose})' : ''}");
        } catch (e) {}
      }
    });
    
    String finalNotes = _additionalNotes;
    if (loggedOtherMeds.isNotEmpty) {
      finalNotes = "${finalNotes.isNotEmpty ? '$finalNotes\n\n' : ''}Supplements taken today: ${loggedOtherMeds.join(', ')}";
    }

    return DailyLog(
      id: dateStr,
      userId: uid,
      date: date,
      symptoms: loggedSymptoms,
      triggers: triggerNames,
      caffeineCups: _caffeineCups,
      alcoholGlasses: _alcoholGlasses,
      stressLevel: _stressLevel,
      foodsTriggered: _foodsTriggered,
      foodsNotes: _foodsNotes,
      customTriggerCounters: _customTriggerCounters,
      customTriggerTexts: _customTriggerTexts,
      estradiolChecked: estradiolChecked,
      estradiolDose: estradiolDose,
      estradiolUnit: estradiolUnit,
      estradiolTime: estradiolTime,
      progesteroneChecked: progesteroneChecked,
      progesteroneDose: progesteroneDose,
      progesteroneUnit: progesteroneUnit,
      progesteroneTime: progesteroneTime,
      vitaminDChecked: _vitaminDChecked,
      magnesiumChecked: _magnesiumChecked,
      sleepDuration: _sleepDuration,
      hydrationCups: _hydrationCups,
      weight: null,
      additionalNotes: finalNotes,
      hrtIntakes: hrtIntakes,
      createdAt: DateTime.now(),
      isCompleted: isCompleted,
      lastCompletedStep: lastCompletedStep ?? (_maxStepReached > _currentStep ? _maxStepReached : _currentStep),
    );
  }

  Future<void> _saveDraft({int? targetStep}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final step = targetStep ?? _currentStep;
    if (step > _maxStepReached) {
      _maxStepReached = step;
    }
    // Drafts are only saved if the user has completed at least Step 1 (which means targetStep or _maxStepReached is >= 1)
    if (_maxStepReached < 1) return;
    final dailyLog = _buildDailyLog(isCompleted: false, lastCompletedStep: _maxStepReached);
    try {
      await ref.read(firestoreServiceProvider).saveDailyLog(user.uid, dailyLog);
    } catch (e) {
      debugPrint("Error saving daily log draft: $e");
    }
  }

  String _getSymptomName(String id) {
    final library = ref.read(symptomLibraryProvider);
    final symptom = library.firstWhere(
      (s) => s.id == id,
      orElse: () => Symptom(id: id, name: id.replaceAll('s_', '').replaceAll('_', ' '), iconName: 'medical_services'),
    );
    return symptom.name;
  }

  void _nextStep() {
    if (_currentStep < 4) {
      final nextStepIndex = _currentStep + 1;
      _saveDraft(targetStep: nextStepIndex);
      setState(() {
        _currentStep = nextStepIndex;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else if (_currentStep == 4) {
      _saveDraft(targetStep: 5);
      setState(() {
        _currentStep = 5;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0 && _currentStep <= 4) {
      final prevStepIndex = _currentStep - 1;
      _saveDraft(targetStep: prevStepIndex);
      setState(() {
        _currentStep = prevStepIndex;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else if (_currentStep == 5) {
      _saveDraft(targetStep: 4);
      setState(() {
        _currentStep = 4;
      });
    }
  }

  void _showInfoBottomSheet(BuildContext context, int step) {
    String title = '';
    String content = '';

    switch (step) {
      case 0:
        title = 'Step 1 – Symptoms Logging';
        content = 'Select any symptoms that you are experiencing today. Tracking your symptoms daily helps identify hormonal fluctuations, patterns, and trends over time. Regular logging allows Eunora to offer personalized recommendations tailored to your unique journey.';
        break;
      case 1:
        title = 'Step 2 – Rate Intensity';
        content = 'Assign intensity levels to your selected symptoms to track their severity:\n\n• Mild: Noticeable but doesn\'t interfere with daily activities.\n• Moderate: Interferes with some daily activities.\n• Severe: Significantly disrupts your day.\n\nFor hot flashes or night sweats, you can also specify the duration in minutes to monitor their length.';
        break;
      case 2:
        title = 'Step 3 – Log Your Triggers';
        content = 'Select any potential triggers you encountered today. Triggers like caffeine, alcohol, stress, specific foods, and lifestyle factors can directly influence the frequency and severity of your symptoms.';
        break;
      case 3:
        title = 'Step 4 – Journal Influences';
        content = 'Provide details about your selected triggers. You can specify amounts (e.g., cups of coffee, glasses of alcohol), rate your stress levels, or write down notes about foods to better understand how these influences affect your body.';
        break;
      case 4:
        title = 'Step 5 – Review / Daily Data Entry';
        content = 'Log your daily medication (Hormone Replacement Therapy), sleep duration, and water intake. Recording these consistency habits helps visualize how HRT dosage, quality rest, and hydration correlate with your overall symptom patterns.';
        break;
      default:
        title = 'Help';
        content = 'Eunora daily logging assists in tracking your wellness patterns.';
    }

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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                title,
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _finishLoggingAndSync() async {
    final dailyLog = _buildDailyLog(isCompleted: true, lastCompletedStep: 5);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await ref.read(firestoreServiceProvider).saveDailyLog(user.uid, dailyLog);

        // Run promotion check silently after save — user is already on success screen.
        final thirtyDaysAgo =
            DateTime.now().subtract(const Duration(days: kPromotionWindowDays));
        final recentLogs = await ref
            .read(firestoreServiceProvider)
            .getDailyLogsHistory(user.uid, thirtyDaysAgo, DateTime.now());
        await ref
            .read(symptomQuickAccessProvider.notifier)
            .runPromotionCheck(recentLogs);
      } catch (e) {
        debugPrint("Error saving daily log to firestore: $e");
      }
    }

    final List<Map<String, String>> symptomsResult = dailyLog.symptoms.map((s) => {
      'name': s.symptom.name,
      'severity': s.severity ?? 'Mild',
    }).toList();

    final List<Map<String, dynamic>> triggersResult = dailyLog.triggers.map((t) {
      final parsed = parseTriggerString(t);
      final triggerLib = ref.read(triggerLibraryProvider);
      final trigger = triggerLib.firstWhere(
        (tr) => tr.id == parsed.id,
        orElse: () => TriggerOption(
          id: parsed.id,
          name: parsed.label.toUpperCase(),
          description: '',
          iconName: 'spa',
          category: 'Other',
        ),
      );
      return {
        'name': trigger.name.toUpperCase(),
        'value': parsed.value ?? 'Logged',
        'icon': trigger.getIconData(),
      };
    }).toList();

    final result = {
      'symptoms': symptomsResult,
      'triggers': triggersResult,
      'estradiolTaken': dailyLog.estradiolChecked,
      'progesteroneTaken': dailyLog.progesteroneChecked,
    };

    Navigator.pop(context, result);
  }

  Future<void> _handleCancel() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes?', style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to go back? Any changes made during this logging session will not be saved.', style: GoogleFonts.manrope()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.outline)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard', style: GoogleFonts.manrope(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (leave == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLog) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF9F6),
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
          ),
        ),
      );
    }

    // Reactive initialization from profile/providers once loaded
    final profile = ref.watch(onboardingProfileProvider);
    if (profile != null && !_isMedsInitialized && !_isSymptomsInitialized && !_existingLogLoaded) {
      _isMedsInitialized = true;
      _isSymptomsInitialized = true;

      // Symptoms start unselected by default for fresh logging session
      _selectedSymptomIds.clear();

      // Triggers start unchecked
      _selectedTriggerIds.clear();

      // Initialize medications from profile
      for (final med in profile.medications) {
        _hrtChecked[med.id] = false;
        _hrtDoses[med.id] = med.dose;
        _hrtUnits[med.id] = med.unit;
        _hrtTimes[med.id] = '08:00 AM';
        _initialHrtDoses[med.id] = med.dose;
        _initialHrtUnits[med.id] = med.unit;
      }

      // Initialize other medications from profile
      _otherMedsChecked.clear();
      for (final med in profile.otherMedications) {
        _otherMedsChecked[med.id] = true;
      }
    } else if (profile == null && !_isMedsInitialized && !_isSymptomsInitialized && !_existingLogLoaded) {
      final meds = ref.watch(medicationsProvider).medications.where((m) => m.endedAt == null).toList();
      if (meds.isNotEmpty) {
        _isMedsInitialized = true;
        for (final med in meds) {
          _hrtChecked[med.id] = false;
          _hrtDoses[med.id] = med.dose;
          _hrtUnits[med.id] = med.unit;
          _hrtTimes[med.id] = '08:00 AM';
          _initialHrtDoses[med.id] = med.dose;
          _initialHrtUnits[med.id] = med.unit;
        }
      }
      _isSymptomsInitialized = true;
      _selectedSymptomIds.clear();
      _selectedTriggerIds.clear();
      final otherMeds = ref.watch(otherMedicationsProvider).medications;
      if (otherMeds.isNotEmpty) {
        _otherMedsChecked.clear();
        for (final med in otherMeds) {
          _otherMedsChecked[med.id] = true;
        }
      }
    }

    // Reactive Symptom & Trigger Listeners
    // Only update selection if we have NOT yet loaded a real log from Firestore
    // (prevents overwriting Firestore-loaded symptoms when user re-opens logging)
    ref.listen(symptomsProvider, (previous, next) {
      if (!_existingLogLoaded) {
        setState(() {
          _selectedSymptomIds.retainAll(next.frequentSymptomIds.map(sanitizeSymptomId));
        });
      }
    });

    ref.listen(triggersProvider, (previous, next) {
      if (!_existingLogLoaded) {
        setState(() {
          _selectedTriggerIds.retainAll(next.activeTriggerIds);
        });
      }
    });

    if (_currentStep == 5) {
      return _buildSuccessScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleCancel();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F6), // brand-cream
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: _currentStep,
              totalSteps: 5,
              title: _getStepTitle(),
              showStepPill: true,
              showBackButton: true,
              onBack: _currentStep == 0 ? _handleCancel : _prevStep,
              onSkip: () => _showInfoBottomSheet(context, _currentStep),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentStep = page;
                  });
                },
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: SymptomsStep(
                      selectedSymptomIds: _selectedSymptomIds,
                      onSymptomToggled: (symId) {
                        setState(() {
                          if (_selectedSymptomIds.contains(symId)) {
                            _selectedSymptomIds.remove(symId);
                          } else {
                            _selectedSymptomIds.add(symId);
                          }
                        });
                      },
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: SeverityStep(
                      selectedSymptomIds: _selectedSymptomIds,
                      symptomSeverities: _symptomSeverities,
                      symptomDurations: _symptomDurations,
                      onSeverityChanged: (entry) {
                        setState(() {
                          _symptomSeverities[entry.key] = entry.value;
                        });
                      },
                      onDurationChanged: (entry) {
                        setState(() {
                          _symptomDurations[entry.key] = entry.value;
                        });
                      },
                      onAddAnotherSymptom: () {
                        setState(() {
                          _currentStep = 0;
                        });
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: TriggersStep(
                      selectedTriggerIds: _selectedTriggerIds,
                      onTriggerToggled: (trigId) {
                        setState(() {
                          if (_selectedTriggerIds.contains(trigId)) {
                            _selectedTriggerIds.remove(trigId);
                          } else {
                            _selectedTriggerIds.add(trigId);
                          }
                        });
                      },
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: TriggerDetailsStep(
                      selectedTriggerIds: _selectedTriggerIds,
                      caffeineCups: _caffeineCups,
                      alcoholGlasses: _alcoholGlasses,
                      stressLevel: _stressLevel,
                      foodsTriggered: _foodsTriggered,
                      foodsNotes: _foodsNotes,
                      customTriggerCounters: _customTriggerCounters,
                      customTriggerTexts: _customTriggerTexts,
                      onCaffeineCupsChanged: (val) {
                        setState(() {
                          _caffeineCups = val;
                        });
                      },
                      onAlcoholGlassesChanged: (val) {
                        setState(() {
                          _alcoholGlasses = val;
                        });
                      },
                      onStressLevelChanged: (val) {
                        setState(() {
                          _stressLevel = val;
                        });
                      },
                      onFoodsTriggeredChanged: (val) {
                        setState(() {
                          _foodsTriggered = val;
                        });
                      },
                      onFoodsNotesChanged: (val) {
                        setState(() {
                          _foodsNotes = val;
                        });
                      },
                      onCustomTriggerCounterChanged: (trigId, val) {
                        setState(() {
                          _customTriggerCounters[trigId] = val;
                        });
                      },
                      onCustomTriggerTextChanged: (trigId, val) {
                        setState(() {
                          _customTriggerTexts[trigId] = val;
                        });
                      },
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: DailyEntryStep(
                      loggingDate: widget.initialDate,
                      hrtChecked: _hrtChecked,
                      hrtDoses: _hrtDoses,
                      hrtUnits: _hrtUnits,
                      hrtTimes: _hrtTimes,
                      initialHrtDoses: _initialHrtDoses,
                      initialHrtUnits: _initialHrtUnits,
                      onHrtCheckedToggled: (medId, val) {
                        setState(() {
                          _hrtChecked[medId] = val;
                        });
                      },
                      onHrtDoseChanged: (medId, val) {
                        setState(() {
                          _hrtDoses[medId] = val;
                        });
                      },
                      onHrtUnitChanged: (medId, val) {
                        setState(() {
                          _hrtUnits[medId] = val;
                        });
                      },
                      onHrtTimeChanged: (medId, val) {
                        setState(() {
                          _hrtTimes[medId] = val;
                        });
                      },
                      vitaminDChecked: _vitaminDChecked,
                      magnesiumChecked: _magnesiumChecked,
                      sleepDuration: _sleepDuration,
                      hydrationCups: _hydrationCups,
                      additionalNotes: _additionalNotes,
                      otherMedsChecked: _otherMedsChecked,
                      onOtherMedsChanged: (val) {
                        setState(() {
                          _otherMedsChecked.clear();
                          _otherMedsChecked.addAll(val);
                        });
                      },
                      onVitaminDCheckedToggled: (val) {
                        setState(() {
                          _vitaminDChecked = val;
                        });
                      },
                      onMagnesiumCheckedToggled: (val) {
                        setState(() {
                          _magnesiumChecked = val;
                        });
                      },
                      onSleepDurationChanged: (val) {
                        setState(() {
                          _sleepDuration = val;
                        });
                      },
                      onHydrationCupsChanged: (val) {
                        setState(() {
                          _hydrationCups = val;
                        });
                      },
                      onAdditionalNotesChanged: (val) {
                        setState(() {
                          _additionalNotes = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    ),);
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Log Your Symptoms';
      case 1:
        return 'Rate intensity';
      case 2:
        return 'Log Your Triggers';
      case 3:
        return 'Journal Influences';
      case 4:
        return 'Daily Entry';
      default:
        return 'Eunora';
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6).withOpacity(0.95),
        border: const Border(top: BorderSide(color: Color(0xFFF2EDEA))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 52,
                child: Bounceable(
                  onTap: _prevStep,
                  child: IgnorePointer(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD0C4BC)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: Bounceable(
                onTap: _nextStep,
                child: IgnorePointer(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      _currentStep == 4 ? 'Save Log' : 'Continue',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return DailyLoggingSuccessScreen(
      onFinish: _finishLoggingAndSync,
    );
  }
}
