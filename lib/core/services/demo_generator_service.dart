import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
import 'package:eunora/features/onboarding/domain/models/other_medication.dart';
import 'package:eunora/features/onboarding/domain/models/symptom.dart';
import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';

enum DemoPersona {
  demoA(
    id: 'demo_a',
    code: 'A',
    label: 'Try demo A (90 day sample data)',
    durationDays: 90,
    stage: MenopauseStage.irregular,
    description: 'Perimenopause, No HRT, Moderate-Confidence Correlation',
  ),
  demoB(
    id: 'demo_b',
    code: 'B',
    label: 'Try demo B (90 day sample data)',
    durationDays: 90,
    stage: MenopauseStage.noPeriod12Months,
    description: 'Menopause + HRT, Dose Change With Clear Before/After',
  ),
  demoC(
    id: 'demo_c',
    code: 'C',
    label: 'Try demo C (90 day sample data)',
    durationDays: 90,
    stage: MenopauseStage.postmenopause,
    description: 'Postmenopause, Long-Term Stable HRT, High-Confidence Correlations',
  ),
  demoD(
    id: 'demo_d',
    code: 'D',
    label: 'Try demo D (60 day sample data)',
    durationDays: 60,
    stage: MenopauseStage.surgical,
    description: 'Sparse/Inconsistent Logger, Mostly-Gated States (60 days)',
  );

  final String id;
  final String code;
  final String label;
  final int durationDays;
  final MenopauseStage stage;
  final String description;

  const DemoPersona({
    required this.id,
    required this.code,
    required this.label,
    required this.durationDays,
    required this.stage,
    required this.description,
  });

  static DemoPersona fromCode(String? code) {
    if (code == null) return DemoPersona.demoA;
    return DemoPersona.values.firstWhere(
      (p) => p.code.toUpperCase() == code.toUpperCase() || p.id.toLowerCase() == code.toLowerCase(),
      orElse: () => DemoPersona.demoA,
    );
  }
}

class DemoGeneratorService {
  const DemoGeneratorService();

  /// Completely clears prior demo data from Firestore and local cache before generating new persona data.
  Future<void> clearPriorData(DocumentReference userDoc) async {
    final dailyLogsSnap = await userDoc.collection('daily_logs').get();
    for (final doc in dailyLogsSnap.docs) {
      await doc.reference.delete();
    }

    final doseChangesSnap = await userDoc.collection('hrt_dose_changes').get();
    for (final doc in doseChangesSnap.docs) {
      await doc.reference.delete();
    }
  }

  /// Generates and writes the specified DemoPersona dataset following domain rules.
  Future<void> generatePersonaData({
    required User user,
    required DemoPersona persona,
    required Function(String status, double progress) onProgress,
  }) async {
    final db = FirebaseFirestore.instance;
    final userDoc = db.collection('users').doc(user.uid);

    onProgress('Clearing previous dataset...', 0.05);
    await clearPriorData(userDoc);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed_${user.uid}', true);
    await prefs.setString('active_demo_persona_${user.uid}', persona.id);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final totalDays = persona.durationDays;
    final startDate = today.subtract(Duration(days: totalDays - 1));

    onProgress('Setting up ${persona.code} profile & medications...', 0.12);

    // Build Profile & Medications per persona
    final profileData = _buildProfileForPersona(user.uid, persona, startDate, now);
    await userDoc.set(profileData.profile.toMap());

    // Insert dose changes (if any) using domain model
    for (final change in profileData.doseChanges) {
      await userDoc.collection('hrt_dose_changes').doc(change.id).set(change.toMap());
    }

    // Seed realistic, autocorrelated daily logs
    final logs = generateSyntheticDailyLogs(
      userId: user.uid,
      persona: persona,
      startDate: startDate,
      totalDays: totalDays,
    );

    for (int idx = 0; idx < logs.length; idx++) {
      final log = logs[idx];
      final frac = 0.15 + (idx / logs.length) * 0.80;
      if (idx % 5 == 0 || idx == logs.length - 1) {
        onProgress('Writing day ${idx + 1} of ${logs.length}...', frac);
      }

      final dateStr = '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}';
      await userDoc.collection('daily_logs').doc(dateStr).set(log.toMap());
    }

    onProgress('Finalizing ${persona.label}...', 0.98);
  }

