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
  bool _estradiolChecked = true;
  double _estradiolDose = 50.0; // Typical is 50.0 mcg
  String _estradiolUnit = 'mcg';
  String _estradiolTime = '08:30 AM';

  bool _progesteroneChecked = false;
  double _progesteroneDose = 100.0; // Typical is 100.0 mg
  String _progesteroneUnit = 'mg';
  String _progesteroneTime = '08:00 PM';

  bool _vitaminDChecked = false;
  bool _magnesiumChecked = true;

  double _sleepDuration = 7.5;
  int _hydrationCups = 8;
  String _additionalNotes = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final meds = ref.read(medicationsProvider).medications;
      for (final med in meds) {
        final name = med.name.toLowerCase();
        if (name.contains('estradiol') || name.contains('estrogen') || name.contains('estradot')) {
          setState(() {
            _estradiolChecked = true;
            _estradiolDose = med.dose;
            _estradiolUnit = med.unit;
          });
        } else if (name.contains('progesterone') || name.contains('utrogestan')) {
          setState(() {
            _progesteroneChecked = true;
            _progesteroneDose = med.dose;
            _progesteroneUnit = med.unit;
          });
        }
      }
    });
  }

  // All symptoms template definitions for colors and icons
  final Map<String, Map<String, dynamic>> _symptomTemplates = {
    's_hot_flashes': {
      'name': 'Hot Flashes',
      'icon': Icons.thermostat,
      'color': const Color(0xFFD4A5A5), // brand-rose
      'bg': const Color(0xFFFDF2F2),
    },
    's_mood': {
      'name': 'Mood Changes',
      'icon': Icons.mood,
      'color': const Color(0xFFA7C5D8), // brand-sky
      'bg': const Color(0xFFF0F6FA),
    },
    's_sleep': {
      'name': 'Sleep Issues',
      'icon': Icons.dark_mode,
      'color': const Color(0xFFB8A7C5), // brand-lavender
      'bg': const Color(0xFFF5F0FA),
    },
    's_dryness': {
      'name': 'Dryness',
      'icon': Icons.opacity,
      'color': const Color(0xFF8EB8B5), // brand-teal
      'bg': const Color(0xFFF0F7F7),
    },
    's_joint_pain': {
      'name': 'Joint Pain',
      'icon': Icons.accessibility_new,
      'color': const Color(0xFFA9B388), // brand-sage
      'bg': const Color(0xFFF5F7F0),
    },
  };

  // Triggers template definitions
  final Map<String, Map<String, dynamic>> _triggerTemplates = {
    't_caffeine': {
      'name': 'Caffeine',
      'desc': 'Coffee, tea, energy drinks, or soda consumed throughout the day.',
      'icon': Icons.coffee,
      'bg': const Color(0xFFFDECE8), // peach-soft
    },
    't_alcohol': {
      'name': 'Alcohol',
      'desc': 'Wine, beer, or cocktails, especially late in the evening.',
      'icon': Icons.local_bar,
      'bg': const Color(0xFFEDE8F4), // lavender-soft
    },
    't_stress': {
      'name': 'Stress',
      'desc': 'High mental or emotional pressure from work, home, or personal life.',
      'icon': Icons.psychology,
      'bg': const Color(0xFFF5F0FA),
    },
    't_exercise': {
      'name': 'Exercise',
      'desc': 'Physical exertion, intense workouts, or new activity levels.',
      'icon': Icons.fitness_center,
      'bg': const Color(0xFFEDE8F4),
    },
    't_weather': {
      'name': 'Weather',
      'desc': 'Extreme heat, high humidity, or sudden temperature shifts.',
      'icon': Icons.thermostat,
      'bg': const Color(0xFFFDECE8),
    },
    't_foods': {
      'name': 'Foods',
      'desc': 'Spicy foods, sugary snacks, or heavy meals before bed.',
      'icon': Icons.restaurant,
      'bg': const Color(0xFFEDE8F4),
    },
  };

  String _getSymptomName(String id) {
    final library = ref.read(symptomLibraryProvider);
    final symptom = library.firstWhere(
      (s) => s.id == id,
      orElse: () => Symptom(id: id, name: id.replaceAll('s_', '').replaceAll('_', ' '), iconName: 'medical_services'),
    );
    return symptom.name;
  }

  IconData _getSymptomIcon(String id) {
    final library = ref.read(symptomLibraryProvider);
    final symptom = library.firstWhere(
      (s) => s.id == id,
      orElse: () => Symptom(id: id, name: id.replaceAll('s_', '').replaceAll('_', ' '), iconName: 'medical_services'),
    );
    return symptom.getIconData();
  }

  Color _getSymptomColor(String id) {
    final library = ref.read(symptomLibraryProvider);
    final symptom = library.firstWhere(
      (s) => s.id == id,
      orElse: () => Symptom(id: id, name: id.replaceAll('s_', '').replaceAll('_', ' '), iconName: 'medical_services'),
    );
    return symptom.getIconColor();
  }

  Color _getSymptomBg(String id) {
    final library = ref.read(symptomLibraryProvider);
    final symptom = library.firstWhere(
      (s) => s.id == id,
      orElse: () => Symptom(id: id, name: id.replaceAll('s_', '').replaceAll('_', ' '), iconName: 'medical_services'),
    );
    return symptom.getIconColor().withOpacity(0.1);
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < 5) {
        _currentStep++;
      }
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  void _addCustomSymptom() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFEF8F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Custom Symptom',
          style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Symptom name (e.g. Brain Fog)',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  _customSymptoms.add(val);
                  _selectedSymptomIds.add(val);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addCustomTrigger() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFEF8F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Custom Influence',
          style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Influence name (e.g. Travel)',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  _customTriggers.add(val);
                  _selectedTriggerIds.add(val);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openMedicationModal(String medKey) {
    bool isEstradiol = medKey == 'estradiol';
    double dose = isEstradiol ? _estradiolDose : _progesteroneDose;
    String unit = isEstradiol ? _estradiolUnit : _progesteroneUnit;
    String time = isEstradiol ? _estradiolTime : _progesteroneTime;
    String medName = isEstradiol ? 'Estradiol Patch' : 'Progesterone';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFEF8F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                        color: const Color(0xFFD0C4BC).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF9B8B7E)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          Text(
                            medName,
                            style: GoogleFonts.notoSerif(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            "Today's Log",
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: const Color(0xFF9B8B7E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Time Taken
                  Text(
                    'TIME TAKEN',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: const Color(0xFF9B8B7E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final timeOfDay = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (timeOfDay != null) {
                        setModalState(() {
                          time = timeOfDay.format(context);
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule, color: AppTheme.primary),
                              const SizedBox(width: 12),
                              Text(
                                time,
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFFD0C4BC)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Dose
                  Text(
                    'DOSE AMOUNT',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: const Color(0xFF9B8B7E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7E1DF),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextFormField(
                            initialValue: dose.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                            onChanged: (val) {
                              final parsed = double.tryParse(val);
                              if (parsed != null) {
                                dose = parsed;
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7E5),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setModalState(() => unit = isEstradiol ? 'mcg' : 'mg'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: unit == (isEstradiol ? 'mcg' : 'mg')
                                      ? const Color(0xFFEDDDF5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  isEstradiol ? 'mcg' : 'mg',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: unit == (isEstradiol ? 'mcg' : 'mg')
                                        ? const Color(0xFF6C6074)
                                        : const Color(0xFF9B8B7E),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setModalState(() => unit = isEstradiol ? 'mg' : 'mcg'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: unit == (isEstradiol ? 'mg' : 'mcg')
                                      ? const Color(0xFFEDDDF5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  isEstradiol ? 'mg' : 'mcg',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: unit == (isEstradiol ? 'mg' : 'mcg')
                                        ? const Color(0xFF6C6074)
                                        : const Color(0xFF9B8B7E),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // consistency card tip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2DFD0).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD6C3B5).withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Consistency is key for hormone stability. Try to apply your patch within the same hour window each time.',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: const Color(0xFF51443A),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // save & delete buttons
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveMedicationEdit(medKey, dose, unit, time);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Save changes',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          if (isEstradiol) {
                            _estradiolChecked = false;
                          } else {
                            _progesteroneChecked = false;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Delete Entry',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.error),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveMedicationEdit(String medKey, double dose, String unit, String time) {
    bool isEstradiol = medKey == 'estradiol';
    double defaultDose = isEstradiol ? 50.0 : 100.0;

    if (dose != defaultDose) {
      // Dose change warning dialog!
      _showDoseChangeAlert(medKey, defaultDose, dose, unit, time);
    } else {
      // Directly save
      setState(() {
        if (isEstradiol) {
          _estradiolDose = dose;
          _estradiolUnit = unit;
          _estradiolTime = time;
          _estradiolChecked = true;
        } else {
          _progesteroneDose = dose;
          _progesteroneUnit = unit;
          _progesteroneTime = time;
          _progesteroneChecked = true;
        }
      });
    }
  }

  void _showDoseChangeAlert(String medKey, double beforeDose, double afterDose, String unit, String time) {
    bool isEstradiol = medKey == 'estradiol';
    String medLabel = isEstradiol ? 'Estradiol' : 'Progesterone';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFFEF8F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.help_outline, color: Color(0xFF9B8B7E), size: 48),
              const SizedBox(height: 16),
              Text(
                'We Noticed a Dose Change',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.4),
                  children: [
                    const TextSpan(text: 'Your last entry for '),
                    TextSpan(text: medLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' showed ${beforeDose.toStringAsFixed(0)} $unit. Your new entry shows ${afterDose.toStringAsFixed(0)} $unit. Did your doctor change your dose?'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // visual comparison block
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text('BEFORE', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFA8A29E))),
                        const SizedBox(height: 2),
                        Text('${beforeDose.toStringAsFixed(0)} $unit', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFA8A29E))),
                      ],
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.arrow_forward, color: Color(0xFF9B8B7E)),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text('AFTER', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF9B8B7E))),
                        const SizedBox(height: 2),
                        Text('${afterDose.toStringAsFixed(0)} $unit', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF9B8B7E))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // purple warning explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDDDF5).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Tracking dose changes helps us show you the impact on your symptoms. We'll track the next 14 days and compare.",
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF6C6074),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (isEstradiol) {
                        _estradiolDose = afterDose;
                        _estradiolUnit = unit;
                        _estradiolTime = time;
                        _estradiolChecked = true;
                      } else {
                        _progesteroneDose = afterDose;
                        _progesteroneUnit = unit;
                        _progesteroneTime = time;
                        _progesteroneChecked = true;
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B8B7E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Yes, My Dose Changed',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    // Reset to default
                    setState(() {
                      if (isEstradiol) {
                        _estradiolDose = beforeDose;
                        _estradiolChecked = true;
                      } else {
                        _progesteroneDose = beforeDose;
                        _progesteroneChecked = true;
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD0C4BC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'No, That Was a Mistake',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

      try {
        await ref.read(firestoreServiceProvider).saveDailyLog(user.uid, dailyLog);
      } catch (e) {
        debugPrint("Error saving daily log to firestore: $e");
      }
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
    // Reactive Symptom Synchronization
    final symptomsState = ref.watch(symptomsProvider);
    _selectedSymptomIds.retainAll(symptomsState.frequentSymptomIds);

    // Reactive Trigger Synchronization
    final triggersState = ref.watch(triggersProvider);
    _selectedTriggerIds.retainAll(triggersState.activeTriggerIds);

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
              child: DirectionalAnimatedSwitcher(
                currentIndex: _currentStep,
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: _buildStepView(),
                  ),
                ),
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

  Widget _buildStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1SymptomsGrid();
      case 1:
        return _buildStep2SeveritySliders();
      case 2:
        return _buildStep3TriggersGrid();
      case 3:
        return _buildStep4TriggerDetails();
      case 4:
        return _buildStep5FinalConfirm();
      default:
        return Container();
    }
  }

  // --- STEP 1: Symptom Selection Grid ---
  Widget _buildStep1SymptomsGrid() {
    final state = ref.watch(symptomsProvider);
    final library = ref.watch(symptomLibraryProvider);

    // Get symptoms currently marked as "Frequent" (even if deselected)
    final frequentSymptoms = state.frequentSymptomIds.map((id) {
      return library.firstWhere(
        (s) => s.id == id,
        orElse: () => Symptom(
          id: id,
          name: id.replaceAll('s_', '').replaceAll('_', ' '),
          iconName: 'medical_services',
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'How are you feeling right now?',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select any symptoms that have been bothering you today. We\'re here to listen.',
          style: GoogleFonts.manrope(
            fontSize: 16,
            color: const Color(0xFF1D1B1A).withOpacity(0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: frequentSymptoms.length + 1,
          itemBuilder: (context, index) {
            if (index == frequentSymptoms.length) {
              // Add Custom Other Button (opens library page)
              return Bounceable(
                onTap: () => context.push('/symptom-library'),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFF9B8B7E).withOpacity(0.2),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B8B7E).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: const Color(0xFF9B8B7E).withOpacity(0.4),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Other',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF9B8B7E).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final symptom = frequentSymptoms[index];
            final symId = symptom.id;
            final isSelected = _selectedSymptomIds.contains(symId);
            final symName = symptom.name;
            final iconColor = symptom.getIconColor();
            final iconBgColor = iconColor.withOpacity(0.1);

            return Bounceable(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSymptomIds.remove(symId);
                  } else {
                    _selectedSymptomIds.add(symId);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF9B8B7E) : Colors.transparent,
                    width: isSelected ? 2 : 0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
                      blurRadius: isSelected ? 15 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isSelected ? iconColor.withOpacity(0.2) : iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        symptom.getIconData(),
                        color: iconColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        symName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF1D1B1A)
                              : const Color(0xFF9B8B7E),
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        // Tip banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF9B8B7E).withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF9B8B7E).withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Color(0xFF9B8B7E), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '"It\'s common to experience multiple symptoms. Logging them helps us spot patterns in your journey."',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF9B8B7E),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- STEP 2: Symptom Severity Sliders ---
  Widget _buildStep2SeveritySliders() {
    if (_selectedSymptomIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.playlist_add_check, size: 64, color: Color(0xFFD0C4BC)),
              const SizedBox(height: 16),
              Text(
                'No symptoms selected',
                style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Go back and select symptoms to rate.',
                style: GoogleFonts.manrope(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Rate your symptoms',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A gentle check-in on how you\'re feeling.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF8A817C),
          ),
        ),
        const SizedBox(height: 32),
        ..._selectedSymptomIds.map((id) {
          final symName = _getSymptomName(id);
          final symIcon = _getSymptomIcon(id);
          final symBg = _getSymptomBg(id);
          final symColor = _getSymptomColor(id);
          final currentSeverity = _symptomSeverities[id] ?? 'Mild';
          final hasDuration = id == 's_hot_flashes' || id == 's_night_sweats';
          final duration = _symptomDurations[id] ?? 15;

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: symColor.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: symBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(symIcon, color: symColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      symName,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'INTENSITY',
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: const Color(0xFF8A817C),
                  ),
                ),
                const SizedBox(height: 12),
                // custom premium fluid severity bar
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE2F5E2), // Soft Green (Mild)
                        Color(0xFFFFF1D0), // Soft Yellow/Orange (Moderate)
                        Color(0xFFFFE0E0), // Soft Red (Severe)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Stack(
                    children: [
                      // White sliding thumb selector
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: currentSeverity == 'Mild'
                            ? Alignment.centerLeft
                            : currentSeverity == 'Moderate'
                                ? Alignment.center
                                : Alignment.centerRight,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.26,
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                      // Three Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _symptomSeverities[id] = 'Mild'),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('😊', style: TextStyle(fontSize: 18)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Mild',
                                      style: GoogleFonts.manrope(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: currentSeverity == 'Mild' ? AppTheme.primary : const Color(0xFF8A817C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _symptomSeverities[id] = 'Moderate'),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('😐', style: TextStyle(fontSize: 18)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Moderate',
                                      style: GoogleFonts.manrope(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: currentSeverity == 'Moderate' ? AppTheme.primary : const Color(0xFF8A817C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _symptomSeverities[id] = 'Severe'),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('😟', style: TextStyle(fontSize: 18)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Severe',
                                      style: GoogleFonts.manrope(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: currentSeverity == 'Severe' ? AppTheme.primary : const Color(0xFF8A817C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasDuration) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF7F5F0), height: 1),
                  const SizedBox(height: 20),
                  Text(
                    'DURATION',
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: const Color(0xFF8A817C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // duration increments
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5F0).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (duration > 5) {
                              setState(() => _symptomDurations[id] = duration - 5);
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: const Icon(Icons.remove, color: AppTheme.primary),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$duration',
                              style: GoogleFonts.notoSerif(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'min',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8A817C),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _symptomDurations[id] = duration + 5);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: const Icon(Icons.add, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        // Add another symptom button
        SizedBox(
          width: double.infinity,
          height: 72,
          child: OutlinedButton(
            onPressed: () => setState(() => _currentStep = 0),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primary.withOpacity(0.2), width: 2, style: BorderStyle.solid),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Add another symptom',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- STEP 3: Trigger Selection Grid ---
  Widget _buildStep3TriggersGrid() {
    final state = ref.watch(triggersProvider);
    final library = ref.watch(triggerLibraryProvider);

    // Get active triggers currently marked as tracked
    final activeTriggers = state.activeTriggerIds.map((id) {
      return library.firstWhere(
        (t) => t.id == id,
        orElse: () => TriggerOption(
          id: id,
          name: id.replaceAll('t_', '').toUpperCase(),
          description: 'Influence on daily routines',
          iconName: 'spa',
          category: 'Other',
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'What might have triggered your symptoms?',
          style: GoogleFonts.notoSerif(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply to today\'s entry',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.primary.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 32),
        ...activeTriggers.map((trigger) {
          final trigId = trigger.id;
          final isSelected = _selectedTriggerIds.contains(trigId);
          final name = trigger.name;
          final desc = trigger.description;
          final icon = trigger.getIconData();
          final bg = trigger.getIconColor().withOpacity(0.1);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTriggerIds.remove(trigId);
                  } else {
                    _selectedTriggerIds.add(trigId);
                  }
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEDE8F4).withOpacity(0.4) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.primary.withOpacity(0.6),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        // custom trigger button
        SizedBox(
          width: double.infinity,
          height: 60,
          child: OutlinedButton(
            onPressed: () => context.push('/trigger-library'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD0C4BC)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Add Custom Influence',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- STEP 4: Trigger Details ---
  Widget _buildStep4TriggerDetails() {
    if (_selectedTriggerIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.playlist_add_check, size: 64, color: Color(0xFFD0C4BC)),
              const SizedBox(height: 16),
              Text(
                'No influences selected',
                style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Go back and select influences to details.',
                style: GoogleFonts.manrope(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Journal Your Influences',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Reflect on today\'s triggers',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        ..._selectedTriggerIds.map((trigId) {
          if (trigId == 't_caffeine') {
            return _buildCaffeineDetailCard();
          } else if (trigId == 't_alcohol') {
            return _buildAlcoholDetailCard();
          } else if (trigId == 't_stress') {
            return _buildStressDetailCard();
          } else if (trigId == 't_foods') {
            return _buildFoodsDetailCard();
          } else {
            return _buildCustomTriggerDetailCard(trigId);
          }
        }),
        const SizedBox(height: 20),
        // Reflection tip
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEDDDF5).withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb, color: AppTheme.primaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.5),
                    children: [
                      TextSpan(text: 'Pro Tip: ', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      const TextSpan(text: 'High sodium can increase water retention and worsen night sweats. Try reducing salt in your evening meals.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCaffeineDetailCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caffeine',
                    style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HOW MUCH TODAY?',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                ],
              ),
              const Icon(Icons.coffee, color: Color(0xFF9D675C)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5F0).withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_caffeineCups > 0) {
                      setState(() => _caffeineCups--);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.remove, color: AppTheme.primary),
                  ),
                ),
                Text(
                  '$_caffeineCups cups',
                  style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                GestureDetector(
                  onTap: () => setState(() => _caffeineCups++),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlcoholDetailCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alcohol',
                    style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CONSUMPTION LOG',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                ],
              ),
              const Icon(Icons.local_bar, color: Color(0xFF9D675C)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5F0).withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_alcoholGlasses > 0) {
                      setState(() => _alcoholGlasses--);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.remove, color: AppTheme.primary),
                  ),
                ),
                Text(
                  '$_alcoholGlasses glass',
                  style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                GestureDetector(
                  onTap: () => setState(() => _alcoholGlasses++),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressDetailCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stress',
                    style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'INTENSITY LEVEL',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                ],
              ),
              const Icon(Icons.psychology, color: Color(0xFF9D675C)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE2F5E2), // Soft Green (Calm)
                  Color(0xFFFFF1D0), // Soft Yellow/Orange (Moderate)
                  Color(0xFFFFE0E0), // Soft Red (High)
                ],
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Stack(
              children: [
                // White sliding thumb selector
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: _stressLevel == 'Calm'
                      ? Alignment.centerLeft
                      : _stressLevel == 'Moderate'
                          ? Alignment.center
                          : Alignment.centerRight,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.26,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                ),
                // Three Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _stressLevel = 'Calm'),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('😊', style: TextStyle(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text(
                                'Calm',
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _stressLevel == 'Calm' ? AppTheme.primary : const Color(0xFF8A817C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _stressLevel = 'Moderate'),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('😐', style: TextStyle(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text(
                                'Moderate',
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _stressLevel == 'Moderate' ? AppTheme.primary : const Color(0xFF8A817C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _stressLevel = 'High'),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('😟', style: TextStyle(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text(
                                'High',
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _stressLevel == 'High' ? AppTheme.primary : const Color(0xFF8A817C),
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildFoodsDetailCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foods',
                    style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SPECIFIC TRIGGERS?',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1),
                  ),
                ],
              ),
              AnimatedSwitch(
                value: _foodsTriggered,
                onChanged: (val) => setState(() => _foodsTriggered = val),
                activeColor: AppTheme.primary,
              ),
            ],
          ),
          if (_foodsTriggered) ...[
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _foodsNotes,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                hintText: 'Spicy foods, heavy dinner...',
              ),
              style: GoogleFonts.notoSerif(fontSize: 14, fontStyle: FontStyle.italic),
              maxLines: 2,
              onChanged: (val) => setState(() => _foodsNotes = val),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCustomTriggerDetailCard(String trigId) {
    final counter = _customTriggerCounters[trigId] ?? 1;
    final note = _customTriggerTexts[trigId] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trigId,
                style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
              ),
              const Icon(Icons.stars, color: Color(0xFF9D675C)),
            ],
          ),
          const SizedBox(height: 16),
          // simple increment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Occurrence Level:',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (counter > 1) {
                        setState(() => _customTriggerCounters[trigId] = counter - 1);
                      }
                    },
                  ),
                  Text('$counter times', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() => _customTriggerCounters[trigId] = counter + 1);
                    },
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: note,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              hintText: 'Add any details...',
            ),
            style: GoogleFonts.manrope(fontSize: 13),
            onChanged: (val) => setState(() => _customTriggerTexts[trigId] = val),
          ),
        ],
      ),
    );
  }

  // --- STEP 5: Final Review, Medications & Supplements ---
  Widget _buildStep5FinalConfirm() {
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
            border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildMedRow(
                title: 'Estradiol Patch',
                subtitle: '${_estradiolDose.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} $_estradiolUnit • $_estradiolTime',
                icon: Icons.medication,
                checked: _estradiolChecked,
                onCheckedChange: (val) => setState(() => _estradiolChecked = val!),
                onTap: () => setState(() => _estradiolChecked = !_estradiolChecked),
              ),
              if (_estradiolChecked) _buildInlineMedicationDetails('estradiol'),
              const Divider(color: Color(0xFFF2EDEA), height: 1),
              _buildMedRow(
                title: 'Progesterone',
                subtitle: '${_progesteroneDose.toStringAsFixed(0)} $_progesteroneUnit • $_progesteroneTime',
                icon: Icons.medication,
                checked: _progesteroneChecked,
                onCheckedChange: (val) => setState(() => _progesteroneChecked = val!),
                onTap: () => setState(() => _progesteroneChecked = !_progesteroneChecked),
              ),
              if (_progesteroneChecked) _buildInlineMedicationDetails('progesterone'),
            ],
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
            border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildSupplementRow(
                title: 'Daily Vitamin D',
                subtitle: '2000 IU • With Food',
                icon: Icons.spa,
                checked: _vitaminDChecked,
                onCheckedChange: (val) => setState(() => _vitaminDChecked = val!),
              ),
              const Divider(color: Color(0xFFF2EDEA), height: 1),
              _buildSupplementRow(
                title: 'Magnesium Glycinate',
                subtitle: '200 mg • Before Sleep',
                icon: Icons.spa,
                checked: _magnesiumChecked,
                onCheckedChange: (val) => setState(() => _magnesiumChecked = val!),
              ),
            ],
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
                      const Icon(Icons.brightness_3, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Sleep Duration', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('$_sleepDuration', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                      const SizedBox(width: 4),
                      Text('hrs', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.outline)),
                    ],
                  )
                ],
              ),
              Slider(
                value: _sleepDuration,
                min: 0,
                max: 12,
                divisions: 24,
                activeColor: AppTheme.primary,
                onChanged: (val) => setState(() => _sleepDuration = val),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Hydration', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('$_hydrationCups', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                      const SizedBox(width: 4),
                      Text('cups', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.outline)),
                    ],
                  )
                ],
              ),
              Slider(
                value: _hydrationCups.toDouble(),
                min: 0,
                max: 15,
                divisions: 15,
                activeColor: AppTheme.primary,
                onChanged: (val) => setState(() => _hydrationCups = val.toInt()),
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
          initialValue: _additionalNotes,
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFD0C4BC))),
            hintText: 'How are you feeling today? Any specific symptoms?',
            hintStyle: GoogleFonts.notoSerif(fontStyle: FontStyle.italic, color: Colors.grey.withOpacity(0.6)),
          ),
          style: GoogleFonts.manrope(fontSize: 14),
          onChanged: (val) => setState(() => _additionalNotes = val),
        ),
        const SizedBox(height: 32),
      ],
    );
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
    required String unit,
    required double currentDose,
    required ValueChanged<double> onDoseChanged,
  }) {
    final doses = _getAvailableDoses(unit);
    int initialIndex = doses.indexWhere((d) => (d - currentDose).abs() < 0.01);
    if (initialIndex == -1) initialIndex = 0;

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
                      Navigator.pop(context);
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
                    onDoseChanged(doses[index]);
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

  Widget _buildInlineMedicationDetails(String medKey) {
    bool isEstradiol = medKey == 'estradiol';
    double dose = isEstradiol ? _estradiolDose : _progesteroneDose;
    String unit = isEstradiol ? _estradiolUnit : _progesteroneUnit;
    String time = isEstradiol ? _estradiolTime : _progesteroneTime;
    
    // Dynamic unit options
    List<String> unitOptions = ['mg', 'mcg'];
    if (!unitOptions.contains(unit)) {
      unitOptions.add(unit);
    }
    final onboardingMeds = ref.read(medicationsProvider).medications;
    for (var m in onboardingMeds) {
      if (!unitOptions.contains(m.unit)) {
        unitOptions.add(m.unit);
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        unit: unit,
                        currentDose: dose,
                        onDoseChanged: (newDose) {
                          setState(() {
                            if (isEstradiol) {
                              _estradiolDose = newDose;
                            } else {
                              _progesteroneDose = newDose;
                            }
                          });
                        },
                      ),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.4)),
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
                        color: const Color(0xFFEDE7E5).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        children: unitOptions.map((opt) {
                          final isSelected = unit == opt;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isEstradiol) {
                                    _estradiolUnit = opt;
                                  } else {
                                    _progesteroneUnit = opt;
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  opt,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppTheme.primary : const Color(0xFF9B8B7E),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
                      onTap: () async {
                        final timeOfDay = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (timeOfDay != null) {
                          setState(() {
                            if (isEstradiol) {
                              _estradiolTime = timeOfDay.format(context);
                            } else {
                              _progesteroneTime = timeOfDay.format(context);
                            }
                          });
                        }
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD0C4BC).withOpacity(0.4)),
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
        ],
      ),
    );
  }

  Widget _buildMedRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool checked,
    required ValueChanged<bool?> onCheckedChange,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: const Color(0xFFEDDDF5).withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
      subtitle: Text(subtitle, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.outline)),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: checked ? AppTheme.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: checked ? null : Border.all(color: const Color(0xFFD0C4BC), width: 2),
        ),
        child: checked ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
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

  // --- FOOTER BUTTONS ---
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 4 ? 'Save Log' : 'Continue',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
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

  // --- STEP 6: Success Confirmation Overlay ---
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Stack(
        children: [
          // Background abstract radial bloom
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
                // Daily routine reminder cards
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
