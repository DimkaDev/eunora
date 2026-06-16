import 'package:uuid/uuid.dart';

class HrtDoseChange {
  final String id;
  final String userId;
  final String medicationId;
  final String medicationName;
  final double oldDose;
  final double newDose;
  final String unit;
  final DateTime changeDate;

  HrtDoseChange({
    String? id,
    required this.userId,
    required this.medicationId,
    required this.medicationName,
    required this.oldDose,
    required this.newDose,
    required this.unit,
    required this.changeDate,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'oldDose': oldDose,
      'newDose': newDose,
      'unit': unit,
      'changeDate': changeDate.toIso8601String(),
    };
  }

  factory HrtDoseChange.fromMap(Map<String, dynamic> map) {
    return HrtDoseChange(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      medicationId: map['medicationId'] as String? ?? '',
      medicationName: map['medicationName'] as String? ?? '',
      oldDose: (map['oldDose'] as num? ?? 0.0).toDouble(),
      newDose: (map['newDose'] as num? ?? 0.0).toDouble(),
      unit: map['unit'] as String? ?? '',
      changeDate: map['changeDate'] != null 
          ? DateTime.parse(map['changeDate'] as String) 
          : DateTime.now(),
    );
  }
}
