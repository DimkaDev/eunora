import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eunora/features/onboarding/domain/models/user_profile.dart';
import 'package:eunora/features/onboarding/domain/models/medication.dart';
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
  ),

  // ============ 11 Manual Test Scenarios (MenoSync_Manual_Test_Scenarios.md) ============
  scenario1(
    id: 'scenario_1',
    code: '1',
    label: 'Scenario 1 (7 days) — Floor / Baseline',
    durationDays: 7,
    stage: MenopauseStage.noPeriod12Months,
    description: 'Menopause, Estradiol 50mcg, no change, 3/7 stress events, passport locked (23d left)',
  ),
  scenario2(
    id: 'scenario_2',
    code: '2',
    label: 'Scenario 2 (15 days) — HRT < 14d Baseline',
    durationDays: 15,
    stage: MenopauseStage.noPeriod12Months,
    description: 'HRT 50mcg -> 75mcg on Day 8, unreachable before-window (7d), passport locked (15d left)',
  ),
  scenario3(
    id: 'scenario_3',
    code: '3',
    label: 'Scenario 3 (30 days) — HRT 14/14 Boundary',
    durationDays: 30,
    stage: MenopauseStage.noPeriod12Months,
    description: 'HRT 50mcg -> 75mcg on Day 15, 14/14d unlocked, 9 wine events, passport unlocked',
  ),
  scenario4(
    id: 'scenario_4',
    code: '4',
    label: 'Scenario 4 (30 days) — Perimenopause No HRT',
    durationDays: 30,
    stage: MenopauseStage.irregular,
    description: 'Perimenopause, no HRT, exactly 7 stress events, bleeding days 1-3 & 15-16, stable HF',
  ),
  scenario5(
    id: 'scenario_5',
    code: '5',
    label: 'Scenario 5 (60 days) — High Conf & Worsening',
    durationDays: 60,
    stage: MenopauseStage.postmenopause,
    description: 'Stable HRT, 14 wine events (High Conf chip), 10 exercise events, worsening step Day 31',
  ),
  scenario6(
    id: 'scenario_6',
    code: '6',
    label: 'Scenario 6 (60 days) — Sparse (26/60 days)',
    durationDays: 60,
    stage: MenopauseStage.surgical,
    description: '26 logged days, passport 4 days to go, dose change Day 52 countdown, 6 stress events',
  ),
  scenario7(
    id: 'scenario_7',
    code: '7',
    label: 'Scenario 7 (30 days) — Symptom Diversity',
    durationDays: 30,
    stage: MenopauseStage.postmenopause,
    description: 'Progynova 1mg, Fatigue(30)>Irritability(15)>Dryness(10)>Fog(9)>Headache(8)>Mood(5)',
  ),
  scenario8(
    id: 'scenario_8',
    code: '8',
    label: 'Scenario 8 (15 days) — Weekday vs Frequency',
    durationDays: 15,
    stage: MenopauseStage.noPeriod12Months,
    description: 'Utrogestan twice-weekly: Day 6 weekday change (no divider), Day 12 freq change (divider)',
  ),
  scenario9(
    id: 'scenario_9',
    code: '9',
    label: 'Scenario 9 (20 days) — Duplicate & Deletion',
    durationDays: 20,
    stage: MenopauseStage.noPeriod12Months,
    description: 'Evorel 50mcg soft-stop Day 8 & resume Day 15, Evorel 75mcg history deletion lock',
  ),
  scenario10(
    id: 'scenario_10',
    code: '10',
    label: 'Scenario 10 (30 days) — PCOS Mode',
    durationDays: 30,
    stage: MenopauseStage.pcos,
    description: 'PCOS stage, bleeding days 1-5, 25-day gap without atypical cycle warning, no HRT',
  ),
  scenario11(
    id: 'scenario_11',
    code: '11',
    label: 'Scenario 11 (60 days) — Gel + Ring, Soft-Stop',
    durationDays: 60,
    stage: MenopauseStage.postmenopause,
    description: 'Gel soft-stop Day 30 & resume Day 45, Ring continuous, 20 coffee days with weak correlation',
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

  bool get isLegacyDemo =>
      this == DemoPersona.demoA ||
      this == DemoPersona.demoB ||
      this == DemoPersona.demoC ||
      this == DemoPersona.demoD;

  bool get isScenario => !isLegacyDemo;

  int? get scenarioNumber {
    if (!isScenario) return null;
    final numStr = code.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numStr);
  }

  static List<DemoPersona> get manualScenarios =>
      values.where((p) => p.isScenario).toList();

  static DemoPersona fromCode(String? code) {
    if (code == null) return DemoPersona.demoA;
    final clean = code.trim().toLowerCase();
    return DemoPersona.values.firstWhere(
      (p) =>
          p.code.toLowerCase() == clean ||
          p.id.toLowerCase() == clean ||
          p.name.toLowerCase() == clean ||
          clean == 'scenario_${p.code.toLowerCase()}' ||
          clean == 'scenario${p.code.toLowerCase()}' ||
          clean == 's${p.code.toLowerCase()}',
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

    // Seed realistic / deterministic daily logs
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
        final profile = UserProfile(
          uid: userId,
          email: 'demo_a@eunora.test',
          age: 47,
          menopauseStage: MenopauseStage.irregular,
          yearsInStage: '2',
          selectedStageSymptoms: ['s_hot_flashes', 's_anxiety', 's_brain_fog', 's_sleep', 's_fatigue'],
          medications: const [],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: const []);

      case DemoPersona.demoB:
        final day42Date = startDate.add(const Duration(days: 42));
        final estradiolPatch = Medication(
          id: 'med_estradiol_patch',
          name: 'Estradiol patch',
          type: MedicationType.patch,
          dose: 75.0,
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
          startedAt: now.subtract(const Duration(days: 730)),
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
        final eightDaysAgo = now.subtract(const Duration(days: 8));
        final estrogel = Medication(
          id: 'med_estrogel',
          name: 'EstroGel',
          type: MedicationType.gel,
          dose: 1.5,
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

      // ============ 11 Manual Test Scenarios ============
      case DemoPersona.scenario1:
        // Scenario 1: Menopause, Estradiol patch 50mcg daily, started Day 1, no dose change.
        final med = Medication(
          id: 'med_estradiol_patch_50',
          name: 'Estradiol patch',
          type: MedicationType.patch,
          dose: 50.0,
          unit: 'mcg',
          frequency: 'Daily',
          drugCategory: 'systemicEstrogen',
          startedAt: startDate,
        );
        final profile = UserProfile(
          uid: userId,
          email: 'scenario_1@menoxync.test',
          age: 52,
          menopauseStage: MenopauseStage.noPeriod12Months,
          yearsInStage: '1',
          selectedStageSymptoms: ['hot_flash', 'night_sweats', 'anxiety'],
          medications: [med],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: const []);

      case DemoPersona.scenario2:
        // Scenario 2: Menopause, Estradiol 50mcg Days 1–7, change to 75mcg on Day 8 (changeDate = Day 8).
        final day8Date = startDate.add(const Duration(days: 7)); // Day 8 (0-indexed day 7)
        final med = Medication(
          id: 'med_estradiol_patch',
          name: 'Estradiol patch',
          type: MedicationType.patch,
          dose: 75.0,
          unit: 'mcg',
          frequency: 'Daily',
          drugCategory: 'systemicEstrogen',
          startedAt: startDate,
        );
        final doseChange = HrtDoseChange(
          userId: userId,
          medicationId: med.id,
          medicationName: 'Estradiol patch',
          oldDose: 50.0,
          newDose: 75.0,
          unit: 'mcg',
          changeDate: day8Date,
          changeType: RegimenChangeType.doseChange,
        );
        final profile = UserProfile(
          uid: userId,
          email: 'scenario_2@menoxync.test',
          age: 52,
          menopauseStage: MenopauseStage.noPeriod12Months,
          yearsInStage: '1',
          selectedStageSymptoms: ['hot_flash'],
          medications: [med],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: [doseChange]);

      case DemoPersona.scenario3:
        // Scenario 3: Menopause, Estradiol 50mcg Days 1–14, change to 75mcg on Day 15 (changeDate = Day 15).
        final day15Date = startDate.add(const Duration(days: 14)); // Day 15 (0-indexed day 14)
        final med = Medication(
          id: 'med_estradiol_patch',
          name: 'Estradiol patch',
          type: MedicationType.patch,
          dose: 75.0,
          unit: 'mcg',
          frequency: 'Daily',
          drugCategory: 'systemicEstrogen',
          startedAt: startDate,
        );
        final doseChange = HrtDoseChange(
          userId: userId,
          medicationId: med.id,
          medicationName: 'Estradiol patch',
          oldDose: 50.0,
          newDose: 75.0,
          unit: 'mcg',
          changeDate: day15Date,
          changeType: RegimenChangeType.doseChange,
        );
        final profile = UserProfile(
          uid: userId,
          email: 'scenario_3@menoxync.test',
          age: 52,
          menopauseStage: MenopauseStage.noPeriod12Months,
          yearsInStage: '1',
          selectedStageSymptoms: ['hot_flash'],
          medications: [med],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: [doseChange]);

      case DemoPersona.scenario4:
        // Scenario 4: Perimenopause without HRT.
        final profile = UserProfile(
          uid: userId,
          email: 'scenario_4@menoxync.test',
          age: 47,
          menopauseStage: MenopauseStage.irregular,
          yearsInStage: '2',
          selectedStageSymptoms: ['hot_flash', 'anxiety', 'bleeding'],
          medications: const [],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: const []);

      case DemoPersona.scenario5:
        // Scenario 5: Postmenopause, stable HRT all 60 days, no dose change.
        final med = Medication(
          id: 'med_estradiol_patch',
          name: 'Estradiol patch',
          type: MedicationType.patch,
          dose: 50.0,
          unit: 'mcg',
          frequency: 'Daily',
          drugCategory: 'systemicEstrogen',
          startedAt: startDate.subtract(const Duration(days: 365)),
        );
        final profile = UserProfile(
          uid: userId,
          email: 'scenario_5@menoxync.test',
          age: 58,
          menopauseStage: MenopauseStage.postmenopause,
          yearsInStage: '5',
          selectedStageSymptoms: ['hot_flash', 'joint_pain'],
          medications: [med],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: const []);

      case DemoPersona.scenario6:
        // Scenario 6: Surgical menopause, Estradiol patch 50mcg, change to 75mcg on Day 52.
        final day52Date = startDate.add(const Duration(days: 51)); // Day 52 (0-indexed day 51)
        final med = Medication(
          id: 'med_estradiol_patch',
          name: 'Estradiol patch',
          type: MedicationType.patch,
          dose: 75.0,
          unit: 'mcg',
          frequency: 'Daily',
          drugCategory: 'systemicEstrogen',
          startedAt: startDate,
        );
        final doseChange = HrtDoseChange(
          userId: userId,
          medicationId: med.id,
          medicationName: 'Estradiol patch',
          oldDose: 50.0,
          newDose: 75.0,
          unit: 'mcg',
          changeDate: day52Date,
          changeType: RegimenChangeType.doseChange,
        );
        final profile = UserProfile(
          uid: userId,
          email: 'scenario_6@menoxync.test',
          age: 46,
          menopauseStage: MenopauseStage.surgical,
          yearsInStage: '1',
          selectedStageSymptoms: ['hot_flash', 'anxiety'],
          medications: [med],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: [doseChange]);

      case DemoPersona.scenario7:
        // Scenario 7: Postmenopause, Progynova (tablet) 1mg, daily, no dose change.
        final med = Medication(
          id: 'med_progynova',
          name: 'Progynova',
          type: MedicationType.pill,
          dose: 1.0,
          unit: 'mg',
          frequency: 'Daily',
          drugCategory: 'systemicEstrogen',
          startedAt: startDate,
        );
        final profile = UserProfile(
          uid: userId,
          email: 'scenario_7@menoxync.test',
          age: 55,
          menopauseStage: MenopauseStage.postmenopause,
          yearsInStage: '4',
          selectedStageSymptoms: ['fatigue', 'irritability', 'skin_dryness', 'brain_fog', 'headache', 'low_mood'],
          medications: [med],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: const []);

      case DemoPersona.scenario8:
        // Scenario 8: Utrogestan 100mg, twice-weekly Day 1-5, Day 6 weekday change, Day 12 freq change.
        final day6Date = startDate.add(const Duration(days: 5));
        final day12Date = startDate.add(const Duration(days: 11));
        final med = Medication(
          id: 'med_utrogestan',
          name: 'Utrogestan',
          type: MedicationType.pill,
          dose: 100.0,
          unit: 'mg',
          frequency: 'Weekly',
          drugCategory: 'progestogen',
          startedAt: startDate,
        );
        final scheduleChange = HrtDoseChange(
          userId: userId,
          medicationId: med.id,
          medicationName: 'Utrogestan',
          oldDose: 100.0,
          newDose: 100.0,
          unit: 'mg',
          changeDate: day6Date,
          changeType: RegimenChangeType.scheduleDayChange,
          previousValue: 'Mon, Thu',
          newValue: 'Tue, Fri',
        );
        final freqChange = HrtDoseChange(
          userId: userId,
          medicationId: med.id,
          medicationName: 'Utrogestan',
          oldDose: 100.0,
          newDose: 100.0,
          unit: 'mg',
          changeDate: day12Date,
          changeType: RegimenChangeType.frequencyChange,
          previousValue: 'Twice weekly',
          newValue: 'Weekly',
        );
        final profile = UserProfile(
          uid: userId,
          email: 'scenario_8@menoxync.test',
          age: 52,
          menopauseStage: MenopauseStage.noPeriod12Months,
          yearsInStage: '1',
          selectedStageSymptoms: ['hot_flash'],
          medications: [med],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: [scheduleChange, freqChange]);

      case DemoPersona.scenario9:
        // Scenario 9: Evorel patch 75mcg active (started Day 5), Evorel 50mcg resumed Day 15.
        final day5Date = startDate.add(const Duration(days: 4));
        final day15Date = startDate.add(const Duration(days: 14));
        final evorel75 = Medication(
          id: 'med_evorel_75',
          name: 'Evorel patch',
          type: MedicationType.patch,
          dose: 75.0,
          unit: 'mcg',
          frequency: 'Weekly',
          drugCategory: 'systemicEstrogen',
          startedAt: day5Date,
        );
        final evorel50 = Medication(
          id: 'med_evorel_50',
          name: 'Evorel patch',
          type: MedicationType.patch,
          dose: 50.0,
          unit: 'mcg',
          frequency: 'Weekly',
          drugCategory: 'systemicEstrogen',
          startedAt: day15Date,
        );
        final profile = UserProfile(
          uid: userId,
          email: 'scenario_9@menoxync.test',
          age: 52,
          menopauseStage: MenopauseStage.noPeriod12Months,
          yearsInStage: '1',
          selectedStageSymptoms: ['hot_flash'],
          medications: [evorel75, evorel50],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: const []);

      case DemoPersona.scenario10:
        // Scenario 10: PCOS stage, no HRT configured.
        final profile = UserProfile(
          uid: userId,
          email: 'scenario_10@menoxync.test',
          age: 31,
          menopauseStage: MenopauseStage.pcos,
          yearsInStage: '3',
          selectedStageSymptoms: ['anxiety', 'brain_fog', 'hot_flash', 'bleeding'],
          medications: const [],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: const []);

      case DemoPersona.scenario11:
        // Scenario 11: Medication A (Estradiol gel 1.5mg) + Medication B (Vaginal ring 2mg).
        final gel = Medication(
          id: 'med_estradiol_gel',
          name: 'Estradiol gel',
          type: MedicationType.gel,
          dose: 1.5,
          unit: 'mg',
          frequency: 'Daily',
          drugCategory: 'systemicEstrogen',
          startedAt: startDate,
        );
        final ring = Medication(
          id: 'med_vaginal_ring',
          name: 'Vaginal ring',
          type: MedicationType.ring,
          dose: 2.0,
          unit: 'mg',
          frequency: 'Monthly',
          drugCategory: 'localEstrogen',
          startedAt: startDate,
        );
        final profile = UserProfile(
          uid: userId,
          email: 'scenario_11@menoxync.test',
          age: 56,
          menopauseStage: MenopauseStage.postmenopause,
          yearsInStage: '3',
          selectedStageSymptoms: ['irritability'],
          medications: [gel, ring],
          otherMedications: const [],
          isOnboardingCompleted: true,
          createdAt: startDate,
          updatedAt: now,
        );
        return _PersonaProfileData(profile: profile, doseChanges: const []);
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
      case DemoPersona.scenario1:
        return _generateScenario1Logs(userId, startDate, totalDays);
      case DemoPersona.scenario2:
        return _generateScenario2Logs(userId, startDate, totalDays);
      case DemoPersona.scenario3:
        return _generateScenario3Logs(userId, startDate, totalDays);
      case DemoPersona.scenario4:
        return _generateScenario4Logs(userId, startDate, totalDays);
      case DemoPersona.scenario5:
        return _generateScenario5Logs(userId, startDate, totalDays);
      case DemoPersona.scenario6:
        return _generateScenario6Logs(userId, startDate, totalDays);
      case DemoPersona.scenario7:
        return _generateScenario7Logs(userId, startDate, totalDays);
      case DemoPersona.scenario8:
        return _generateScenario8Logs(userId, startDate, totalDays);
      case DemoPersona.scenario9:
        return _generateScenario9Logs(userId, startDate, totalDays);
      case DemoPersona.scenario10:
        return _generateScenario10Logs(userId, startDate, totalDays);
      case DemoPersona.scenario11:
        return _generateScenario11Logs(userId, startDate, totalDays);
    }
  }

  // =========================================================================
  // Standard helper for deterministic logging in Scenarios 1–11
  // =========================================================================
  static DailyLog _buildLog({
    required String userId,
    required DateTime calendarDate,
    List<LoggedSymptom> symptoms = const [],
    List<String> triggers = const [],
    double sleepDuration = 6.5,
    int sleepQuality = 3,
    String moodCategory = 'Okay',
    int moodScore = 3,
    String stressLevel = 'Moderate',
    int alcoholGlasses = 0,
    int caffeineCups = 0,
    List<HrtIntakeLog> hrtIntakes = const [],
    Map<String, int> customCounters = const {},
    Map<String, String> customTexts = const {},
    String additionalNotes = '',
  }) {
    final dateStr =
        '${calendarDate.year}-${calendarDate.month.toString().padLeft(2, '0')}-${calendarDate.day.toString().padLeft(2, '0')}';
    final logTimestamp = DateTime(calendarDate.year, calendarDate.month, calendarDate.day, 21, 0);

    final sleepDurationStr = sleepDuration.toStringAsFixed(
        sleepDuration.truncateToDouble() == sleepDuration ? 0 : 1);
    final mergedCustomTexts = <String, String>{
      'sleep_info': '$sleepDurationStr hours · quality $sleepQuality/5',
      'mood_info': '$moodCategory · $moodScore/5',
      ...customTexts,
    };

    return DailyLog(
      id: dateStr,
      userId: userId,
      date: calendarDate,
      isCompleted: true,
      symptoms: symptoms,
      triggers: triggers,
      caffeineCups: caffeineCups,
      alcoholGlasses: alcoholGlasses,
      stressLevel: stressLevel,
      customTriggerCounters: customCounters,
      customTriggerTexts: mergedCustomTexts,
      sleepDuration: sleepDuration,
      hrtIntakes: hrtIntakes,
      additionalNotes: additionalNotes,
      createdAt: logTimestamp,
    );
  }

  // =========================================================================
  // 11 DETERMINISTIC SCENARIO LOG GENERATORS
  // =========================================================================

  /// Сценарий 1 — 7 дней — «Пол» (везде недостаточно данных)
  List<DailyLog> _generateScenario1Logs(String userId, DateTime startDate, int totalDays) {
    final logs = <DailyLog>[];
    for (int i = 0; i < totalDays; i++) {
      final calendarDate = startDate.add(Duration(days: i));
      final dayNumber = i + 1;
      final isStressDay = (dayNumber == 2 || dayNumber == 4 || dayNumber == 6);

      final hrtIntakes = [
        HrtIntakeLog(
          medicationId: 'med_estradiol_patch_50',
          name: 'Estradiol patch',
          dose: 50.0,
          unit: 'mcg',
          time: '08:30 AM',
          isTaken: true,
        ),
      ];

      final symptoms = [
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat', category: 'Vasomotor'),
          severity: 'Moderate',
          intensity: 2,
          durationMinutes: 10,
        ),
        LoggedSymptom(
          symptom: const Symptom(id: 'night_sweats', name: 'Night Sweats', iconName: 'water_drop', category: 'Vasomotor'),
          severity: 'Mild',
          intensity: 1,
        ),
        LoggedSymptom(
          symptom: const Symptom(id: 'anxiety', name: 'Anxiety', iconName: 'psychology', category: 'Mood / Cognitive'),
          severity: isStressDay ? 'Severe' : 'Mild',
          intensity: isStressDay ? 3 : 1,
        ),
      ];

      logs.add(_buildLog(
        userId: userId,
        calendarDate: calendarDate,
        symptoms: symptoms,
        triggers: isStressDay ? const ['Stress'] : const [],
        sleepDuration: 6.0,
        sleepQuality: 3,
        moodCategory: isStressDay ? 'Stressed' : 'Good',
        moodScore: isStressDay ? 2 : 4,
        stressLevel: isStressDay ? 'High' : 'Moderate',
        hrtIntakes: hrtIntakes,
      ));
    }
    return logs;
  }

  /// Сценарий 2 — 15 дней — HRT: недостижимый порог (обе стороны < 14 дней)
  List<DailyLog> _generateScenario2Logs(String userId, DateTime startDate, int totalDays) {
    final logs = <DailyLog>[];
    for (int i = 0; i < totalDays; i++) {
      final calendarDate = startDate.add(Duration(days: i));
      final dayNumber = i + 1;
      final isBefore = dayNumber < 8; // Days 1-7 before Day 8 divider

      final currentDose = isBefore ? 50.0 : 75.0;
      final hfOccurrences = isBefore ? 5 : 2;

      final hrtIntakes = [
        HrtIntakeLog(
          medicationId: 'med_estradiol_patch',
          name: 'Estradiol patch',
          dose: currentDose,
          unit: 'mcg',
          time: '08:30 AM',
          isTaken: true,
        ),
      ];

      final symptoms = [
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat', category: 'Vasomotor'),
          severity: 'Moderate',
          intensity: 2,
          durationMinutes: 10,
        ),
      ];

      logs.add(_buildLog(
        userId: userId,
        calendarDate: calendarDate,
        symptoms: symptoms,
        triggers: const [],
        sleepDuration: 6.5,
        sleepQuality: 3,
        moodCategory: 'Okay',
        moodScore: 3,
        hrtIntakes: hrtIntakes,
        customCounters: {'hot_flash_occurrences': hfOccurrences, 'hot_flash_count': hfOccurrences},
      ));
    }
    return logs;
  }

  /// Сценарий 3 — 30 дней — HRT: точная граница 14/14 дней + умеренная корреляция
  List<DailyLog> _generateScenario3Logs(String userId, DateTime startDate, int totalDays) {
    final logs = <DailyLog>[];
    final wineDays = {3, 6, 9, 12, 15, 18, 21, 24, 27};
    final spikeDays = {4, 7, 10, 13, 16, 19, 22, 25, 28};

    for (int i = 0; i < totalDays; i++) {
      final calendarDate = startDate.add(Duration(days: i));
      final dayNumber = i + 1;
      final isBeforeChange = dayNumber < 15;
      final hasWine = wineDays.contains(dayNumber);
      final isSpikeDay = spikeDays.contains(dayNumber);

      final currentDose = isBeforeChange ? 50.0 : 75.0;
      final int hfOccurrences;
      if (isBeforeChange) {
        hfOccurrences = isSpikeDay ? 9 : 6;
      } else {
        hfOccurrences = isSpikeDay ? 5 : 2;
      }

      final hrtIntakes = [
        HrtIntakeLog(
          medicationId: 'med_estradiol_patch',
          name: 'Estradiol patch',
          dose: currentDose,
          unit: 'mcg',
          time: '08:30 AM',
          isTaken: true,
        ),
      ];

      final symptoms = [
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat', category: 'Vasomotor'),
          severity: isSpikeDay ? 'Severe' : 'Moderate',
          intensity: isSpikeDay ? 3 : 2,
          durationMinutes: 10,
        ),
      ];

      logs.add(_buildLog(
        userId: userId,
        calendarDate: calendarDate,
        symptoms: symptoms,
        triggers: hasWine ? const ['Wine'] : const [],
        alcoholGlasses: hasWine ? 1 : 0,
        sleepDuration: 6.5,
        sleepQuality: 3,
        moodCategory: 'Okay',
        moodScore: 3,
        hrtIntakes: hrtIntakes,
        customCounters: {'hot_flash_occurrences': hfOccurrences, 'hot_flash_count': hfOccurrences},
      ));
    }
    return logs;
  }

  /// Сценарий 4 — 30 дней — Перименопауза без HRT, граница ровно 7 событий
  List<DailyLog> _generateScenario4Logs(String userId, DateTime startDate, int totalDays) {
    final logs = <DailyLog>[];
    final stressDays = {4, 8, 12, 16, 20, 24, 28}; // exactly 7 events
    final highAnxietyDays = {5, 9, 13, 17, 21, 25, 29};
    final mediumBleedingDays = {1, 2, 3};
    final lightBleedingDays = {15, 16};

    for (int i = 0; i < totalDays; i++) {
      final calendarDate = startDate.add(Duration(days: i));
      final dayNumber = i + 1;
      final hasStress = stressDays.contains(dayNumber);
      final hasHighAnxiety = highAnxietyDays.contains(dayNumber);

      final symptoms = <LoggedSymptom>[
        // Flat severity 2 across all 30 days -> trend "Stable"
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat', category: 'Vasomotor'),
          severity: 'Moderate',
          intensity: 2,
          durationMinutes: 10,
        ),
        LoggedSymptom(
          symptom: const Symptom(id: 'anxiety', name: 'Anxiety', iconName: 'psychology', category: 'Mood / Cognitive'),
          severity: hasHighAnxiety ? 'Severe' : 'Mild',
          intensity: hasHighAnxiety ? 3 : 1,
        ),
      ];

      if (mediumBleedingDays.contains(dayNumber)) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'bleeding', name: 'Bleeding', iconName: 'water_drop', category: 'Cycle'),
          severity: 'Moderate',
          intensity: 2,
        ));
      } else if (lightBleedingDays.contains(dayNumber)) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'bleeding', name: 'Bleeding', iconName: 'water_drop', category: 'Cycle'),
          severity: 'Mild',
          intensity: 1,
        ));
      }

      logs.add(_buildLog(
        userId: userId,
        calendarDate: calendarDate,
        symptoms: symptoms,
        triggers: hasStress ? const ['Stress'] : const [],
        stressLevel: hasStress ? 'High' : 'Moderate',
        sleepDuration: 6.5,
        sleepQuality: 3,
        moodCategory: hasHighAnxiety ? 'Anxious' : 'Okay',
        moodScore: hasHighAnxiety ? 2 : 3,
        hrtIntakes: const [], // Strict: No HRT
      ));
    }
    return logs;
  }

  /// Сценарий 5 — 60 дней — Постменопауза, стабильная HRT, high-confidence + позитивная корреляция
  List<DailyLog> _generateScenario5Logs(String userId, DateTime startDate, int totalDays) {
    final logs = <DailyLog>[];
    final wineDays = {4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56}; // 14 wine days
    final spikeDays = {5, 9, 13, 17, 21, 25, 29, 33, 37, 41, 45, 49, 53, 57}; // 14 spike days
    final exerciseDays = {2, 6, 14, 18, 26, 30, 38, 42, 50, 54}; // 10 exercise days
    final missedDoseDays = {20, 45}; // 2 missed doses -> 58/60 adherence

    for (int i = 0; i < totalDays; i++) {
      final calendarDate = startDate.add(Duration(days: i));
      final dayNumber = i + 1;
      final hasWine = wineDays.contains(dayNumber);
      final isSpikeDay = spikeDays.contains(dayNumber);
      final hasExercise = exerciseDays.contains(dayNumber);
      final isMissedDose = missedDoseDays.contains(dayNumber);
      final isWorseningPhase = dayNumber >= 31; // Step on Day 31!

      final hrtIntakes = [
        HrtIntakeLog(
          medicationId: 'med_estradiol_patch',
          name: 'Estradiol patch',
          dose: 50.0,
          unit: 'mcg',
          time: '08:30 AM',
          isTaken: !isMissedDose,
        ),
      ];

      // HF: 1 vs 3 contrast on wine days (High confidence chip)
      // Exercise: duration drops from 10 to 5 min
      final int hfSev = isSpikeDay ? 3 : 1;
      final String hfSevLabel = isSpikeDay ? 'Severe' : 'Mild';
      final int hfDuration = hasExercise ? 5 : 10;

      final symptoms = <LoggedSymptom>[
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat', category: 'Vasomotor'),
          severity: hfSevLabel,
          intensity: hfSev,
          durationMinutes: hfDuration,
        ),
        LoggedSymptom(
          symptom: const Symptom(id: 'joint_pain', name: 'Joint Pain', iconName: 'accessibility_new', category: 'Physical'),
          severity: isWorseningPhase ? 'Severe' : 'Moderate',
          intensity: isWorseningPhase ? 3 : 2,
        ),
      ];

      final triggers = <String>[];
      if (hasWine) triggers.add('Wine');
      if (hasExercise) triggers.add('Exercise · 30 min');

      final customCounters = <String, int>{};
      if (hasExercise) {
        customCounters['t_exercise'] = 30;
        customCounters['exercise'] = 30;
      }

      logs.add(_buildLog(
        userId: userId,
        calendarDate: calendarDate,
        symptoms: symptoms,
        triggers: triggers,
        alcoholGlasses: hasWine ? 1 : 0,
        sleepDuration: 6.0,
        sleepQuality: isWorseningPhase ? 2 : 4, // Step from 4 to 2 on Day 31
        moodCategory: isWorseningPhase ? 'Low' : 'Good',
        moodScore: isWorseningPhase ? 2 : 4,
        hrtIntakes: hrtIntakes,
        customCounters: customCounters,
      ));
    }
    return logs;
  }

  /// Сценарий 6 — 60 дней — Разреженное логирование, logged days ≠ calendar days (26/60 days)
  List<DailyLog> _generateScenario6Logs(String userId, DateTime startDate, int totalDays) {
    final logs = <DailyLog>[];
    final loggedDays = {
      1, 2, 3, 4, 5, 6, 7,
      16, 17, 18, 19, 20,
      31, 32, 33, 34, 35,
      46, 47, 48, 49, 50, 51,
      52,
      59, 60,
    }; // exactly 26 logged days

    final stressDays = {2, 17, 33, 47, 49, 60}; // 6 stress days
    final highAnxietyDays = {3, 18, 34, 48, 50}; // 5 high anxiety days

    for (int i = 0; i < totalDays; i++) {
      final dayNumber = i + 1;
      if (!loggedDays.contains(dayNumber)) continue; // unlogged calendar days

      final calendarDate = startDate.add(Duration(days: i));
      final hasStress = stressDays.contains(dayNumber);
      final hasHighAnxiety = highAnxietyDays.contains(dayNumber);
      final isAfterDoseChange = dayNumber >= 52; // divider at Day 52

      final currentDose = isAfterDoseChange ? 75.0 : 50.0;
      final hrtIntakes = [
        HrtIntakeLog(
          medicationId: 'med_estradiol_patch',
          name: 'Estradiol patch',
          dose: currentDose,
          unit: 'mcg',
          time: '08:30 AM',
          isTaken: true,
        ),
      ];

      final symptoms = [
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat', category: 'Vasomotor'),
          severity: 'Moderate',
          intensity: 2,
          durationMinutes: 10,
        ),
        LoggedSymptom(
          symptom: const Symptom(id: 'anxiety', name: 'Anxiety', iconName: 'psychology', category: 'Mood / Cognitive'),
          severity: hasHighAnxiety ? 'Severe' : 'Mild',
          intensity: hasHighAnxiety ? 3 : 1,
        ),
      ];

      logs.add(_buildLog(
        userId: userId,
        calendarDate: calendarDate,
        symptoms: symptoms,
        triggers: hasStress ? const ['Stress'] : const [],
        stressLevel: hasStress ? 'High' : 'Moderate',
        sleepDuration: 6.0,
        sleepQuality: 3,
        moodCategory: 'Okay',
        moodScore: 3,
        hrtIntakes: hrtIntakes,
      ));
    }
    return logs;
  }

  /// Сценарий 7 — 30 дней — Разнообразие симптомов + Coffee/Weather (Postmenopause, Progynova)
  List<DailyLog> _generateScenario7Logs(String userId, DateTime startDate, int totalDays) {
    final logs = <DailyLog>[];
    final coffeeDays = {2, 5, 8, 11, 14, 17, 20, 23}; // 8 days
    final weatherDays = {3, 6, 9, 12, 15, 18, 21, 24, 27}; // 9 days
    final irritabilityDays = {2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30}; // 15 days
    final drynessDays = {3, 6, 9, 12, 15, 18, 21, 24, 27, 30}; // 10 days
    final brainFogDays = {4, 7, 10, 13, 16, 19, 22, 25, 28}; // 9 days
    final headacheDays = {2, 5, 8, 11, 14, 17, 20, 23}; // 8 days
    final lowMoodDays = {5, 10, 15, 20, 25}; // 5 days

    for (int i = 0; i < totalDays; i++) {
      final calendarDate = startDate.add(Duration(days: i));
      final dayNumber = i + 1;

      final hasCoffee = coffeeDays.contains(dayNumber);
      final hasWeather = weatherDays.contains(dayNumber);
      final hasIrritability = irritabilityDays.contains(dayNumber);
      final hasDryness = drynessDays.contains(dayNumber);
      final hasBrainFog = brainFogDays.contains(dayNumber);
      final hasHeadache = headacheDays.contains(dayNumber);
      final hasLowMood = lowMoodDays.contains(dayNumber);

      final hrtIntakes = [
        HrtIntakeLog(
          medicationId: 'med_progynova',
          name: 'Progynova',
          dose: 1.0,
          unit: 'mg',
          time: '08:30 AM',
          isTaken: true,
        ),
      ];

      final symptoms = <LoggedSymptom>[
        // Fatigue present on all 30 days, flat severity 2 -> trend "Stable"
        LoggedSymptom(
          symptom: const Symptom(id: 'fatigue', name: 'Fatigue', iconName: 'battery_low', category: 'Physical'),
          severity: 'Moderate',
          intensity: 2,
        ),
      ];

      if (hasIrritability) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'irritability', name: 'Irritability', iconName: 'sentiment_dissatisfied', category: 'Mood / Cognitive'),
          severity: 'Mild',
          intensity: 1,
        ));
      }
      if (hasDryness) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'skin_dryness', name: 'Skin Dryness', iconName: 'dry_cleaning', category: 'Physical'),
          severity: 'Mild',
          intensity: 1,
        ));
      }
      if (hasBrainFog) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'brain_fog', name: 'Brain Fog', iconName: 'cloud', category: 'Mood / Cognitive'),
          severity: 'Severe',
          intensity: 3,
        ));
      }
      if (hasHeadache) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'headache', name: 'Headache', iconName: 'bolt', category: 'Physical'),
          severity: 'Severe',
          intensity: 3,
        ));
      }
      if (hasLowMood) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'low_mood', name: 'Low Mood', iconName: 'sentiment_dissatisfied', category: 'Mood / Cognitive'),
          severity: 'Mild',
          intensity: 1,
        ));
      }

      final triggers = <String>[];
      if (hasCoffee) triggers.add('Coffee');
      if (hasWeather) triggers.add('Weather');

      logs.add(_buildLog(
        userId: userId,
        calendarDate: calendarDate,
        symptoms: symptoms,
        triggers: triggers,
        caffeineCups: hasCoffee ? 2 : 0,
        sleepDuration: 6.5,
        sleepQuality: 3,
        moodCategory: hasLowMood ? 'Low' : 'Okay',
        moodScore: hasLowMood ? 2 : 3,
        hrtIntakes: hrtIntakes,
      ));
    }
    return logs;
  }

  /// Сценарий 8 — 15 дней — Weekday-only vs Frequency change (два разных тира)
  List<DailyLog> _generateScenario8Logs(String userId, DateTime startDate, int totalDays) {
    final logs = <DailyLog>[];
    final utrogestanDays = {1, 4, 8, 11, 15};

    for (int i = 0; i < totalDays; i++) {
      final calendarDate = startDate.add(Duration(days: i));
      final dayNumber = i + 1;
      final isUtrogestanDay = utrogestanDays.contains(dayNumber);

      final hrtIntakes = isUtrogestanDay
          ? [
              HrtIntakeLog(
                medicationId: 'med_utrogestan',
                name: 'Utrogestan',
                dose: 100.0,
                unit: 'mg',
                time: '08:00 PM',
                isTaken: true,
              ),
            ]
          : <HrtIntakeLog>[];

      final symptoms = [
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat', category: 'Vasomotor'),
          severity: 'Moderate',
          intensity: 2,
          durationMinutes: 10,
        ),
      ];

      logs.add(_buildLog(
        userId: userId,
        calendarDate: calendarDate,
        symptoms: symptoms,
        triggers: const [],
        sleepDuration: 6.0,
        sleepQuality: 3,
        moodCategory: 'Okay',
        moodScore: 3,
        hrtIntakes: hrtIntakes,
      ));
    }
    return logs;
  }

  /// Сценарий 9 — 20 дней — Три уровня duplicate detection + правила удаления
  List<DailyLog> _generateScenario9Logs(String userId, DateTime startDate, int totalDays) {
    final logs = <DailyLog>[];

    for (int i = 0; i < totalDays; i++) {
      final calendarDate = startDate.add(Duration(days: i));
      final dayNumber = i + 1;

      final hrtIntakes = <HrtIntakeLog>[];
      // Day 1: Evorel 50mcg
      if (dayNumber == 1) {
        hrtIntakes.add(HrtIntakeLog(
          medicationId: 'med_evorel_50',
          name: 'Evorel patch',
          dose: 50.0,
          unit: 'mcg',
          time: '08:30 AM',
          isTaken: true,
        ));
      }
      // Days 5, 12, 19: Evorel 75mcg (weekly)
      if (dayNumber == 5 || dayNumber == 12 || dayNumber == 19) {
        hrtIntakes.add(HrtIntakeLog(
          medicationId: 'med_evorel_75',
          name: 'Evorel patch',
          dose: 75.0,
          unit: 'mcg',
          time: '08:30 AM',
          isTaken: true,
        ));
      }
      // Day 15: Evorel 50mcg resumed
      if (dayNumber == 15) {
        hrtIntakes.add(HrtIntakeLog(
          medicationId: 'med_evorel_50',
          name: 'Evorel patch',
          dose: 50.0,
          unit: 'mcg',
          time: '08:30 AM',
          isTaken: true,
        ));
      }

      final symptoms = [
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat', category: 'Vasomotor'),
          severity: 'Moderate',
          intensity: 2,
          durationMinutes: 10,
        ),
      ];

      logs.add(_buildLog(
        userId: userId,
        calendarDate: calendarDate,
        symptoms: symptoms,
        triggers: const [],
        sleepDuration: 6.0,
        sleepQuality: 3,
        moodCategory: 'Okay',
        moodScore: 3,
        hrtIntakes: hrtIntakes,
      ));
    }
    return logs;
  }

  /// Сценарий 10 — 30 дней — PCOS Mode, нестандартный цикл
  List<DailyLog> _generateScenario10Logs(String userId, DateTime startDate, int totalDays) {
    final logs = <DailyLog>[];

    for (int i = 0; i < totalDays; i++) {
      final calendarDate = startDate.add(Duration(days: i));
      final dayNumber = i + 1;
      final isBleedingDay = dayNumber >= 1 && dayNumber <= 5; // Menstruation Days 1-5

      final symptoms = <LoggedSymptom>[
        LoggedSymptom(
          symptom: const Symptom(id: 'anxiety', name: 'Anxiety', iconName: 'psychology', category: 'Mood / Cognitive'),
          severity: 'Mild',
          intensity: 1,
        ),
        LoggedSymptom(
          symptom: const Symptom(id: 'brain_fog', name: 'Brain Fog', iconName: 'cloud', category: 'Mood / Cognitive'),
          severity: 'Mild',
          intensity: 1,
        ),
        LoggedSymptom(
          symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat', category: 'Vasomotor'),
          severity: 'Mild',
          intensity: 1,
        ),
      ];

      if (isBleedingDay) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'bleeding', name: 'Bleeding', iconName: 'water_drop', category: 'Cycle'),
          severity: 'Moderate',
          intensity: 2,
        ));
      }

      logs.add(_buildLog(
        userId: userId,
        calendarDate: calendarDate,
        symptoms: symptoms,
        triggers: const [],
        sleepDuration: 6.5,
        sleepQuality: 3,
        moodCategory: 'Okay',
        moodScore: 3,
        hrtIntakes: const [], // Strict: No HRT
      ));
    }
    return logs;
  }

  /// Сценарий 11 — 60 дней — Gel + Ring, soft-stop/resume, слабая корреляция без чипа
  List<DailyLog> _generateScenario11Logs(String userId, DateTime startDate, int totalDays) {
    final logs = <DailyLog>[];
    // Coffee every 3 days (20 days total)
    final coffeeDays = {
      1, 4, 7, 10, 13, 16, 19, 22, 25, 28,
      31, 34, 37, 40, 43, 46, 49, 52, 55, 58,
    };
    // Irritability 3 on exactly half the coffee days (10 days), 2 on other half (10 days)
    final highIrritabilityCoffeeDays = {1, 7, 13, 19, 25, 31, 37, 43, 49, 55};

    for (int i = 0; i < totalDays; i++) {
      final calendarDate = startDate.add(Duration(days: i));
      final dayNumber = i + 1;
      final hasCoffee = coffeeDays.contains(dayNumber);
      final isHighIrritability = highIrritabilityCoffeeDays.contains(dayNumber);

      // Ring active and taken on all 60 days
      // Gel active Days 1–30, soft-stopped Days 31–44, resumed Day 45–60
      final isGelActive = (dayNumber <= 30) || (dayNumber >= 45);

      final hrtIntakes = <HrtIntakeLog>[
        HrtIntakeLog(
          medicationId: 'med_vaginal_ring',
          name: 'Vaginal ring',
          dose: 2.0,
          unit: 'mg',
          time: '08:00 AM',
          isTaken: true,
        ),
      ];

      if (isGelActive) {
        hrtIntakes.add(HrtIntakeLog(
          medicationId: 'med_estradiol_gel',
          name: 'Estradiol gel',
          dose: 1.5,
          unit: 'mg',
          time: '08:30 AM',
          isTaken: true,
        ));
      }

      final symptoms = [
        LoggedSymptom(
          symptom: const Symptom(id: 'irritability', name: 'Irritability', iconName: 'sentiment_dissatisfied', category: 'Mood / Cognitive'),
          severity: isHighIrritability ? 'Severe' : 'Moderate',
          intensity: isHighIrritability ? 3 : 2,
        ),
      ];

      logs.add(_buildLog(
        userId: userId,
        calendarDate: calendarDate,
        symptoms: symptoms,
        triggers: hasCoffee ? const ['Coffee'] : const [],
        caffeineCups: hasCoffee ? 2 : 0,
        sleepDuration: 6.0,
        sleepQuality: 3,
        moodCategory: 'Okay',
        moodScore: 3,
        hrtIntakes: hrtIntakes,
      ));
    }
    return logs;
  }

  // =========================================================================
  // LEGACY PERSONA LOG GENERATORS (PROMPT A–D)
  // =========================================================================

  /// PROMPT A: Perimenopause, No HRT, Moderate-Confidence Correlation (90 days)
  List<DailyLog> _generatePersonaALogs(String userId, DateTime startDate, int totalDays) {
    final rand = Random(4201); // Deterministic seed
    final logs = <DailyLog>[];

    final unloggedIndices = {6, 13, 20, 26, 34, 43, 49, 58, 65, 72, 79, 85, 89};
    final bleedingDays = {10, 11, 12, 25, 26, 27, 39, 40, 54, 55, 56, 68, 69, 70, 83, 84};
    final workStressDays = {4, 15, 22, 32, 45, 53, 61, 74, 82};

    double hfState = 3.0;
    int moderateAnxietyAdded = 0;

    for (int dayIdx = 0; dayIdx < totalDays; dayIdx++) {
      if (unloggedIndices.contains(dayIdx)) continue;

      final calendarDate = startDate.add(Duration(days: dayIdx));
      hfState = 0.65 * hfState + 0.35 * (2.2 + rand.nextDouble() * 1.8) + (rand.nextDouble() * 0.3 - 0.15);
      final double hfScore = hfState.clamp(2.0, 4.8);

      final symptoms = <LoggedSymptom>[];
      symptoms.add(LoggedSymptom(
        symptom: const Symptom(id: 'hot_flash', name: 'Hot Flashes', iconName: 'thermostat'),
        severity: _scoreToLabel(hfScore),
        intensity: hfScore.round(),
        durationMinutes: 15 + (hfScore * 6).round(),
      ));

      if (bleedingDays.contains(dayIdx)) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'bleeding', name: 'Bleeding', iconName: 'water_drop', category: 'Cycle'),
          severity: 'Moderate',
          intensity: 3,
        ));
      }

      if (dayIdx % 3 == 0 || dayIdx % 5 == 0) {
        symptoms.add(LoggedSymptom(
          symptom: const Symptom(id: 'brain_fog', name: 'Brain Fog', iconName: 'psychology'),
          severity: 'Moderate',
          intensity: 3,
        ));
      }

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
        if (moderateAnxietyAdded < 25 && dayIdx % 3 == 0) {
          symptoms.add(LoggedSymptom(
            symptom: const Symptom(id: 'anxiety', name: 'Anxiety', iconName: 'psychology'),
            severity: 'Moderate',
            intensity: 3,
          ));
          moderateAnxietyAdded++;
        }
      }

      final double sleepHours = double.parse((6.1 + rand.nextDouble() * 0.6).toStringAsFixed(1));
      final hour = 20 + rand.nextInt(2);
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
        hrtIntakes: const [],
        createdAt: logTimestamp,
      ));
    }

    return logs;
  }

  /// PROMPT B: Menopause + HRT, Dose Change With Clear Before/After (90 days)
  List<DailyLog> _generatePersonaBLogs(String userId, DateTime startDate, int totalDays) {
    final rand = Random(4202);
    final logs = <DailyLog>[];

    final unloggedIndices = {7, 18, 29, 38, 48, 59, 68, 78, 87};
    final missedEstradiolDays = {14, 31, 55, 73};
    final missedUtrogestanDays = {10, 24, 46, 67, 83};

    for (int dayIdx = 0; dayIdx < totalDays; dayIdx++) {
      if (unloggedIndices.contains(dayIdx)) continue;

      final calendarDate = startDate.add(Duration(days: dayIdx));
      final bool isBeforeChange = dayIdx < 42;

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
  List<DailyLog> _generatePersonaCLogs(String userId, DateTime startDate, int totalDays) {
    final rand = Random(4203);
    final logs = <DailyLog>[];

    final unloggedIndices = {8, 19, 28, 39, 49, 59, 69, 79, 88};
    final redWineDays = {3, 9, 14, 21, 26, 33, 40, 46, 52, 57, 63, 70, 75, 81, 86};
    final exerciseDays = {5, 11, 17, 23, 31, 37, 44, 50, 66, 72, 84};
    final missedDoseDays = {25, 61};

    for (int dayIdx = 0; dayIdx < totalDays; dayIdx++) {
      if (unloggedIndices.contains(dayIdx)) continue;

      final calendarDate = startDate.add(Duration(days: dayIdx));
      final bool prevHadRedWine = redWineDays.contains(dayIdx - 1);
      final bool hasExercise = exerciseDays.contains(dayIdx);
      final bool hasRedWine = redWineDays.contains(dayIdx);

      final double progression = dayIdx / totalDays;
      final double jointScore = (2.4 + progression * 1.1 + (rand.nextDouble() * 0.4 - 0.2)).clamp(2.0, 4.5);
      final double sleepHours = (6.8 - progression * 0.8 + (rand.nextDouble() * 0.4 - 0.2)).clamp(5.0, 7.5);

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
        triggers.add('Alcohol · 1 drink');
      }
      if (hasExercise) {
        triggers.add('Exercise · 35 min');
      }

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
  List<DailyLog> _generatePersonaDLogs(String userId, DateTime startDate, int totalDays) {
    final rand = Random(4204);
    final logs = <DailyLog>[];

    final loggedIndices = {
      2, 6, 11, 16, 21, 25, 29, 32, 35,
      37, 39, 41, 43, 45, 47, 49, 50,
      52, 54, 56, 58, 59,
    };

    final coffeeDays = {6, 21, 37, 45, 54};
    final missedDoseDays = {11, 25, 37, 43, 52, 58};

    for (int dayIdx = 0; dayIdx < totalDays; dayIdx++) {
      if (!loggedIndices.contains(dayIdx)) continue;

      final calendarDate = startDate.add(Duration(days: dayIdx));
      final bool isAfterDoseChange = dayIdx >= 51;

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
