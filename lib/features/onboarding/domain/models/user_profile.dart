import 'package:eunora/features/onboarding/presentation/providers/menopause_stage_provider.dart';
import 'medication.dart';
import 'other_medication.dart';
import 'notification_settings.dart';

class UserProfile {
  final String uid;
  final String email;
  final int age;
  final MenopauseStage menopauseStage;
  final String yearsInStage;

  // Stage-specific details
  final String? irregularDuration;
  final String? hormoneTreatment;
  final String? medicationName;
  final DateTime? startDate;

  final String? hrtStatus;
  final String? hrtType;
  final String? lastPeriodDuration;

  final String? menopauseDuration;
  final String? hrtYears;
  final List<String> goals;
  final DateTime? nextAppointment;

  final DateTime? procedureDate;
  final String? procedureType;
  final String? hrtTiming;
  final List<String> selectedStageSymptoms;
  /// Per-symptom quick-access preference.
  /// Values: 'onboarding' | 'promoted' | 'removed'
  final Map<String, String> symptomQuickAccessPrefs;
  final List<String> selectedTriggers;
  final int? overallFeeling;

  final List<String> conditions;
  final String? otherConditionText;
  final String? cycleType;
  final bool? seesSpecialist;
  final bool? tryingToConceive;
  final List<String> interests;

  // General onboarding data
  final List<Medication> medications;
  final List<OtherMedication> otherMedications;
  final bool? isUsingContraception;
  final String? contraceptionType;
  final String? contraceptionBrand;
  final String? contraceptionDose;

  final List<String> healthConditions;
  final String? healthConditionsOther;
  final bool? noneOfAboveConditions;

  final String? smokingStatus;
  final String? alcoholFrequency;
  final double? sleepHours;
  final String? exerciseFrequency;
  final String? caffeineIntake;

  final double? weight;
  final bool? isMetric;

  final NotificationSettings notificationSettings;

