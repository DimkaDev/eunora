import '../data/symptom_library.dart';

class SymptomChipState {
  final SymptomDefinition definition;
  final bool isSelected;
  final int? intensity;       // 1-5, null until set
  final int? durationMinutes; // hot flashes only

  const SymptomChipState({
    required this.definition,
    required this.isSelected,
    this.intensity,
    this.durationMinutes,
  });

  SymptomChipState copyWith({
    SymptomDefinition? definition,
    bool? isSelected,
    int? intensity,
    int? durationMinutes,
  }) {
    return SymptomChipState(
      definition: definition ?? this.definition,
      isSelected: isSelected ?? this.isSelected,
      intensity: intensity ?? this.intensity,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
