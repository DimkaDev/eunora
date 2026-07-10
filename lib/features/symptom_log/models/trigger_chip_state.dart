import '../data/trigger_library.dart';

class TriggerChipState {
  final TriggerDefinition definition;
  final bool isSelected;

  const TriggerChipState({
    required this.definition,
    required this.isSelected,
  });

  TriggerChipState copyWith({
    TriggerDefinition? definition,
    bool? isSelected,
  }) {
    return TriggerChipState(
      definition: definition ?? this.definition,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