  final bool isOnboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.age,
    required this.menopauseStage,
    required this.yearsInStage,
    this.irregularDuration,
    this.hormoneTreatment,
    this.medicationName,
    this.startDate,
    this.hrtStatus,
    this.hrtType,
    this.lastPeriodDuration,
    this.menopauseDuration,
    this.hrtYears,
    this.goals = const [],
    this.nextAppointment,
    this.procedureDate,
    this.procedureType,
    this.hrtTiming,
    this.selectedStageSymptoms = const [],
    this.symptomQuickAccessPrefs = const {},
    this.selectedTriggers = const [],
    this.overallFeeling,
    this.conditions = const [],
    this.otherConditionText,
    this.cycleType,
    this.seesSpecialist,
    this.tryingToConceive,
    this.interests = const [],
    this.medications = const [],
    this.otherMedications = const [],
    this.isUsingContraception,
    this.contraceptionType,
    this.contraceptionBrand,
    this.contraceptionDose,
    this.healthConditions = const [],
    this.healthConditionsOther,
    this.noneOfAboveConditions,
    this.smokingStatus,
    this.alcoholFrequency,
    this.sleepHours,
    this.exerciseFrequency,
    this.caffeineIntake,
    this.weight,
    this.isMetric,
    NotificationSettings? notificationSettings,
    this.isOnboardingCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  }) : notificationSettings = notificationSettings ?? NotificationSettings();

  UserProfile copyWith({
    String? uid,
    String? email,
    int? age,
    MenopauseStage? menopauseStage,
    String? yearsInStage,
    String? irregularDuration,
    String? hormoneTreatment,
    String? medicationName,
    DateTime? startDate,
    String? hrtStatus,
    String? hrtType,
    String? lastPeriodDuration,
    String? menopauseDuration,
    String? hrtYears,
    List<String>? goals,
    DateTime? nextAppointment,
    DateTime? procedureDate,
    String? procedureType,
    String? hrtTiming,
    List<String>? selectedStageSymptoms,
    Map<String, String>? symptomQuickAccessPrefs,
    List<String>? selectedTriggers,
    int? overallFeeling,
    List<String>? conditions,
    String? otherConditionText,
    String? cycleType,
    bool? seesSpecialist,
    bool? tryingToConceive,
    List<String>? interests,
    List<Medication>? medications,
    List<OtherMedication>? otherMedications,
    bool? isUsingContraception,
    String? contraceptionType,
    String? contraceptionBrand,
    String? contraceptionDose,
    List<String>? healthConditions,
    String? healthConditionsOther,
    bool? noneOfAboveConditions,
    String? smokingStatus,
    String? alcoholFrequency,
    double? sleepHours,
    String? exerciseFrequency,
    String? caffeineIntake,
    double? weight,
    bool? isMetric,
    NotificationSettings? notificationSettings,
    bool? isOnboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      age: age ?? this.age,
      menopauseStage: menopauseStage ?? this.menopauseStage,
      yearsInStage: yearsInStage ?? this.yearsInStage,
      irregularDuration: irregularDuration ?? this.irregularDuration,
      hormoneTreatment: hormoneTreatment ?? this.hormoneTreatment,
      medicationName: medicationName ?? this.medicationName,
      startDate: startDate ?? this.startDate,
      hrtStatus: hrtStatus ?? this.hrtStatus,
      hrtType: hrtType ?? this.hrtType,
      lastPeriodDuration: lastPeriodDuration ?? this.lastPeriodDuration,
      menopauseDuration: menopauseDuration ?? this.menopauseDuration,
      hrtYears: hrtYears ?? this.hrtYears,
      goals: goals ?? this.goals,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      procedureDate: procedureDate ?? this.procedureDate,
      procedureType: procedureType ?? this.procedureType,
      hrtTiming: hrtTiming ?? this.hrtTiming,
      selectedStageSymptoms: selectedStageSymptoms ?? this.selectedStageSymptoms,
      symptomQuickAccessPrefs: symptomQuickAccessPrefs ?? this.symptomQuickAccessPrefs,
      selectedTriggers: selectedTriggers ?? this.selectedTriggers,
      overallFeeling: overallFeeling ?? this.overallFeeling,
      conditions: conditions ?? this.conditions,
      otherConditionText: otherConditionText ?? this.otherConditionText,
      cycleType: cycleType ?? this.cycleType,
      seesSpecialist: seesSpecialist ?? this.seesSpecialist,
      tryingToConceive: tryingToConceive ?? this.tryingToConceive,
      interests: interests ?? this.interests,
      medications: medications ?? this.medications,
      otherMedications: otherMedications ?? this.otherMedications,
      isUsingContraception: isUsingContraception ?? this.isUsingContraception,
      contraceptionType: contraceptionType ?? this.contraceptionType,
      contraceptionBrand: contraceptionBrand ?? this.contraceptionBrand,
      contraceptionDose: contraceptionDose ?? this.contraceptionDose,
      healthConditions: healthConditions ?? this.healthConditions,
      healthConditionsOther: healthConditionsOther ?? this.healthConditionsOther,
      noneOfAboveConditions: noneOfAboveConditions ?? this.noneOfAboveConditions,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      alcoholFrequency: alcoholFrequency ?? this.alcoholFrequency,
      sleepHours: sleepHours ?? this.sleepHours,
      exerciseFrequency: exerciseFrequency ?? this.exerciseFrequency,
      caffeineIntake: caffeineIntake ?? this.caffeineIntake,
      weight: weight ?? this.weight,
      isMetric: isMetric ?? this.isMetric,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'age': age,
      'menopauseStage': menopauseStage.name,
      'yearsInStage': yearsInStage,
      'irregularDuration': irregularDuration,
      'hormoneTreatment': hormoneTreatment,
      'medicationName': medicationName,
      'startDate': startDate?.toIso8601String(),
      'hrtStatus': hrtStatus,
      'hrtType': hrtType,
      'lastPeriodDuration': lastPeriodDuration,
      'menopauseDuration': menopauseDuration,
      'hrtYears': hrtYears,
      'goals': goals,
      'nextAppointment': nextAppointment?.toIso8601String(),
      'procedureDate': procedureDate?.toIso8601String(),
      'procedureType': procedureType,
      'hrtTiming': hrtTiming,
      'selectedStageSymptoms': selectedStageSymptoms,
      'symptomQuickAccessPrefs': symptomQuickAccessPrefs,
      'selectedTriggers': selectedTriggers,
      'overallFeeling': overallFeeling,
      'conditions': conditions,
      'otherConditionText': otherConditionText,
      'cycleType': cycleType,
      'seesSpecialist': seesSpecialist,
      'tryingToConceive': tryingToConceive,
      'interests': interests,
      'medications': medications.map((m) => m.toMap()).toList(),
      'otherMedications': otherMedications.map((m) => m.toMap()).toList(),
      'isUsingContraception': isUsingContraception,
      'contraceptionType': contraceptionType,
      'contraceptionBrand': contraceptionBrand,
      'contraceptionDose': contraceptionDose,
      'healthConditions': healthConditions,
      'healthConditionsOther': healthConditionsOther,
      'noneOfAboveConditions': noneOfAboveConditions,
      'smokingStatus': smokingStatus,
      'alcoholFrequency': alcoholFrequency,
      'sleepHours': sleepHours,
      'exerciseFrequency': exerciseFrequency,
      'caffeineIntake': caffeineIntake,
      'weight': weight,
      'isMetric': isMetric,
      'notificationSettings': notificationSettings.toMap(),
      'isOnboardingCompleted': isOnboardingCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      age: map['age'] as int? ?? 50,
      menopauseStage: MenopauseStage.values.byName(map['menopauseStage'] as String? ?? 'irregular'),
      yearsInStage: map['yearsInStage'] as String? ?? '',
      irregularDuration: map['irregularDuration'] as String?,
      hormoneTreatment: map['hormoneTreatment'] as String?,
      medicationName: map['medicationName'] as String?,
      startDate: _parseDateTime(map['startDate']),
      hrtStatus: map['hrtStatus'] as String?,
      hrtType: map['hrtType'] as String?,
      lastPeriodDuration: map['lastPeriodDuration'] as String?,
      menopauseDuration: map['menopauseDuration'] as String?,
      hrtYears: map['hrtYears'] as String?,
      goals: List<String>.from(map['goals'] ?? const []),
      nextAppointment: _parseDateTime(map['nextAppointment']),
      procedureDate: _parseDateTime(map['procedureDate']),
      procedureType: map['procedureType'] as String?,
      hrtTiming: map['hrtTiming'] as String?,
      selectedStageSymptoms: List<String>.from(map['selectedStageSymptoms'] ?? const []),
      symptomQuickAccessPrefs: Map<String, String>.from(
          (map['symptomQuickAccessPrefs'] as Map?)?.map(
                (k, v) => MapEntry(k as String, v as String)) ??
              const {}),
      selectedTriggers: List<String>.from(map['selectedTriggers'] ?? const []),
      overallFeeling: map['overallFeeling'] as int?,
      conditions: List<String>.from(map['conditions'] ?? const []),
      otherConditionText: map['otherConditionText'] as String?,
      cycleType: map['cycleType'] as String?,
      seesSpecialist: map['seesSpecialist'] as bool?,
      tryingToConceive: map['tryingToConceive'] as bool?,
      interests: List<String>.from(map['interests'] ?? const []),
      medications: (map['medications'] as List? ?? [])
          .map((m) => Medication.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      otherMedications: (map['otherMedications'] as List? ?? [])
          .map((m) => OtherMedication.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      isUsingContraception: map['isUsingContraception'] as bool?,
      contraceptionType: map['contraceptionType'] as String?,
      contraceptionBrand: map['contraceptionBrand'] as String?,
      contraceptionDose: map['contraceptionDose'] as String?,
      healthConditions: List<String>.from(map['healthConditions'] ?? const []),
      healthConditionsOther: map['healthConditionsOther'] as String?,
      noneOfAboveConditions: map['noneOfAboveConditions'] as bool?,
      smokingStatus: map['smokingStatus'] as String?,
      alcoholFrequency: map['alcoholFrequency'] as String?,
      sleepHours: (map['sleepHours'] as num?)?.toDouble(),
      exerciseFrequency: map['exerciseFrequency'] as String?,
      caffeineIntake: map['caffeineIntake'] as String?,
      weight: (map['weight'] as num?)?.toDouble(),
      isMetric: map['isMetric'] as bool?,
      notificationSettings: map['notificationSettings'] != null
          ? NotificationSettings.fromMap(Map<String, dynamic>.from(map['notificationSettings'] as Map))
          : null,
      isOnboardingCompleted: map['isOnboardingCompleted'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is String) return DateTime.tryParse(val);
    try {
      if (val.runtimeType.toString() == 'Timestamp') {
        return (val as dynamic).toDate();
      }
    } catch (_) {}
    return null;
  }
}
