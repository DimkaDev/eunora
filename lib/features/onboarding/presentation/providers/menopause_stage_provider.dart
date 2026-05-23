import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MenopauseStage {
  irregular,
  noPeriod12Months,
  postmenopause,
  surgical,
  pcos,
}

class MenopauseStageState {
  final MenopauseStage? selectedStage;

  MenopauseStageState({this.selectedStage});

  MenopauseStageState copyWith({MenopauseStage? selectedStage}) {
    return MenopauseStageState(
      selectedStage: selectedStage ?? this.selectedStage,
    );
  }
}

class MenopauseStageNotifier extends StateNotifier<MenopauseStageState> {
  MenopauseStageNotifier() : super(MenopauseStageState());

  void selectStage(MenopauseStage stage) {
    state = state.copyWith(selectedStage: stage);
  }
}

final menopauseStageProvider = StateNotifierProvider<MenopauseStageNotifier, MenopauseStageState>((ref) {
  return MenopauseStageNotifier();
});
