import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/medication.dart';

part 'medications_provider.g.dart';

class MedicationsState {
  final List<Medication> medications;
  final String? error;

  MedicationsState({
    required this.medications,
    this.error,
  });

  MedicationsState copyWith({
    List<Medication>? medications,
    String? error,
  }) {
    return MedicationsState(
      medications: medications ?? this.medications,
      error: error,
    );
  }
}

@riverpod
class Medications extends _$Medications {
  @override
  MedicationsState build() {
    return MedicationsState(medications: []);
  }

  void addMedication(Medication medication) {
    state = state.copyWith(
      medications: [...state.medications, medication],
      error: null,
    );
  }

  void removeMedication(String id) {
    state = state.copyWith(
      medications: state.medications.where((m) => m.id != id).toList(),
    );
  }

  void updateMedication(Medication medication) {
    state = state.copyWith(
      medications: state.medications.map((m) => m.id == medication.id ? medication : m).toList(),
    );
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
