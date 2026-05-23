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
}
