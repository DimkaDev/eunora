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

import 'package:eunora/features/home/presentation/pages/daily_logging/symptoms_step.dart';
import 'package:eunora/features/home/presentation/pages/daily_logging/severity_step.dart';
import 'package:eunora/features/home/presentation/pages/daily_logging/triggers_step.dart';
import 'package:eunora/features/home/presentation/pages/daily_logging/trigger_details_step.dart';
import 'package:eunora/features/home/presentation/pages/daily_logging/daily_entry_step.dart';
import 'package:eunora/features/home/presentation/widgets/dose_change_alert.dart';

class DailyLoggingPage extends ConsumerStatefulWidget {
  const DailyLoggingPage({super.key});

  @override
  ConsumerState<DailyLoggingPage> createState() => _DailyLoggingPageState();
}

class _DailyLoggingPageState extends ConsumerState<DailyLoggingPage> {
  int _currentStep = 0; // 0 to 5 (Step 1 to Step 6)

  // Step 1: Symptoms Selection
  final Set<String> _selectedSymptomIds = {'s_hot_flashes'};
  final List<String> _customSymptoms = [];

  // Step 2: Symptom Severities & Durations
  final Map<String, String> _symptomSeverities = {
    's_hot_flashes': 'Moderate',
    's_mood': 'Mild',
    's_sleep': 'Severe',
    's_dryness': 'Mild',
    's_joint_pain': 'Mild',
  };
  final Map<String, int> _symptomDurations = {
    's_hot_flashes': 30,
    's_night_sweats': 15,
  };

  // Step 3: Trigger Selection
  final Set<String> _selectedTriggerIds = {'t_stress'};
  final List<String> _customTriggers = [];

  // Step 4: Trigger Details
  int _caffeineCups = 2;
  int _alcoholGlasses = 1;
  String _stressLevel = 'Moderate'; // Calm, Moderate, High
  bool _foodsTriggered = true;
  String _foodsNotes = 'Spicy food in evening';
  final Map<String, int> _customTriggerCounters = {};
  final Map<String, String> _customTriggerTexts = {};

  // Step 5: Medications & Supplements
  bool _estradiolChecked = false;
  double _estradiolDose = 50.0; // Typical is 50.0 mcg
  String _estradiolUnit = 'mcg';
  String _estradiolTime = '08:30 AM';

  bool _progesteroneChecked = false;
  double _progesteroneDose = 100.0; // Typical is 100.0 mg
  String _progesteroneUnit = 'mg';
  String _progesteroneTime = '08:00 PM';

  bool _vitaminDChecked = false;
  bool _magnesiumChecked = false;

  double _sleepDuration = 7.5;
  int _hydrationCups = 8;
  String _additionalNotes = '';
  double? _initialEstradiolDose;
  String? _initialEstradiolUnit;
  double? _initialProgesteroneDose;
  String? _initialProgesteroneUnit;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final symptomsState = ref.read(symptomsProvider);
      final triggersState = ref.read(triggersProvider);
      setState(() {
        _selectedSymptomIds.retainAll(symptomsState.frequentSymptomIds);
        _selectedTriggerIds.retainAll(triggersState.activeTriggerIds);
      });

