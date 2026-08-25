import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:eunora/core/services/firestore_service.dart';
import 'package:eunora/features/home/domain/entities/hrt_dose_change.dart';
import '../../domain/models/medication.dart';
import 'onboarding_profile_provider.dart';

import 'package:eunora/features/hrt_tracker/domain/hrt_schedule_service.dart';
import 'package:eunora/features/home/domain/entities/daily_log.dart';

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

@Riverpod(keepAlive: true)
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

  /// Returns medications active on [targetDate] according to start_date and end_date.
  List<Medication> getActiveMedicationsForDate(DateTime targetDate) {
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return state.medications.where((med) {
      if (med.startedAt != null) {
        final start = DateTime(med.startedAt!.year, med.startedAt!.month, med.startedAt!.day);
        if (target.isBefore(start)) return false;
      }
      if (med.endedAt != null) {
        final end = DateTime(med.endedAt!.year, med.endedAt!.month, med.endedAt!.day);
        if (target.isAfter(end)) return false;
      }
      return true;
    }).toList();
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

  void endMedication(String id, {DateTime? endDate}) {
    final stopDate = endDate ?? DateTime.now();
    state = state.copyWith(
      medications: state.medications.map((m) => m.id == id ? m.copyWith(endedAt: stopDate) : m).toList(),
    );
    _syncToFirestore();
  }

  /// Enforces business rule: Hard delete if 0 history, Soft stop (endedAt) if >=1 history.
  void removeOrStopMedication({
    required Medication med,
    required Iterable<DailyLog> logs,
    DateTime? stopDate,
  }) {
    final hasHistory = HrtScheduleService.hasLoggedHistory(med, logs);
    if (hasHistory) {
      endMedication(med.id, endDate: stopDate ?? DateTime.now());
    } else {
      removeMedication(med.id);
    }
  }

  void updateMedication(Medication medication) {
    final oldMed = state.medications.firstWhere((m) => m.id == medication.id, orElse: () => medication);

    state = state.copyWith(
      medications: state.medications.map((m) => m.id == medication.id ? medication : m).toList(),
    );
    _syncToFirestore();

    final isOnboardingCompleted = ref.read(onboardingProfileProvider)?.isOnboardingCompleted ?? false;
    if (isOnboardingCompleted && oldMed.id == medication.id) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        RegimenChangeType? changeType;
        String prevVal = '';
        String newVal = '';

        final bool doseChanged = oldMed.dose != medication.dose || oldMed.unit != medication.unit;
        final bool freqChanged = oldMed.frequency != medication.frequency;
        final bool weekdaysChanged = !listEquals(oldMed.selectedWeekdays, medication.selectedWeekdays);

        if (doseChanged && freqChanged) {
          changeType = RegimenChangeType.doseChange;
          final oldDoseStr = '${oldMed.dose.toStringAsFixed(oldMed.dose == oldMed.dose.toInt() ? 0 : 2)} ${oldMed.unit}'.trim();
          final newDoseStr = '${medication.dose.toStringAsFixed(medication.dose == medication.dose.toInt() ? 0 : 2)} ${medication.unit}'.trim();
          prevVal = '$oldDoseStr, ${oldMed.formattedFrequency}';
          newVal = '$newDoseStr, ${medication.formattedFrequency}';
        } else if (doseChanged) {
          changeType = RegimenChangeType.doseChange;
          prevVal = '${oldMed.dose.toStringAsFixed(oldMed.dose == oldMed.dose.toInt() ? 0 : 2)} ${oldMed.unit}'.trim();
          newVal = '${medication.dose.toStringAsFixed(medication.dose == medication.dose.toInt() ? 0 : 2)} ${medication.unit}'.trim();
        } else if (freqChanged) {
          changeType = RegimenChangeType.frequencyChange;
          prevVal = oldMed.formattedFrequency;
          newVal = medication.formattedFrequency;
        } else if (weekdaysChanged) {
          changeType = RegimenChangeType.scheduleDayChange;
          prevVal = oldMed.weekdaysString;
          newVal = medication.weekdaysString;
        }

        if (changeType != null) {
          final change = HrtDoseChange(
            userId: user.uid,
            medicationId: medication.id,
            medicationName: medication.name,
            oldDose: oldMed.dose,
            newDose: medication.dose,
            unit: medication.unit,
            changeDate: DateTime.now(),
            changeType: changeType,
            previousValue: prevVal,
            newValue: newVal,
          );
          ref.read(firestoreServiceProvider).saveHrtDoseChange(user.uid, change).catchError((e) {
            debugPrint("Error saving regimen change: $e");
          });
        }
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
