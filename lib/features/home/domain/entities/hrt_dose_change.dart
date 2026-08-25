import 'package:uuid/uuid.dart';

enum RegimenChangeType {
  doseChange,
  frequencyChange,
  scheduleDayChange,
}

class HrtDoseChange {
  final String id;
  final String userId;
  final String medicationId;
  final String medicationName;
  final double oldDose;
  final double newDose;
  final String unit;
  final DateTime changeDate;
  final RegimenChangeType changeType;
  final String previousValue;
  final String newValue;
  final bool? isDoctorPrescribed;

  HrtDoseChange({
    String? id,
    required this.userId,
    required this.medicationId,
    required this.medicationName,
    required this.oldDose,
    required this.newDose,
    required this.unit,
    required this.changeDate,
    this.changeType = RegimenChangeType.doseChange,
    String? previousValue,
    String? newValue,
    this.isDoctorPrescribed,
  })  : id = id ?? const Uuid().v4(),
        previousValue = previousValue ?? '$oldDose $unit'.trim(),
        newValue = newValue ?? '$newDose $unit'.trim();

  /// Returns true if this is a clinical regimen change (Dose or Frequency change)
  bool get isClinicalChange =>
      changeType == RegimenChangeType.doseChange ||
      changeType == RegimenChangeType.frequencyChange;

  /// Returns true if this is an administrative scheduling change (Weekday change only)
  bool get isAdministrativeChange =>
      changeType == RegimenChangeType.scheduleDayChange;

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
      'changeType': changeType.name,
      'previousValue': previousValue,
      'newValue': newValue,
      'isDoctorPrescribed': isDoctorPrescribed,
    };
  }

  factory HrtDoseChange.fromMap(Map<String, dynamic> map) {
    RegimenChangeType parsedType = RegimenChangeType.doseChange;
    final typeStr = map['changeType'] as String?;
    if (typeStr != null) {
      if (typeStr == 'frequencyChange') {
        parsedType = RegimenChangeType.frequencyChange;
      } else if (typeStr == 'scheduleDayChange') {
        parsedType = RegimenChangeType.scheduleDayChange;
      }
    }

    final oldD = (map['oldDose'] as num? ?? 0.0).toDouble();
    final newD = (map['newDose'] as num? ?? 0.0).toDouble();
    final u = map['unit'] as String? ?? '';

    return HrtDoseChange(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      medicationId: map['medicationId'] as String? ?? '',
      medicationName: map['medicationName'] as String? ?? '',
      oldDose: oldD,
      newDose: newD,
      unit: u,
      changeDate: map['changeDate'] != null
          ? DateTime.parse(map['changeDate'] as String)
          : DateTime.now(),
      changeType: parsedType,
      previousValue: map['previousValue'] as String? ?? '$oldD $u'.trim(),
      newValue: map['newValue'] as String? ?? '$newD $u'.trim(),
      isDoctorPrescribed: map['isDoctorPrescribed'] as bool?,
    );
  }
}
