import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/symptom.dart';
import 'package:eunora/features/symptom_log/data/symptom_library.dart';

String _mapIconName(String id) {
  switch (id) {
    case 'hot_flash':
    case 'night_sweats':
    case 'chills':
      return 'thermostat';
    case 'night_wakings':
    case 'difficulty_falling_asleep':
      return 'bedtime';
    case 'brain_fog':
    case 'memory_problems':
    case 'irritability':
    case 'anxiety':
    case 'low_mood':
    case 'mood_swings':
    case 'panic_attacks':
    case 'feeling_tense':
    case 'low_confidence':
      return 'psychology';
    case 'fatigue':
      return 'battery_low';
    case 'joint_pain':
    case 'muscle_aches':
      return 'accessibility_new';
    case 'vaginal_dryness':
    case 'painful_sex':
    case 'recurrent_uti':
    case 'low_libido':
    case 'urinary_incontinence':
      return 'opacity';
    case 'skin_dryness':
    case 'dry_mouth_eyes':
      return 'dry_cleaning';
    case 'headache':
      return 'skull';
    default:
      return 'medical_services';
  }
}

// --- Static Base Library of Symptoms mapped from kSymptomLibrary ---
final baseSymptomLibrary = kSymptomLibrary.map((def) {
  return Symptom(
    id: def.id,
    name: def.label,
    iconName: _mapIconName(def.id),
    category: def.category.displayName,
  );
}).toList();

class SymptomsState {
  final List<LoggedSymptom> loggedSymptoms; 
  final List<Symptom> customSymptoms;      
  final List<String> frequentSymptomIds; 
  final String? error;

  SymptomsState({
    this.loggedSymptoms = const [],
    this.customSymptoms = const [],
    this.frequentSymptomIds = const [
      'fatigue', 'night_wakings', 'hot_flash', 'night_sweats',
      'memory_problems', 'brain_fog', 'irritability', 'anxiety',
      'low_mood', 'joint_pain', 'low_libido', 'vaginal_dryness',
      'urinary_incontinence', 'skin_dryness', 'headache'
    ],
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
