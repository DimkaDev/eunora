import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/trigger.dart';
import 'package:eunora/features/symptom_log/data/trigger_library.dart';

String _mapTriggerIcon(String id) {
  switch (id) {
    case 'coffee': return 'coffee';
    case 'alcohol': return 'local_bar';
    case 'stress': return 'psychology';
    case 'exercise': return 'fitness_center';
    case 'weather': return 'thermostat';
    case 'spicy_food':
    case 'sugar_processed_food':
    case 'hot_drinks_food':
    case 'skipped_meals':
      return 'restaurant';
    case 'smoking': return 'smoking';
    case 'tight_clothing': return 'spa';
    case 'warm_bedroom': return 'bedtime';
    default: return 'spa';
  }
}

String _mapTriggerDesc(String id) {
  switch (id) {
    case 'coffee': return 'Coffee, tea, energy drinks, or soda consumed throughout the day.';
    case 'alcohol': return 'Wine, beer, or cocktails, especially late in the evening.';
    case 'stress': return 'High mental or emotional pressure from work, home, or personal life.';
    case 'exercise': return 'Physical exertion, intense workouts, or new activity levels.';
    case 'weather': return 'Extreme heat, high humidity, or sudden temperature shifts.';
    case 'spicy_food': return 'Spicy ingredients or dishes that can trigger hot flashes or increase body temperature.';
    case 'sugar_processed_food': return 'Highly processed foods, sweets, or refined sugars that spike blood glucose.';
    case 'hot_drinks_food': return 'Warm beverages like tea, soup, or coffee that raise core body temperature.';
    case 'skipped_meals': return 'Irregular eating windows or fasting that can destabilize energy and hormones.';
    case 'smoking': return 'Cigarettes, e-cigarettes, or tobacco use, which constricts blood vessels.';
    case 'tight_clothing': return 'Restricting clothes or heavy synthetic fabrics that trap heat.';
    case 'warm_bedroom': return 'Elevated room temperature during sleep, causing night sweats and waking.';
    default: return 'Dietary, lifestyle, or environmental trigger.';
  }
}

String _mapTriggerCategory(TriggerCategory cat) {
  switch (cat) {
    case TriggerCategory.dietary: return 'Diet & Nutrition';
    case TriggerCategory.lifestyle: return 'Lifestyle & Habits';
    case TriggerCategory.environmental: return 'Emotional & Environmental';
  }
}

// --- Static Base Library of Triggers mapped from kTriggerLibrary ---
final baseTriggerLibrary = kTriggerLibrary.map((def) {
  return TriggerOption(
    id: 't_${def.id}',
    name: def.label,
    description: _mapTriggerDesc(def.id),
    iconName: _mapTriggerIcon(def.id),
    category: _mapTriggerCategory(def.category),
  );
}).toList();

class TriggersState {
  final List<TriggerOption> customTriggers;
  final List<String> activeTriggerIds;
  final String? error;

  TriggersState({
    this.customTriggers = const [],
    this.activeTriggerIds = const [
      't_coffee',
      't_alcohol',
      't_stress',
      't_exercise',
      't_weather',
      't_spicy_food',
      't_sugar_processed_food',
      't_hot_drinks_food',
      't_skipped_meals',
      't_smoking',
      't_tight_clothing',
      't_warm_bedroom',
    ],
    this.error,
  });

  TriggersState copyWith({
    List<TriggerOption>? customTriggers,
    List<String>? activeTriggerIds,
    String? error,
    bool clearError = false,
  }) {
    return TriggersState(
      customTriggers: customTriggers ?? this.customTriggers,
      activeTriggerIds: activeTriggerIds ?? this.activeTriggerIds,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TriggersNotifier extends StateNotifier<TriggersState> {
  TriggersNotifier() : super(TriggersState());

  List<TriggerOption> get fullLibrary => [...baseTriggerLibrary, ...state.customTriggers];

  void toggleActive(String id) {
    final newActive = List<String>.from(state.activeTriggerIds);
    if (newActive.contains(id)) {
      newActive.remove(id);
    } else {
      newActive.add(id);
    }
    state = state.copyWith(activeTriggerIds: newActive);
  }

  void addCustomTrigger(String name, String category) {
    if (name.trim().isEmpty) return;

    final exists = fullLibrary.any((t) => t.name.toLowerCase() == name.trim().toLowerCase());
    if (exists) {
      state = state.copyWith(error: 'Trigger already exists.');
      return;
    }

    final customTrigger = TriggerOption.custom(name.trim(), category);
    state = state.copyWith(
      customTriggers: [...state.customTriggers, customTrigger],
      activeTriggerIds: [...state.activeTriggerIds, customTrigger.id],
      clearError: true,
    );
  }

  bool isActive(String id) {
    return state.activeTriggerIds.contains(id);
  }
}

final triggersProvider = StateNotifierProvider<TriggersNotifier, TriggersState>((ref) {
  return TriggersNotifier();
});

final triggerLibraryProvider = Provider<List<TriggerOption>>((ref) {
  final state = ref.watch(triggersProvider);
  return [...baseTriggerLibrary, ...state.customTriggers];
});
