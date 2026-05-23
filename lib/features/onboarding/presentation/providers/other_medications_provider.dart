import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/other_medication.dart';

class OtherMedicationsState {
  final List<OtherMedication> medications;
  final bool isTakingAnythingElse;
  final String? error;

  OtherMedicationsState({
    this.medications = const [],
    this.isTakingAnythingElse = true,
    this.error,
  });

  OtherMedicationsState copyWith({
    List<OtherMedication>? medications,
    bool? isTakingAnythingElse,
    String? error,
  }) {
    return OtherMedicationsState(
      medications: medications ?? this.medications,
      isTakingAnythingElse: isTakingAnythingElse ?? this.isTakingAnythingElse,
      error: error ?? this.error,
    );
  }
}

class OtherMedicationsNotifier extends StateNotifier<OtherMedicationsState> {
  OtherMedicationsNotifier() : super(OtherMedicationsState());

  void toggleIsTakingAnythingElse(bool value) {
    state = state.copyWith(isTakingAnythingElse: value);
  }

  void addMedication({
    required String name,
    String? dose,
    String? category,
    String? frequency,
    bool hasReminder = false,
  }) {
    if (name.trim().isEmpty) return;

    final newMed = OtherMedication(
      name: name.trim(),
      dose: dose?.trim(),
      category: category,
      frequency: frequency,
      hasReminder: hasReminder,
    );
    state = state.copyWith(medications: [...state.medications, newMed]);
  }

  void updateMedication(OtherMedication updatedMed) {
    state = state.copyWith(
      medications: state.medications.map((m) => m.id == updatedMed.id ? updatedMed : m).toList(),
    );
  }

  void removeMedication(String id) {
    state = state.copyWith(
      medications: state.medications.where((m) => m.id != id).toList(),
    );
  }
}

final otherMedicationsProvider = StateNotifierProvider<OtherMedicationsNotifier, OtherMedicationsState>((ref) {
  return OtherMedicationsNotifier();
});
