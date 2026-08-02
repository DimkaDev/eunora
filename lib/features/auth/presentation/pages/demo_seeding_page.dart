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
import 'package:eunora/features/onboarding/presentation/providers/medications_provider.dart';

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

      // Step 3: Write user profile with full 90-day human HRT journey
      final now = DateTime.now();
      final ninetyDaysAgo = now.subtract(const Duration(days: 90));
      final sixtyDaysAgo = now.subtract(const Duration(days: 60));
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final profile = UserProfile(
        uid: user.uid,
        email: 'demo@eunora.test',
        age: 48,
        menopauseStage: MenopauseStage.irregular,
        yearsInStage: '2',
        selectedStageSymptoms: ['s_hot_flashes', 's_night_sweats', 's_sleep', 's_fatigue', 's_mood', 's_brain_fog'],
        medications: [
          Medication(
            id: 'med_estradiol',
            name: 'Estradiol Patch',
            type: MedicationType.patch,
            dose: 50.0,
            unit: 'mcg',
            frequency: 'Twice weekly',
            drugCategory: 'estrogen',
            isCombinedProduct: false,
            market: 'US',
            startedAt: ninetyDaysAgo,
          ),
          Medication(
            id: 'med_progesterone',
            name: 'Progesterone',
            type: MedicationType.pill,
            dose: 100.0,
            unit: 'mg',
            frequency: 'Daily',
            drugCategory: 'progestogen',
            isCombinedProduct: false,
            market: 'US',
            startedAt: ninetyDaysAgo,
          ),
          Medication(
            id: 'med_estradiol_cream',
            name: 'Estradiol Cream 0.01%',
            type: MedicationType.cream,
            dose: 0.5,
            unit: 'mg',
            frequency: 'Twice weekly',
            drugCategory: 'estrogen',
            isCombinedProduct: false,
            market: 'US',
            startedAt: thirtyDaysAgo,
          ),
        ],
        otherMedications: [
          OtherMedication(name: 'Vitamin D3', category: 'Supplement'),
          OtherMedication(name: 'Magnesium Glycinate', category: 'Supplement'),
        ],
        isOnboardingCompleted: true,
        createdAt: ninetyDaysAgo,
        updatedAt: now,
      );
      await userDoc.set(profile.toMap());

      // Step 4: Seed HRT dose change history (Dose increase from 25 to 50 mcg 60 days ago)
      _update('Adding HRT history & dose changes...', 0.15);
      final doseChange = HrtDoseChange(
        userId: user.uid,
        medicationId: 'med_estradiol',
        medicationName: 'Estradiol Patch',
        oldDose: 25.0,
        newDose: 50.0,
        unit: 'mcg',
        changeDate: sixtyDaysAgo,
      );
      await userDoc.collection('hrt_dose_changes').doc(doseChange.id).set(doseChange.toMap());

      // Step 5: Seed 91 days of realistic daily logs (write individually)
      final random = Random(42); // fixed seed for realistic reproducibility
      final totalDays = 91;

      // Available symptoms matching current app library
      final symptomsLib = [
        {'id': 's_hot_flashes', 'name': 'Hot flashes', 'iconName': 'thermostat', 'category': 'Vasomotor'},
        {'id': 's_night_sweats', 'name': 'Night sweats', 'iconName': 'water_drop', 'category': 'Vasomotor'},
        {'id': 's_sleep', 'name': 'Sleep problems', 'iconName': 'dark_mode', 'category': 'Sleep & Energy'},
        {'id': 's_fatigue', 'name': 'Fatigue', 'iconName': 'battery_low', 'category': 'Sleep & Energy'},
        {'id': 's_mood', 'name': 'Mood swings', 'iconName': 'mood', 'category': 'Emotional'},
        {'id': 's_brain_fog', 'name': 'Brain fog', 'iconName': 'psychology', 'category': 'Emotional'},
        {'id': 's_joint_pain', 'name': 'Joint pain', 'iconName': 'accessibility_new', 'category': 'Physical'},
      ];

      for (int i = 90; i >= 0; i--) {
        final dayIndex = 90 - i;
        final progressFraction = 0.15 + (dayIndex / totalDays) * 0.80;
        _update('Generating day ${dayIndex + 1} of $totalDays...', progressFraction);

        final logDate = DateTime.now().subtract(Duration(days: i));
        final logDateStr =
            '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';

        // Real-world human trends over 90 days:
        // Phase 1 (days 90-60 ago): Low HRT dose (25 mcg), high symptoms
        // Phase 2 (days 59-30 ago): Increased HRT dose (50 mcg), symptoms improving
        // Phase 3 (days 29-0 ago): Added Estradiol Cream, symptoms well-controlled
        final bool isPhase1 = i > 60;
        final bool isPhase2 = i <= 60 && i > 30;

        final hasAlcohol = random.nextDouble() < (isPhase1 ? 0.30 : 0.20);
        final hasCaffeine = random.nextDouble() < 0.50;
        final isHighStress = random.nextDouble() < (isPhase1 ? 0.45 : 0.25);
        final hasExercise = random.nextDouble() < (isPhase1 ? 0.25 : 0.45);

        final List<String> triggers = [];
        if (hasAlcohol) triggers.add('Alcohol');
        if (hasCaffeine) triggers.add('Caffeine');
        if (isHighStress) triggers.add('Stress');
        if (hasExercise) triggers.add('Exercise');

        // Choose random symptoms based on current treatment phase
        final int symptomCount = isPhase1 ? (random.nextInt(3) + 3) : (isPhase2 ? (random.nextInt(3) + 1) : (random.nextInt(2) + 1));
        final selectedSymptoms = (List<Map<String, dynamic>>.from(symptomsLib)..shuffle(random)).take(symptomCount).toList();

        final symptomsData = selectedSymptoms.map((sym) {
          final String id = sym['id']!;
          // Phase 1 has higher base intensity than Phase 2 & 3
          double baseIntensity = isPhase1 ? (random.nextInt(2) + 3.0) : (isPhase2 ? (random.nextInt(2) + 1.5) : (random.nextInt(2) + 1.0));

          if (id == 's_hot_flashes' && hasAlcohol) baseIntensity = max(1.0, min(5.0, baseIntensity + 1.5));
          if (id == 's_sleep' && hasCaffeine) baseIntensity = max(1.0, min(5.0, baseIntensity + 1.0));
          if (id == 's_mood' && isHighStress) baseIntensity = max(1.0, min(5.0, baseIntensity + 1.5));

          final String severity = baseIntensity >= 4.0 ? 'Severe' : (baseIntensity >= 2.5 ? 'Moderate' : 'Mild');
          final int duration = (random.nextInt(45) + 15);

          return {
            'id': id,
            'name': sym['name']!,
            'iconName': sym['iconName']!,
            'category': sym['category']!,
            'isCustom': false,
            'intensity': baseIntensity,
            'severity': severity,
            'durationMinutes': duration,
          };
        }).toList();

        // Active HRT intake for this specific historical day
        final double currentEstradiolDose = isPhase1 ? 25.0 : 50.0;
        final bool isTakenToday = random.nextDouble() < 0.95; // 95% realistic adherence

        final List<HrtIntakeLog> hrtIntakes = [
          HrtIntakeLog(
            medicationId: 'med_estradiol',
            name: 'Estradiol Patch',
            dose: currentEstradiolDose,
            unit: 'mcg',
            time: '08:30',
            isTaken: isTakenToday,
          ),
          HrtIntakeLog(
            medicationId: 'med_progesterone',
            name: 'Progesterone',
            dose: 100.0,
            unit: 'mg',
            time: '21:00',
            isTaken: isTakenToday,
          ),
        ];

        if (i <= 30) {
          hrtIntakes.add(HrtIntakeLog(
            medicationId: 'med_estradiol_cream',
            name: 'Estradiol Cream 0.01%',
            dose: 0.5,
            unit: 'mg',
            time: '21:30',
            isTaken: isTakenToday,
          ));
        }

        final double baseSleep = isHighStress ? 5.5 : (isPhase1 ? 6.2 : 7.8);
        final double sleepDuration = max(4.0, min(10.0, baseSleep + (random.nextDouble() * 1.5 - 0.75)));

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
          'estradiolChecked': isTakenToday,
          'estradiolDose': currentEstradiolDose,
          'estradiolUnit': 'mcg',
          'estradiolTime': '08:30',
          'progesteroneChecked': isTakenToday,
          'progesteroneDose': 100.0,
          'progesteroneUnit': 'mg',
          'progesteroneTime': '21:00',
          'vitaminDChecked': isTakenToday,
          'magnesiumChecked': isTakenToday,
          'sleepDuration': sleepDuration,
          'hydrationCups': 5 + random.nextInt(5),
          'additionalNotes': isPhase1 ? 'Persistent hot flashes at night.' : (isPhase2 ? 'Feeling much better on 50mcg.' : 'Feeling stable and well-rested.'),
          'hrtIntakes': hrtIntakes.map((h) => h.toMap()).toList(),
          'isCompleted': true,
          'lastCompletedStep': 5,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      // Step 6: Refresh Riverpod providers so UI immediately loads seeded data
      _update('Finalizing demo state...', 0.98);
      await ref.read(medicationsProvider.notifier).loadFromFirestore();

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
