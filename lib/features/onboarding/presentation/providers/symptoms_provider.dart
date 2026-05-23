import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/symptom.dart';

// --- Static Base Library of Symptoms ---
final baseSymptomLibrary = [
  const Symptom(id: 's_hot_flashes', name: 'Hot flashes', iconName: 'thermostat', category: 'Vasomotor Symptoms'),
  const Symptom(id: 's_night_sweats', name: 'Night sweats', iconName: 'bedtime', category: 'Vasomotor Symptoms'),
  const Symptom(id: 's_cold_flashes', name: 'Cold flashes', iconName: 'ac_unit', category: 'Vasomotor Symptoms'),
  
  const Symptom(id: 's_anxiety', name: 'Anxiety', iconName: 'psychology', category: 'Emotional & Cognitive'),
  const Symptom(id: 's_irritability', name: 'Irritability', iconName: 'sentiment_dissatisfied', category: 'Emotional & Cognitive'),
  const Symptom(id: 's_mood_swings', name: 'Mood swings', iconName: 'reorder', category: 'Emotional & Cognitive'),
  const Symptom(id: 's_brain_fog', name: 'Brain fog', iconName: 'cloud', category: 'Emotional & Cognitive'),
  const Symptom(id: 's_memory_lapses', name: 'Memory lapses', iconName: 'settings_backup_restore', category: 'Emotional & Cognitive'),
  
  const Symptom(id: 's_joint_pain', name: 'Joint pain', iconName: 'accessibility_new', category: 'Physical Wellbeing'),
  const Symptom(id: 's_headaches', name: 'Headaches', iconName: 'skull', category: 'Physical Wellbeing'),
  const Symptom(id: 's_fatigue', name: 'Fatigue', iconName: 'battery_low', category: 'Physical Wellbeing'),
  const Symptom(id: 's_heart_palpitation', name: 'Heart palpitation', iconName: 'favorite', category: 'Physical Wellbeing'),
  const Symptom(id: 's_dry_skin', name: 'Dry skin', iconName: 'dry_cleaning', category: 'Physical Wellbeing'),
  
  const Symptom(id: 's_difficulty_sleep', name: 'Difficulty sleep', iconName: 'bed', category: 'Sleep & Energy'),
  const Symptom(id: 's_waking_night', name: 'Waking night', iconName: 'alarm_on', category: 'Sleep & Energy'),
  const Symptom(id: 's_low_energy', name: 'Low energy', iconName: 'bolt', category: 'Sleep & Energy'),
  
  const Symptom(id: 's_mood', name: 'Mood', iconName: 'mood', category: 'Common'),
  const Symptom(id: 's_sleep', name: 'Sleep', iconName: 'dark_mode', category: 'Common'),
  const Symptom(id: 's_dryness', name: 'Dryness', iconName: 'opacity', category: 'Common'),
];

class SymptomsState {
  final List<LoggedSymptom> loggedSymptoms; 
  final List<Symptom> customSymptoms;      
  final List<String> frequentSymptomIds; 
  final String? error;

  SymptomsState({
    this.loggedSymptoms = const [],
    this.customSymptoms = const [],
    this.frequentSymptomIds = const ['s_hot_flashes', 's_mood', 's_sleep', 's_dryness', 's_joint_pain'],
    this.error,
  });

  SymptomsState copyWith({
    List<LoggedSymptom>? loggedSymptoms,
    List<Symptom>? customSymptoms,
    List<String>? frequentSymptomIds,
    String? error,
    bool clearError = false,
  }) {
    return SymptomsState(
      loggedSymptoms: loggedSymptoms ?? this.loggedSymptoms,
      customSymptoms: customSymptoms ?? this.customSymptoms,
      frequentSymptomIds: frequentSymptomIds ?? this.frequentSymptomIds,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SymptomsNotifier extends StateNotifier<SymptomsState> {
  SymptomsNotifier() : super(SymptomsState());

  List<Symptom> get fullLibrary => [...baseSymptomLibrary, ...state.customSymptoms];

  // --- Toggle selection (for logging) ---
  void toggleLogged(Symptom symptom) {
    final existingIndex = state.loggedSymptoms.indexWhere((l) => l.symptom.id == symptom.id);
    
    if (existingIndex >= 0) {
      final newList = List<LoggedSymptom>.from(state.loggedSymptoms)..removeAt(existingIndex);
      state = state.copyWith(loggedSymptoms: newList, clearError: true);
    } else {
      final newLogged = LoggedSymptom(symptom: symptom);
      state = state.copyWith(
        loggedSymptoms: [...state.loggedSymptoms, newLogged],
        clearError: true,
      );
    }
  }

  // --- Toggle frequent (for display on main grid) ---
  void toggleFrequent(String symptomId) {
    final newFrequent = List<String>.from(state.frequentSymptomIds);
    if (newFrequent.contains(symptomId)) {
      newFrequent.remove(symptomId);
      // If removed from frequent, also remove from logged
      final newLogged = state.loggedSymptoms.where((l) => l.symptom.id != symptomId).toList();
      state = state.copyWith(frequentSymptomIds: newFrequent, loggedSymptoms: newLogged);
    } else {
      newFrequent.add(symptomId);
      state = state.copyWith(frequentSymptomIds: newFrequent);
    }
  }

  void addCustomSymptom(String name, String category) {
    if (name.trim().isEmpty) return;
    
    final existsInLibrary = fullLibrary.any((s) => s.name.toLowerCase() == name.trim().toLowerCase());
    if (existsInLibrary) {
      state = state.copyWith(error: 'Symptom already exists in library.');
      return;
    }

    final customSymptom = Symptom(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      iconName: 'medical_services',
      category: category,
      isCustom: true,
    );

    // Add to library AND frequent list AND log it
    final newLogged = LoggedSymptom(symptom: customSymptom);
    
    state = state.copyWith(
      customSymptoms: [...state.customSymptoms, customSymptom],
      loggedSymptoms: [...state.loggedSymptoms, newLogged],
      frequentSymptomIds: [...state.frequentSymptomIds, customSymptom.id],
      clearError: true,
    );
  }

  bool isLogged(String symptomId) {
    return state.loggedSymptoms.any((l) => l.symptom.id == symptomId);
  }

  bool isFrequent(String symptomId) {
    return state.frequentSymptomIds.contains(symptomId);
  }
}

final symptomsProvider = StateNotifierProvider<SymptomsNotifier, SymptomsState>((ref) {
  return SymptomsNotifier();
});

final symptomLibraryProvider = Provider<List<Symptom>>((ref) {
  final state = ref.watch(symptomsProvider);
  return [...baseSymptomLibrary, ...state.customSymptoms];
});
