import 'package:uuid/uuid.dart';

class Symptom {
  final String id;
  final String name;
  final String iconName;
  final String? category;
  final bool isCustom;

  const Symptom({
    required this.id,
    required this.name,
    required this.iconName,
    this.category,
    this.isCustom = false,
  });

  factory Symptom.custom(String name) {
    return Symptom(
      id: const Uuid().v4(),
      name: name,
      iconName: 'medical_services', // Default icon for custom symptoms
      isCustom: true,
      category: 'Custom',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'category': category,
      'isCustom': isCustom,
    };
  }

  factory Symptom.fromMap(Map<String, dynamic> map) {
    return Symptom(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      iconName: map['iconName'] as String? ?? '',
      category: map['category'] as String?,
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Symptom && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class LoggedSymptom {
  final String id;
  final Symptom symptom;
  final int? intensity; // 0-10, nullable if not yet set
  final String? severity; // 'Mild', 'Moderate', 'Severe'
  final int? durationMinutes; // minutes

  LoggedSymptom({
    String? id,
    required this.symptom,
    this.intensity,
    this.severity,
    this.durationMinutes,
  }) : id = id ?? const Uuid().v4();

  LoggedSymptom copyWith({
    int? intensity,
    String? severity,
    int? durationMinutes,
  }) {
    return LoggedSymptom(
      id: id,
      symptom: symptom,
      intensity: intensity ?? this.intensity,
      severity: severity ?? this.severity,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symptom': symptom.toMap(),
      'intensity': intensity,
      'severity': severity,
      'durationMinutes': durationMinutes,
    };
  }

  factory LoggedSymptom.fromMap(Map<String, dynamic> map) {
    return LoggedSymptom(
      id: map['id'] as String?,
      symptom: Symptom.fromMap(Map<String, dynamic>.from(map['symptom'] as Map)),
      intensity: map['intensity'] as int?,
      severity: map['severity'] as String?,
      durationMinutes: map['durationMinutes'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoggedSymptom &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