      final meds = ref.read(medicationsProvider).medications;
      for (final med in meds) {
        final name = med.name.toLowerCase();
        if (name.contains('estradiol') || name.contains('estrogen') || name.contains('estradot')) {
          setState(() {
            _estradiolChecked = false;
            _estradiolDose = med.dose;
            _estradiolUnit = med.unit;
            _initialEstradiolDose = med.dose;
            _initialEstradiolUnit = med.unit;
          });
        } else if (name.contains('progesterone') || name.contains('utrogestan')) {
          setState(() {
            _progesteroneChecked = false;
            _progesteroneDose = med.dose;
            _progesteroneUnit = med.unit;
            _initialProgesteroneDose = med.dose;
            _initialProgesteroneUnit = med.unit;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else if (_currentStep == 4) {
      Map<String, dynamic>? primaryChange;
      if (_estradiolChecked && _initialEstradiolDose != null && (_estradiolDose != _initialEstradiolDose || _estradiolUnit != _initialEstradiolUnit)) {
        primaryChange = {
          'name': 'Estradiol Patch',
          'oldDose': '${_initialEstradiolDose!.toStringAsFixed(_initialEstradiolDose == _initialEstradiolDose!.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), '')} $_initialEstradiolUnit',
          'newDose': '${_estradiolDose.toStringAsFixed(_estradiolDose == _estradiolDose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), '')} $_estradiolUnit',
        };
      } else if (_progesteroneChecked && _initialProgesteroneDose != null && (_progesteroneDose != _initialProgesteroneDose || _progesteroneUnit != _initialProgesteroneUnit)) {
        primaryChange = {
          'name': 'Progesterone',
          'oldDose': '${_initialProgesteroneDose!.toStringAsFixed(_initialProgesteroneDose == _initialProgesteroneDose!.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), '')} $_initialProgesteroneUnit',
          'newDose': '${_progesteroneDose.toStringAsFixed(_progesteroneDose == _progesteroneDose.toInt() ? 0 : 2).replaceAll(RegExp(r'\.00$'), '')} $_progesteroneUnit',
        };
      }

      if (primaryChange != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: const Color(0xFF1D1B1A).withOpacity(0.4),
          builder: (context) {
            return DoseChangeAlert(
              change: primaryChange!,
              onConfirm: () {
                Navigator.pop(context);
                setState(() {
                  _currentStep = 5;
                });
              },
              onCancel: () {
                Navigator.pop(context);
              },
            );
          },
        );
      } else {
        setState(() {
          _currentStep = 5;
        });
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0 && _currentStep <= 4) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else if (_currentStep == 5) {
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
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
    // Generate results
    final List<Map<String, String>> symptomsResult = [];
    for (final id in _selectedSymptomIds) {
      symptomsResult.add({
        'name': _getSymptomName(id),
        'severity': _symptomSeverities[id] ?? 'Mild',
      });
    }

    final List<Map<String, dynamic>> triggersResult = [];
    final triggerLib = ref.read(triggerLibraryProvider);
    for (final id in _selectedTriggerIds) {
      dynamic val = '';
      if (id == 't_caffeine') val = '$_caffeineCups cups';
      else if (id == 't_alcohol') val = '$_alcoholGlasses glass';
      else if (id == 't_stress') val = _stressLevel;
      else if (id == 't_foods') val = _foodsTriggered ? 'Foods: $_foodsNotes' : 'None';
      else val = _customTriggerCounters[id]?.toString() ?? _customTriggerTexts[id] ?? 'Logged';

      final trigger = triggerLib.firstWhere(
        (t) => t.id == id,
        orElse: () => TriggerOption(id: id, name: id.replaceAll('t_', '').toUpperCase(), description: '', iconName: 'spa', category: 'Other'),
      );

      triggersResult.add({
        'name': trigger.name.toUpperCase(),
        'value': val,
        'icon': trigger.getIconData(),
      });
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final date = DateTime.now();
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final List<LoggedSymptom> loggedSymptoms = [];
      for (final id in _selectedSymptomIds) {
        final name = _getSymptomName(id);
        final severityStr = _symptomSeverities[id] ?? 'Mild';

        loggedSymptoms.add(
          LoggedSymptom(
            symptom: Symptom(
              id: id,
              name: name,
              iconName: id == 's_hot_flashes'
                  ? 'thermostat'
                  : id == 's_mood'
                      ? 'mood'
                      : id == 's_sleep'
                          ? 'dark_mode'
                          : id == 's_dryness'
                              ? 'opacity'
                              : 'accessibility_new',
              category: 'General',
            ),
            severity: severityStr,
          ),
        );
      }

      final List<String> triggerNames = [];
      for (final id in _selectedTriggerIds) {
        if (id == 't_caffeine') {
          triggerNames.add('Caffeine: $_caffeineCups cups');
        } else if (id == 't_alcohol') {
          triggerNames.add('Alcohol: $_alcoholGlasses glasses');
        } else if (id == 't_stress') {
          triggerNames.add('Stress: $_stressLevel');
        } else if (id == 't_foods') {
          triggerNames.add(_foodsTriggered ? 'Foods: $_foodsNotes' : 'Foods');
        } else {
          triggerNames.add(id.replaceAll('t_', '').toUpperCase());
        }
      }

      final dailyLog = DailyLog(
        id: dateStr,
        userId: user.uid,
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
        estradiolChecked: _estradiolChecked,
        estradiolDose: _estradiolDose,
        estradiolUnit: _estradiolUnit,
        estradiolTime: _estradiolTime,
        progesteroneChecked: _progesteroneChecked,
        progesteroneDose: _progesteroneDose,
        progesteroneUnit: _progesteroneUnit,
        progesteroneTime: _progesteroneTime,
        vitaminDChecked: _vitaminDChecked,
        magnesiumChecked: _magnesiumChecked,
        sleepDuration: _sleepDuration,
        hydrationCups: _hydrationCups,
        weight: null,
        additionalNotes: _additionalNotes,
        createdAt: DateTime.now(),
      );

      // Save asynchronously in the background so it does not block navigation
      ref.read(firestoreServiceProvider).saveDailyLog(user.uid, dailyLog).catchError((e) {
        debugPrint("Error saving daily log to firestore: $e");
      });
    }

    final result = {
      'symptoms': symptomsResult,
      'triggers': triggersResult,
      'estradiolTaken': _estradiolChecked,
      'progesteroneTaken': _progesteroneChecked,
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    // Reactive Symptom & Trigger Listeners
    ref.listen(symptomsProvider, (previous, next) {
      setState(() {
        _selectedSymptomIds.retainAll(next.frequentSymptomIds);
      });
    });

    ref.listen(triggersProvider, (previous, next) {
      setState(() {
        _selectedTriggerIds.retainAll(next.activeTriggerIds);
      });
    });

    if (_currentStep == 5) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6), // brand-cream
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: _currentStep,
              totalSteps: 5,
              title: _getStepTitle(),
              showStepPill: true,
              showBackButton: _currentStep != 0,
              onBack: _currentStep == 0 ? () => context.pop() : _prevStep,
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
                      estradiolChecked: _estradiolChecked,
                      estradiolDose: _estradiolDose,
                      estradiolUnit: _estradiolUnit,
                      estradiolTime: _estradiolTime,
                      progesteroneChecked: _progesteroneChecked,
                      progesteroneDose: _progesteroneDose,
                      progesteroneUnit: _progesteroneUnit,
                      progesteroneTime: _progesteroneTime,
                      vitaminDChecked: _vitaminDChecked,
                      magnesiumChecked: _magnesiumChecked,
                      sleepDuration: _sleepDuration,
                      hydrationCups: _hydrationCups,
                      additionalNotes: _additionalNotes,
                      onEstradiolCheckedToggled: (val) {
                        setState(() {
                          _estradiolChecked = val;
                        });
                      },
                      onEstradiolDoseChanged: (val) {
                        setState(() {
                          _estradiolDose = val;
                        });
                      },
                      onEstradiolUnitChanged: (val) {
                        setState(() {
                          _estradiolUnit = val;
                        });
                      },
                      onEstradiolTimeChanged: (val) {
                        setState(() {
                          _estradiolTime = val;
                        });
                      },
                      onProgesteroneCheckedToggled: (val) {
                        setState(() {
                          _progesteroneChecked = val;
                        });
                      },
                      onProgesteroneDoseChanged: (val) {
                        setState(() {
                          _progesteroneDose = val;
                        });
                      },
                      onProgesteroneUnitChanged: (val) {
                        setState(() {
                          _progesteroneUnit = val;
                        });
                      },
                      onProgesteroneTimeChanged: (val) {
                        setState(() {
                          _progesteroneTime = val;
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
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFB8A7C5).withOpacity(0.2),
                      const Color(0xFF8EB8B5).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: AppTheme.primary, size: 48),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "You're all set, Sarah.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSerif(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Daily Sync Complete. Eunora is personalised for your journey.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                _buildReminderSyncCard('🌿', 'Take your HRT', 'Primary Morning Dose at 8:30 AM'),
                const SizedBox(height: 12),
                _buildReminderSyncCard('🌙', 'Log your day', 'Evening Wind Down at 8:00 PM'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _finishLoggingAndSync,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppTheme.primary.withOpacity(0.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Finish & Sync',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_outline),
                      ],
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

  Widget _buildReminderSyncCard(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFF7F5F0), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
