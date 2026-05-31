import 'package:uuid/uuid.dart';

class OtherMedication {
  final String id;
  final String name;
  final String? dose;
  final String? category;
  final String? frequency;
  final bool hasReminder;

  OtherMedication({
    String? id,
    required this.name,
    this.dose,
    this.category,
    this.frequency,
    this.hasReminder = false,
  }) : id = id ?? const Uuid().v4();

  OtherMedication copyWith({
    String? name,
    String? dose,
    String? category,
    String? frequency,
    bool? hasReminder,
  }) {
    return OtherMedication(
      id: id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'category': category,
      'frequency': frequency,
      'hasReminder': hasReminder,
    };
  }

  factory OtherMedication.fromMap(Map<String, dynamic> map) {
    return OtherMedication(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      dose: map['dose'] as String?,
      category: map['category'] as String?,
      frequency: map['frequency'] as String?,
      hasReminder: map['hasReminder'] as bool? ?? false,
    );
  }
}
