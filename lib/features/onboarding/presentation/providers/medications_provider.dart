import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
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

  Future<void> loadFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final profile = await ref.read(firestoreServiceProvider).getUserProfile(user.uid);
      if (profile != null) {
        state = state.copyWith(
          medications: profile.medications,
          error: null,
        );
      }
    } catch (e) {
      debugPrint("Error loading medications from firestore: $e");
    }
  }

  void _syncToFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      ref.read(firestoreServiceProvider).updateUserMedications(user.uid, state.medications).catchError((e) {
        debugPrint("Error syncing user medications to firestore: $e");
      });
    }
  }

  void addMedication(Medication medication) {
    state = state.copyWith(
      medications: [...state.medications, medication],
      error: null,
    );
    _syncToFirestore();
  }

  void removeMedication(String id) {
    state = state.copyWith(
      medications: state.medications.where((m) => m.id != id).toList(),
    );
    _syncToFirestore();
  }

  void updateMedication(Medication medication) {
    final oldMed = state.medications.firstWhere((m) => m.id == medication.id, orElse: () => medication);

    state = state.copyWith(
      medications: state.medications.map((m) => m.id == medication.id ? medication : m).toList(),
    );
    _syncToFirestore();

    if (oldMed.id == medication.id && oldMed.dose != medication.dose) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final change = HrtDoseChange(
          userId: user.uid,
          medicationId: medication.id,
          medicationName: medication.name,
          oldDose: oldMed.dose,
          newDose: medication.dose,
          unit: medication.unit,
          changeDate: DateTime.now(),
        );
        ref.read(firestoreServiceProvider).saveHrtDoseChange(user.uid, change).catchError((e) {
          debugPrint("Error saving dose change: $e");
        });
      }
    }
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