  _PersonaProfileData _buildProfileForPersona(
    String userId,
    DemoPersona persona,
    DateTime startDate,
    DateTime now,
  ) {
    switch (persona) {
      case DemoPersona.demoA:
        // PROMPT A: Perimenopause, NOT on HRT.
        final profile = UserProfile(
          uid: userId,
          email: 'demo_a@eunora.test',
          age: 47,
          menopauseStage: MenopauseStage.irregular,
          yearsInStage: '2',
          selectedStageSymptoms: ['s_hot_flashes', 's_anxiety', 's_brain_fog', 's_sleep', 's_fatigue'],
          medications: const [], // Strict: Not on HRT
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: const []);

      case DemoPersona.demoB:
        // PROMPT B: Menopause + HRT, Dose change at day 42 (48 days ago from today).
        final day42Date = startDate.add(const Duration(days: 42));

        final estradiolPatch = Medication(
          id: 'med_estradiol_patch',
          name: 'Estradiol patch',
          type: MedicationType.patch,
          dose: 75.0, // Current active dose
          unit: 'mcg',
          frequency: 'Twice weekly',
          drugCategory: 'estrogen',
          isCombinedProduct: false,
          market: 'US',
          startedAt: startDate,
        );

        final utrogestanTablet = Medication(
          id: 'med_utrogestan',
          name: 'Utrogestan',
          type: MedicationType.pill,
          dose: 100.0,
          unit: 'mg',
          frequency: 'Daily',
          drugCategory: 'progestogen',
          isCombinedProduct: false,
          market: 'US',
          startedAt: startDate,
        );

        final doseChange = HrtDoseChange(
          userId: userId,
          medicationId: estradiolPatch.id,
          medicationName: 'Estradiol patch',
          oldDose: 50.0,
          newDose: 75.0,
          unit: 'mcg',
          changeDate: day42Date,
        );

        final profile = UserProfile(
          uid: userId,
          email: 'demo_b@eunora.test',
          age: 52,
          menopauseStage: MenopauseStage.noPeriod12Months,
          yearsInStage: '1',
          selectedStageSymptoms: ['s_hot_flashes', 's_night_sweats', 's_sleep', 's_joint_pain'],
          medications: [estradiolPatch, utrogestanTablet],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );

        return _PersonaProfileData(profile: profile, doseChanges: [doseChange]);

      case DemoPersona.demoC:
        // PROMPT C: Postmenopause, 6+ years. Long-term stable HRT (no dose change).
        final stableEstradiolPatch = Medication(
          id: 'med_estradiol_patch',
          name: 'Estradiol patch',
          type: MedicationType.patch,
          dose: 50.0,
          unit: 'mcg',
          frequency: 'Twice weekly',
          drugCategory: 'estrogen',
          isCombinedProduct: false,
          market: 'US',
          startedAt: now.subtract(const Duration(days: 730)), // Started 2 years ago
        );

        final profile = UserProfile(
          uid: userId,
          email: 'demo_c@eunora.test',
          age: 58,
          menopauseStage: MenopauseStage.postmenopause,
          yearsInStage: '6',
          selectedStageSymptoms: ['s_joint_pain', 's_sleep', 's_brain_fog', 's_hot_flashes'],
          medications: [stableEstradiolPatch],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );

        return _PersonaProfileData(profile: profile, doseChanges: const []);

      case DemoPersona.demoD:
        // PROMPT D: Surgical Menopause, 60 days total. Dose change 8 days ago.
        final eightDaysAgo = now.subtract(const Duration(days: 8));

        final estrogel = Medication(
          id: 'med_estrogel',
          name: 'EstroGel',
          type: MedicationType.gel,
          dose: 1.5, // changed from 0.75
          unit: 'mg',
          frequency: 'Daily',
          drugCategory: 'estrogen',
          isCombinedProduct: false,
          market: 'US',
          startedAt: startDate.add(const Duration(days: 5)),
        );

        final doseChange = HrtDoseChange(
          userId: userId,
          medicationId: estrogel.id,
          medicationName: 'EstroGel',
          oldDose: 0.75,
          newDose: 1.5,
          unit: 'mg',
          changeDate: eightDaysAgo,
        );

        final profile = UserProfile(
          uid: userId,
          email: 'demo_d@eunora.test',
          age: 44,
          menopauseStage: MenopauseStage.surgical,
          yearsInStage: '0',
          selectedStageSymptoms: ['s_hot_flashes', 's_mood', 's_fatigue'],
          medications: [estrogel],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );

        return _PersonaProfileData(profile: profile, doseChanges: [doseChange]);
    }
  }

