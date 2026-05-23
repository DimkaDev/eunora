import 'package:uuid/uuid.dart';

enum MedicationType {
  patch,
  pill,
  gel,
  cream,
  other;

  String get displayName {
    switch (this) {
      case MedicationType.patch: return 'Patch';
      case MedicationType.pill: return 'Tablet';
      case MedicationType.gel: return 'Gel';
      case MedicationType.cream: return 'Cream';
      case MedicationType.other: return 'Other';
    }
  }

  String get iconName {
    switch (this) {
      case MedicationType.patch: return 'rectangle';
      case MedicationType.pill: return 'pill';
      case MedicationType.gel:
      case MedicationType.cream: return 'clean_hands';
      case MedicationType.other: return 'medical_services';
    }
  }
}

class Medication {
  final String id;
  final String name;
  final MedicationType type;
  final double dose;
  final String unit;
  final String frequency;
  final String? notes;

  Medication({
    String? id,
    required this.name,
    required this.type,
    required this.dose,
    required this.unit,
    required this.frequency,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  Medication copyWith({
    String? name,
    MedicationType? type,
    double? dose,
    String? unit,
    String? frequency,
    String? notes,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      dose: dose ?? this.dose,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      notes: notes ?? this.notes,
    );
  }

  String get doseAndFrequency => '${dose.toStringAsFixed(dose == dose.toInt() ? 0 : 2)}$unit • $frequency';
}
