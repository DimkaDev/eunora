import 'package:eunora/features/onboarding/domain/models/symptom.dart';

class DailyLog {
  final String id; // date string in yyyy-MM-dd format
  final String userId;
  final DateTime date;
  final List<LoggedSymptom> symptoms;
  final List<String> triggers;
  final int caffeineCups;
  final int alcoholGlasses;
  final String stressLevel;
  final bool foodsTriggered;
  final String? foodsNotes;
  final Map<String, int> customTriggerCounters;
  final Map<String, String> customTriggerTexts;
  final bool estradiolChecked;
  final double estradiolDose;
  final String estradiolUnit;
  final String estradiolTime;
  final bool progesteroneChecked;
  final double progesteroneDose;
  final String progesteroneUnit;
  final String progesteroneTime;
  final bool vitaminDChecked;
  final bool magnesiumChecked;
  final double sleepDuration;
  final int hydrationCups;
  final double? weight;
  final String additionalNotes;
  final DateTime createdAt;

  DailyLog({
    required this.id,
    required this.userId,
    required this.date,
    this.symptoms = const [],
    this.triggers = const [],
    this.caffeineCups = 0,
    this.alcoholGlasses = 0,
    this.stressLevel = 'Moderate',
    this.foodsTriggered = false,
    this.foodsNotes,
    this.customTriggerCounters = const {},
    this.customTriggerTexts = const {},
    this.estradiolChecked = false,
    this.estradiolDose = 0,
    this.estradiolUnit = 'mcg',
    this.estradiolTime = '',
    this.progesteroneChecked = false,
    this.progesteroneDose = 0,
    this.progesteroneUnit = 'mg',
    this.progesteroneTime = '',
    this.vitaminDChecked = false,
    this.magnesiumChecked = false,
    this.sleepDuration = 7.0,
    this.hydrationCups = 0,
    this.weight,
    this.additionalNotes = '',
    required this.createdAt,
  });

  DailyLog copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<LoggedSymptom>? symptoms,
    List<String>? triggers,
    int? caffeineCups,
    int? alcoholGlasses,
    String? stressLevel,
    bool? foodsTriggered,
    String? foodsNotes,
    Map<String, int>? customTriggerCounters,
    Map<String, String>? customTriggerTexts,
    bool? estradiolChecked,
    double? estradiolDose,
    String? estradiolUnit,
    String? estradiolTime,
    bool? progesteroneChecked,
    double? progesteroneDose,
    String? progesteroneUnit,
    String? progesteroneTime,
    bool? vitaminDChecked,
    bool? magnesiumChecked,
    double? sleepDuration,
    int? hydrationCups,
    double? weight,
    String? additionalNotes,
    DateTime? createdAt,
  }) {
    return DailyLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      symptoms: symptoms ?? this.symptoms,
      triggers: triggers ?? this.triggers,
      caffeineCups: caffeineCups ?? this.caffeineCups,
      alcoholGlasses: alcoholGlasses ?? this.alcoholGlasses,
      stressLevel: stressLevel ?? this.stressLevel,
      foodsTriggered: foodsTriggered ?? this.foodsTriggered,
      foodsNotes: foodsNotes ?? this.foodsNotes,
      customTriggerCounters: customTriggerCounters ?? this.customTriggerCounters,
      customTriggerTexts: customTriggerTexts ?? this.customTriggerTexts,
      estradiolChecked: estradiolChecked ?? this.estradiolChecked,
      estradiolDose: estradiolDose ?? this.estradiolDose,
      estradiolUnit: estradiolUnit ?? this.estradiolUnit,
      estradiolTime: estradiolTime ?? this.estradiolTime,
      progesteroneChecked: progesteroneChecked ?? this.progesteroneChecked,
      progesteroneDose: progesteroneDose ?? this.progesteroneDose,
      progesteroneUnit: progesteroneUnit ?? this.progesteroneUnit,
      progesteroneTime: progesteroneTime ?? this.progesteroneTime,
      vitaminDChecked: vitaminDChecked ?? this.vitaminDChecked,
      magnesiumChecked: magnesiumChecked ?? this.magnesiumChecked,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      hydrationCups: hydrationCups ?? this.hydrationCups,
      weight: weight ?? this.weight,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'symptoms': symptoms.map((s) => s.toMap()).toList(),
      'triggers': triggers,
      'caffeineCups': caffeineCups,
      'alcoholGlasses': alcoholGlasses,
      'stressLevel': stressLevel,
      'foodsTriggered': foodsTriggered,
      'foodsNotes': foodsNotes,
      'customTriggerCounters': customTriggerCounters,
      'customTriggerTexts': customTriggerTexts,
      'estradiolChecked': estradiolChecked,
      'estradiolDose': estradiolDose,
      'estradiolUnit': estradiolUnit,
      'estradiolTime': estradiolTime,
      'progesteroneChecked': progesteroneChecked,
      'progesteroneDose': progesteroneDose,
      'progesteroneUnit': progesteroneUnit,
      'progesteroneTime': progesteroneTime,
      'vitaminDChecked': vitaminDChecked,
      'magnesiumChecked': magnesiumChecked,
      'sleepDuration': sleepDuration,
      'hydrationCups': hydrationCups,
      'weight': weight,
      'additionalNotes': additionalNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      date: _parseDateTime(map['date']) ?? DateTime.now(),
      symptoms: (map['symptoms'] as List? ?? [])
          .map((s) => LoggedSymptom.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      triggers: List<String>.from(map['triggers'] ?? const []),
      caffeineCups: map['caffeineCups'] as int? ?? 0,
      alcoholGlasses: map['alcoholGlasses'] as int? ?? 0,
      stressLevel: map['stressLevel'] as String? ?? 'Moderate',
      foodsTriggered: map['foodsTriggered'] as bool? ?? false,
      foodsNotes: map['foodsNotes'] as String?,
      customTriggerCounters: Map<String, int>.from(map['customTriggerCounters'] ?? const {}),
      customTriggerTexts: Map<String, String>.from(map['customTriggerTexts'] ?? const {}),
      estradiolChecked: map['estradiolChecked'] as bool? ?? false,
      estradiolDose: (map['estradiolDose'] as num? ?? 0).toDouble(),
      estradiolUnit: map['estradiolUnit'] as String? ?? 'mcg',
      estradiolTime: map['estradiolTime'] as String? ?? '',
      progesteroneChecked: map['progesteroneChecked'] as bool? ?? false,
      progesteroneDose: (map['progesteroneDose'] as num? ?? 0).toDouble(),
      progesteroneUnit: map['progesteroneUnit'] as String? ?? 'mg',
      progesteroneTime: map['progesteroneTime'] as String? ?? '',
      vitaminDChecked: map['vitaminDChecked'] as bool? ?? false,
      magnesiumChecked: map['magnesiumChecked'] as bool? ?? false,
      sleepDuration: (map['sleepDuration'] as num? ?? 7.0).toDouble(),
      hydrationCups: map['hydrationCups'] as int? ?? 0,
      weight: (map['weight'] as num?)?.toDouble(),
      additionalNotes: map['additionalNotes'] as String? ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
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