  /// Pure deterministic generator producing realistic DailyLog objects.
  List<DailyLog> generateSyntheticDailyLogs({
    required String userId,
    required DemoPersona persona,
    required DateTime startDate,
    required int totalDays,
  }) {
    switch (persona) {
      case DemoPersona.demoA:
        return _generatePersonaALogs(userId, startDate, totalDays);
      case DemoPersona.demoB:
        return _generatePersonaBLogs(userId, startDate, totalDays);
      case DemoPersona.demoC:
        return _generatePersonaCLogs(userId, startDate, totalDays);
      case DemoPersona.demoD:
        return _generatePersonaDLogs(userId, startDate, totalDays);
    }
  }

  /// PROMPT A: Perimenopause, No HRT, Moderate-Confidence Correlation (90 days)
  /// - ~85% logged days (~76-77 days logged), scattered gaps
  /// - Mostly evening timestamps (8-10pm: 20:00-22:00)
  /// - Cycle: irregular bleeding every ~12-16 days, lasting 2-3 days
  /// - Hot flashes intensity 2-4 most days (occasional 5)
  /// - Work stress -> same-day anxiety: exactly 9 paired events, ~68% correlation
  /// - No HRT intakes
  List<DailyLog> _generatePersonaALogs(String userId, DateTime startDate, int totalDays) {
    final rand = Random(4201); // Deterministic seed
    final logs = <DailyLog>[];

    // Pick 13 unlogged days scattered across 90 days (~85.5% logged = 77 logged days)
    final unloggedIndices = {6, 13, 20, 26, 34, 43, 49, 58, 65, 72, 79, 85, 89};

    // Cycle: irregular bleeding every 12-16 days, lasting 2-3 days
    // Day ranges: 10-12 (3 days), 25-27 (3 days), 39-40 (2 days), 54-56 (3 days), 68-70 (3 days), 83-84 (2 days)
    final bleedingDays = {10, 11, 12, 25, 26, 27, 39, 40, 54, 55, 56, 68, 69, 70, 83, 84};

    // Seed exactly 9 work-stress days (weekdays) where anxiety jumps to 5.0
    final workStressDays = {4, 15, 22, 32, 45, 53, 61, 74, 82};

    // AR(1) smooth state for hot flashes
    double hfState = 3.0;
    int moderateAnxietyAdded = 0;

    for (int dayIdx = 0; dayIdx < totalDays; dayIdx++) {
      if (unloggedIndices.contains(dayIdx)) continue;

      final calendarDate = startDate.add(Duration(days: dayIdx));
      final weekday = calendarDate.weekday; // 1=Mon..7=Sun
      final isWorkday = weekday >= DateTime.monday && weekday <= DateTime.thursday;

      // Autoregressive hot flash streak
      hfState = 0.65 * hfState + 0.35 * (2.2 + rand.nextDouble() * 1.8) + (rand.nextDouble() * 0.3 - 0.15);
      final double hfScore = hfState.clamp(2.0, 4.8);

      final symptoms = <LoggedSymptom>[];

      // Hot Flashes (baseline 2-4, occasional 5)
      symptoms.add(LoggedSymptom(
        symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat'),
        severity: _scoreToLabel(hfScore),
        intensity: hfScore.round(),
        durationMinutes: 15 + (hfScore * 6).round(),
      ));

      // Irregular cycle bleeding (every 12-16 days, lasting 2-3 days)
      if (bleedingDays.contains(dayIdx)) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'bleeding', name: 'Bleeding', iconName: 'water_drop', category: 'Cycle'),
          severity: 'Moderate',
          intensity: 3,
        ));
      }

      // Brain fog logged often
      if (dayIdx % 3 == 0 || dayIdx % 5 == 0) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'brain_fog', name: 'Brain Fog', iconName: 'psychology'),
          severity: 'Moderate',
          intensity: 3,
        ));
      }

      // Target correlation: work stress -> same-day anxiety
      // On 9 work stress days: anxiety = 5.0 (Severe).
      // On 25 non-stress days: anxiety = 3.0 (Moderate) to land correlation at ~68%
      final bool hasWorkStress = workStressDays.contains(dayIdx);
      final List<String> triggers = [];
      if (hasWorkStress) {
        triggers.add('Stress · Work');
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'anxiety', name: 'Anxiety', iconName: 'psychology'),
          severity: 'Severe',
          intensity: 5,
        ));
      } else {
        // Background anxiety: logged on exactly 25 non-stress days with Moderate intensity
        if (moderateAnxietyAdded < 25 && dayIdx % 3 == 0) {
          symptoms.add(LoggedSymptom(
            symptom: const Symptom(id: 'anxiety', name: 'Anxiety', iconName: 'psychology'),
            severity: 'Moderate',
            intensity: 3,
          ));
          moderateAnxietyAdded++;
        }
      }

      // Mediocre sleep quality (2-3/5, 6.0-6.7 hours)
      final double sleepHours = double.parse((6.1 + rand.nextDouble() * 0.6).toStringAsFixed(1));

      // Mostly evening timestamps (8-10pm: 20:00-22:00)
      final hour = 20 + rand.nextInt(2); // 20 or 21
      final minute = rand.nextInt(60);
      final logTimestamp = DateTime(calendarDate.year, calendarDate.month, calendarDate.day, hour, minute);

      logs.add(DailyLog(
        id: '${calendarDate.year}-${calendarDate.month.toString().padLeft(2, '0')}-${calendarDate.day.toString().padLeft(2, '0')}',
        userId: userId,
        date: calendarDate,
        isCompleted: true,
        symptoms: symptoms,
        triggers: triggers,
        sleepDuration: sleepHours,
        hrtIntakes: const [], // Strict: No HRT intakes
        createdAt: logTimestamp,
      ));
    }

    return logs;
  }

  /// PROMPT B: Menopause + HRT, Dose Change With Clear Before/After (90 days)
  /// - ~90% logged days (~81 days logged)
  /// - Morning timestamps for medication (08:00), evening for symptom log (20:30)
  /// - Estradiol increased 50mcg -> 75mcg at day 42
  /// - Hot flashes ~8/day (or high severity) before day 42, dropping to ~3/day (mild) after
  /// - Sleep quality improves from 5.8h to 7.8h
  /// - Independent missed doses on Estradiol and Utrogestan
  List<DailyLog> _generatePersonaBLogs(String userId, DateTime startDate, int totalDays) {
    final rand = Random(4202);
    final logs = <DailyLog>[];

    // Pick 9 unlogged days scattered (~90% logged = 81 days)
    final unloggedIndices = {7, 18, 29, 38, 48, 59, 68, 78, 87};

    // Independent missed doses
    final missedEstradiolDays = {14, 31, 55, 73}; // 4 missed doses (~95% adherence)
    final missedUtrogestanDays = {10, 24, 46, 67, 83}; // 5 missed doses (~94% adherence)

    for (int dayIdx = 0; dayIdx < totalDays; dayIdx++) {
      if (unloggedIndices.contains(dayIdx)) continue;

      final calendarDate = startDate.add(Duration(days: dayIdx));
      final bool isBeforeChange = dayIdx < 42;

      // Before change: high hot flashes (severity 4.2), poor sleep (5.8h)
      // After change: mild hot flashes (severity 1.3), good sleep (7.8h)
      final double hfScore;
      final double sleepHours;
      if (isBeforeChange) {
        hfScore = (4.0 + rand.nextDouble() * 0.8).clamp(3.5, 5.0);
        sleepHours = double.parse((5.6 + rand.nextDouble() * 0.6).toStringAsFixed(1));
      } else {
        hfScore = (1.0 + rand.nextDouble() * 0.8).clamp(1.0, 2.0);
        sleepHours = double.parse((7.5 + rand.nextDouble() * 0.6).toStringAsFixed(1));
      }

      final symptoms = <LoggedSymptom>[
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat'),
          severity: _scoreToLabel(hfScore),
          intensity: hfScore.round(),
          durationMinutes: isBeforeChange ? 35 : 10,
        ),
      ];

      if (isBeforeChange) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'night_sweats', name: 'Night Sweats', iconName: 'water_drop'),
          severity: 'Moderate',
          intensity: 3,
        ));
      }

      // HRT Intakes with independent adherence
      final double estradiolDose = isBeforeChange ? 50.0 : 75.0;
      final bool takenEstradiol = !missedEstradiolDays.contains(dayIdx);
      final bool takenUtrogestan = !missedUtrogestanDays.contains(dayIdx);

      final hrtIntakes = [
        HrtIntakeLog(
          medicationId: 'med_estradiol_patch',
          name: 'Estradiol patch',
          dose: estradiolDose,
          unit: 'mcg',
          time: '08:00',
          isTaken: takenEstradiol,
        ),
        HrtIntakeLog(
          medicationId: 'med_utrogestan',
          name: 'Utrogestan',
          dose: 100.0,
          unit: 'mg',
          time: '08:30',
          isTaken: takenUtrogestan,
        ),
      ];

      // Evening timestamp for symptom log (20:30-21:30)
      final hour = 20 + rand.nextInt(2);
      final minute = 15 + rand.nextInt(40);
      final logTimestamp = DateTime(calendarDate.year, calendarDate.month, calendarDate.day, hour, minute);

      logs.add(DailyLog(
        id: '${calendarDate.year}-${calendarDate.month.toString().padLeft(2, '0')}-${calendarDate.day.toString().padLeft(2, '0')}',
        userId: userId,
        date: calendarDate,
        isCompleted: true,
        symptoms: symptoms,
        triggers: const [],
        sleepDuration: sleepHours,
        hrtIntakes: hrtIntakes,
        createdAt: logTimestamp,
      ));
    }

    return logs;
  }

  /// PROMPT C: Postmenopause, Long-Term Stable HRT, High-Confidence Correlations (90 days)
  /// - ~90% logged days (~81 days logged), mixed morning/evening timestamps
  /// - Stable HRT: Estradiol patch 50mcg (high adherence ~95%, 1-2 missed doses)
  /// - Joint pain & sleep disturbance flat-to-worsening across full 90 days
  /// - Red wine (15 paired events) -> next-day hot flash (~78% correlation, High confidence chip)
  /// - Exercise 30+ min (10-11 events) -> same-day hot flash reduction (~73% correlation, protective)
  List<DailyLog> _generatePersonaCLogs(String userId, DateTime startDate, int totalDays) {
    final rand = Random(4203);
    final logs = <DailyLog>[];

    final unloggedIndices = {8, 19, 28, 39, 49, 59, 69, 79, 88};

    // Exactly 15 red wine days in the evening (paired next-day hot flash spike)
    final redWineDays = {3, 9, 14, 21, 26, 33, 40, 46, 52, 57, 63, 70, 75, 81, 86};

    // Exactly 11 exercise 30+ min days (protective same-day)
    final exerciseDays = {5, 11, 17, 23, 31, 37, 44, 50, 66, 72, 84};

    // Only 2 missed doses across 90 days (~97.5% adherence)
    final missedDoseDays = {25, 61};

    for (int dayIdx = 0; dayIdx < totalDays; dayIdx++) {
      if (unloggedIndices.contains(dayIdx)) continue;

      final calendarDate = startDate.add(Duration(days: dayIdx));
      final bool prevHadRedWine = redWineDays.contains(dayIdx - 1);
      final bool hasExercise = exerciseDays.contains(dayIdx);
      final bool hasRedWine = redWineDays.contains(dayIdx);

      // Persistent symptoms: joint pain & sleep disturbance flat-to-worsening
      // Progression: early days 2.5, late days 3.5
      final double progression = dayIdx / totalDays; // 0.0 to 1.0
      final double jointScore = (2.4 + progression * 1.1 + (rand.nextDouble() * 0.4 - 0.2)).clamp(2.0, 4.5);
      final double sleepHours = (6.8 - progression * 0.8 + (rand.nextDouble() * 0.4 - 0.2)).clamp(5.0, 7.5);

      // Hot Flashes:
      // Wine effect: 14 days Severe (5.0), 1 day Moderate (3.0) -> exactly 78% correlation!
      // Exercise protective effect: Mild (1.0) -> ~73% protective correlation!
      // Baseline: Moderate (3.0).
      double hfScore;
      if (prevHadRedWine) {
        if (dayIdx == 4) {
          hfScore = 3.0;
        } else {
          hfScore = 5.0;
        }
      } else if (hasExercise) {
        hfScore = 1.0;
      } else {
        hfScore = 3.0;
      }

      final symptoms = <LoggedSymptom>[
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat'),
          severity: _scoreToLabel(hfScore),
          intensity: hfScore.round(),
          durationMinutes: (hfScore * 7).round(),
        ),
        LoggedSymptom(
          symptom: const Symptom(id: 'joint_pain', name: 'Joint Pain', iconName: 'accessibility_new'),
          severity: _scoreToLabel(jointScore),
          intensity: jointScore.round(),
        ),
        LoggedSymptom(
          symptom: const Symptom(id: 'night_wakings', name: 'Night Wakings', iconName: 'dark_mode'),
          severity: sleepHours < 6.0 ? 'Moderate' : 'Mild',
          intensity: sleepHours < 6.0 ? 3 : 1,
        ),
      ];

      final triggers = <String>[];
      if (hasRedWine) {
        triggers.add('Alcohol · 1 drink'); // Normalized as alcohol
      }
      if (hasExercise) {
        triggers.add('Exercise · 35 min'); // Normalized as exercise
      }

      // Adherence: stable Estradiol patch 50mcg
      final bool isTaken = !missedDoseDays.contains(dayIdx);
      final hrtIntakes = [
        HrtIntakeLog(
          medicationId: 'med_estradiol_patch',
          name: 'Estradiol patch',
          dose: 50.0,
          unit: 'mcg',
          time: '08:30',
          isTaken: isTaken,
        ),
      ];

      // Mixed morning / evening timestamps
      final int hour = rand.nextBool() ? 8 : 20;
      final int minute = rand.nextInt(60);
      final logTimestamp = DateTime(calendarDate.year, calendarDate.month, calendarDate.day, hour, minute);

      logs.add(DailyLog(
        id: '${calendarDate.year}-${calendarDate.month.toString().padLeft(2, '0')}-${calendarDate.day.toString().padLeft(2, '0')}',
        userId: userId,
        date: calendarDate,
        isCompleted: true,
        symptoms: symptoms,
        triggers: triggers,
        sleepDuration: double.parse(sleepHours.toStringAsFixed(1)),
        hrtIntakes: hrtIntakes,
        createdAt: logTimestamp,
      ));
    }

    return logs;
  }

  /// PROMPT D: Sparse/Inconsistent Logger, Mostly-Gated States (60 days)
  /// - Only roughly 20-25 days logged (large multi-day gaps)
  /// - Dose change happened 8 days before today (in-progress countdown)
  /// - Trigger seeded at exactly 5 paired events (sub-7 progress state)
  /// - Adherence: ~70-75% with multiple visibly missed doses
  /// - Passport shows days-to-go based on logged days count (< 30)
  List<DailyLog> _generatePersonaDLogs(String userId, DateTime startDate, int totalDays) {
    final rand = Random(4204);
    final logs = <DailyLog>[];

    // Total 60 calendar days (day 0 to 59).
    // Dose change at day 51 (8 days before day 59).
    // Baseline window: 14 days before day 51 -> days 37 to 50.
    // Need >= 7 logged days in baseline window to pass baseline check!
    // Pick 8 days in 37..50: {37, 39, 41, 43, 45, 47, 49, 50}
    // Days 0..36: 9 sparse logged days: {2, 6, 11, 16, 21, 25, 29, 32, 35}
    // Days 52..59: 5 follow-up logged days: {52, 54, 56, 58, 59}
    // Total logged days = 9 + 8 + 5 = 22 days (in 20-25 range, < 30 for Passport "8 days to go")
    final loggedIndices = {
      2, 6, 11, 16, 21, 25, 29, 32, 35, // 9 days before baseline window
      37, 39, 41, 43, 45, 47, 49, 50,   // 8 days in baseline window (>= 7)
      52, 54, 56, 58, 59,               // 5 days in follow-up window
    };

    // Seed a trigger (e.g. coffee) on exactly 5 logged days (sub-7 progress state)
    final coffeeDays = {6, 21, 37, 45, 54};

    // Noticeably lower adherence (~72.7%): 6 missed doses out of 22 logged days
    final missedDoseDays = {11, 25, 37, 43, 52, 58};

    for (int dayIdx = 0; dayIdx < totalDays; dayIdx++) {
      if (!loggedIndices.contains(dayIdx)) continue;

      final calendarDate = startDate.add(Duration(days: dayIdx));
      final bool isAfterDoseChange = dayIdx >= 51; // 8 days before end

      final double hfScore = (2.5 + rand.nextDouble() * 1.5).clamp(2.0, 4.5);
      final symptoms = <LoggedSymptom>[
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat'),
          severity: _scoreToLabel(hfScore),
          intensity: hfScore.round(),
        ),
      ];

      final triggers = <String>[];
      if (coffeeDays.contains(dayIdx)) {
        triggers.add('Coffee / Caffeine · 2 cups');
      }

      // HRT: EstroGel 0.75 mg before day 52, 1.5 mg after
      final double gelDose = isAfterDoseChange ? 1.5 : 0.75;
      final bool isTaken = !missedDoseDays.contains(dayIdx);

      final hrtIntakes = [
        HrtIntakeLog(
          medicationId: 'med_estrogel',
          name: 'EstroGel',
          dose: gelDose,
          unit: 'mg',
          time: '09:00',
          isTaken: isTaken,
        ),
      ];

      final int hour = 11 + rand.nextInt(10);
      final int minute = rand.nextInt(60);
      final logTimestamp = DateTime(calendarDate.year, calendarDate.month, calendarDate.day, hour, minute);

      logs.add(DailyLog(
        id: '${calendarDate.year}-${calendarDate.month.toString().padLeft(2, '0')}-${calendarDate.day.toString().padLeft(2, '0')}',
        userId: userId,
        date: calendarDate,
        isCompleted: true,
        symptoms: symptoms,
        triggers: triggers,
        sleepDuration: 6.5,
        hrtIntakes: hrtIntakes,
        createdAt: logTimestamp,
      ));
    }

    return logs;
  }

  static double _clampScore(double score) => max(0.0, min(5.0, score));

  static String _scoreToLabel(double score) {
    if (score >= 3.8) return 'Severe';
    if (score >= 2.0) return 'Moderate';
    return 'Mild';
  }
}

class _PersonaProfileData {
  final UserProfile profile;
  final List<HrtDoseChange> doseChanges;

  const _PersonaProfileData({required this.profile, required this.doseChanges});
}
