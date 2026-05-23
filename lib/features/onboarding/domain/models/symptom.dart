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

  LoggedSymptom({
    String? id,
    required this.symptom,
    this.intensity,
  }) : id = id ?? const Uuid().v4();

  LoggedSymptom copyWith({
    int? intensity,
  }) {
    return LoggedSymptom(
      id: id,
      symptom: symptom,
      intensity: intensity ?? this.intensity,
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
