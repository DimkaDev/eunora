import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eunora/core/theme/app_theme.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/onboarding/domain/models/other_medication.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';

class DemoSeedingPage extends ConsumerStatefulWidget {
  const DemoSeedingPage({super.key});

  @override
  ConsumerState<DemoSeedingPage> createState() => _DemoSeedingPageState();
}

class _DemoSeedingPageState extends ConsumerState<DemoSeedingPage> {
  String _statusText = 'Signing in...';
  double _progress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSeeding());
  }

  Future<void> _runSeeding() async {
    try {
      // Step 1: Sign in anonymously
      _update('Signing in anonymously...', 0.05);
      final credential = await FirebaseAuth.instance.signInAnonymously();
      final user = credential.user;
      if (user == null) throw Exception('Anonymous sign-in failed');

      // Step 2: Mark onboarding complete
      _update('Setting up demo profile...', 0.1);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed_${user.uid}', true);

      final db = FirebaseFirestore.instance;
      final userDoc = db.collection('users').doc(user.uid);

      // Step 3: Write user profile
      final profile = UserProfile(
        uid: user.uid,
        email: 'demo@eunora.test',
        age: 45,
        menopauseStage: MenopauseStage.irregular,
        yearsInStage: '2',
        selectedStageSymptoms: ['s_hot_flashes', 's_mood', 's_sleep', 's_dryness', 's_joint_pain'],
        medications: [
          Medication(
            id: 'med_estradiol',
            name: 'Estradiol Patch',
            type: MedicationType.patch,
            dose: 50.0,
            unit: 'mcg',
            frequency: 'Twice weekly',
          ),
          Medication(
            id: 'med_progesterone',
            name: 'Progesterone',
            type: MedicationType.pill,
            dose: 100.0,
            unit: 'mg',
            frequency: 'Daily',
          ),
        ],
        otherMedications: [
          OtherMedication(name: 'Vitamin D3', category: 'Supplement'),
          OtherMedication(name: 'Magnesium', category: 'Supplement'),
        ],
        isOnboardingCompleted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await userDoc.set(profile.toMap());

      // Step 4: Seed dose change
      _update('Adding HRT history...', 0.15);
      final doseChange = HrtDoseChange(
        userId: user.uid,
        medicationId: 'med_estradiol',
        medicationName: 'Estradiol Patch',
        oldDose: 25.0,
        newDose: 50.0,
        unit: 'mcg',
        changeDate: DateTime.now().subtract(const Duration(days: 45)),
      );
      await userDoc.collection('hrt_dose_changes').doc(doseChange.id).set(doseChange.toMap());

      // Step 5: Seed 91 days of logs (write individually to avoid batch limits)
      final random = Random(42); // fixed seed for reproducibility
      final totalDays = 91;

      // Available symptoms for diverse logging
      final symptomsLib = [
        {'id': 's_hot_flashes', 'name': 'Hot Flashes', 'iconName': 'thermostat', 'category': 'Vasomotor Symptoms'},
        {'id': 's_sleep', 'name': 'Sleep quality', 'iconName': 'dark_mode', 'category': 'Sleep & Energy'},
        {'id': 's_mood', 'name': 'Mood swings', 'iconName': 'mood', 'category': 'Emotional & Cognitive'},
        {'id': 's_anxiety', 'name': 'Anxiety', 'iconName': 'psychology', 'category': 'Emotional & Cognitive'},
        {'id': 's_irritability', 'name': 'Irritability', 'iconName': 'sentiment_dissatisfied', 'category': 'Emotional & Cognitive'},
        {'id': 's_joint_pain', 'name': 'Joint pain', 'iconName': 'accessibility_new', 'category': 'Physical Wellbeing'},
        {'id': 's_headaches', 'name': 'Headaches', 'iconName': 'skull', 'category': 'Physical Wellbeing'},
        {'id': 's_fatigue', 'name': 'Fatigue', 'iconName': 'battery_low', 'category': 'Physical Wellbeing'},
      ];

      for (int i = 90; i >= 0; i--) {
        final dayIndex = 90 - i;
        final progressFraction = 0.15 + (dayIndex / totalDays) * 0.85;
        _update('Generating day ${dayIndex + 1} of $totalDays...', progressFraction);

        final logDate = DateTime.now().subtract(Duration(days: i));
        final logDateStr =
            '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';

        // Triggers and logic
        final hasAlcohol = random.nextDouble() < 0.25;
        final hasCaffeine = random.nextDouble() < 0.55;
        final isHighStress = random.nextDouble() < 0.40;
        final hasExercise = random.nextDouble() < 0.35;
        final isDehydrated = random.nextDouble() < 0.20;

        final List<String> triggers = [];
        if (hasAlcohol) triggers.add('Alcohol: ${random.nextInt(2) + 1} glasses');
        if (hasCaffeine) triggers.add('Caffeine: ${random.nextInt(3) + 1} cups');
        if (isHighStress) triggers.add('Stress');
        if (hasExercise) triggers.add('Exercise: 30+ min');
        if (isDehydrated) triggers.add('Dehydration');

        // Choose 2 to 7 random symptoms to report today
        final int symptomCount = random.nextInt(6) + 2; // 2 to 7 symptoms
        final selectedSymptoms = (List<Map<String, dynamic>>.from(symptomsLib)..shuffle(random)).take(symptomCount).toList();

        final symptomsData = selectedSymptoms.map((sym) {
          final String id = sym['id']!;
          double intensity = random.nextInt(3) + 1.0; // default mild-mod 1-3

          // Add realistic correlations:
          if (id == 's_hot_flashes' && hasAlcohol) intensity = random.nextInt(2) + 4.0; // severe 4-5
          if (id == 's_sleep' && hasCaffeine) intensity = random.nextInt(2) + 3.0;
          if (id == 's_mood' && isHighStress) intensity = random.nextInt(2) + 4.0;
          if (id == 's_hot_flashes' && hasExercise) intensity = max(1.0, intensity - 1.5); // exercise decreases flashes

          final String severity = intensity >= 4.0 ? 'Severe' : (intensity >= 2.5 ? 'Moderate' : 'Mild');
          final int duration = (random.nextInt(45) + 15); // 15 to 60 mins duration

          return {
            'id': id,
            'name': sym['name']!,
            'iconName': sym['iconName']!,
            'category': sym['category']!,
            'isCustom': false,
            'intensity': intensity,
            'severity': severity,
            'durationMinutes': duration,
          };
        }).toList();

        // Stable HRT dose - change dose from 25 to 50 mcg on day 45 (45 days ago)
        final bool beforeDoseChange = i > 45;
        final double currentEstradiolDose = beforeDoseChange ? 25.0 : 50.0;

        final hrtIntakes = [
          HrtIntakeLog(
            medicationId: 'med_estradiol',
            name: 'Estradiol Patch',
            dose: currentEstradiolDose,
            unit: 'mcg',
            time: '08:30 AM',
            isTaken: true,
          ),
          HrtIntakeLog(
            medicationId: 'med_progesterone',
            name: 'Progesterone',
            dose: 100.0,
            unit: 'mg',
            time: '08:00 PM',
            isTaken: true,
          ),
        ];

        // Diverse sleep hours
        final double baseSleep = isHighStress ? 5.5 : 7.5;
        final double sleepDuration = baseSleep + (random.nextDouble() * 2.0 - 1.0); // jitter sleep

        await userDoc.collection('daily_logs').doc(logDateStr).set({
          'id': logDateStr,
          'userId': user.uid,
          'date': logDate.toIso8601String(),
          'symptoms': symptomsData,
          'triggers': triggers,
          'caffeineCups': hasCaffeine ? random.nextInt(3) + 1 : 0,
          'alcoholGlasses': hasAlcohol ? random.nextInt(2) + 1 : 0,
          'stressLevel': isHighStress ? 'High' : 'Low',
          'foodsTriggered': false,
          'foodsNotes': '',
          'customTriggerCounters': {},
          'customTriggerTexts': {},
          'estradiolChecked': true,
          'estradiolDose': currentEstradiolDose,
          'estradiolUnit': 'mcg',
          'estradiolTime': '08:30 AM',
          'progesteroneChecked': true,
          'progesteroneDose': 100.0,
          'progesteroneUnit': 'mg',
          'progesteroneTime': '08:00 PM',
          'vitaminDChecked': true,
          'magnesiumChecked': true,
          'sleepDuration': sleepDuration,
          'hydrationCups': 5 + random.nextInt(5),
          'additionalNotes': 'Auto-generated demo log.',
          'hrtIntakes': hrtIntakes.map((h) => h.toMap()).toList(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      _update('Done! Opening your demo...', 1.0);
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed: $e\n\nCheck Firestore rules allow anonymous users.';
        });
      }
    }
  }

  void _update(String text, double progress) {
    if (mounted) {
      setState(() {
        _statusText = text;
        _progress = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.science_outlined, size: 36, color: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Setting Up Demo',
                style: GoogleFonts.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generating 90 days of realistic data\nfor Insights & Passport testing',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: const Color(0xFF6E3E3E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/signin'),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusText,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
