import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/trigger.dart';

final baseTriggerLibrary = [
  const TriggerOption(id: 't_caffeine', name: 'Caffeine', description: 'Coffee, tea, energy drinks, or soda consumed throughout the day.', iconName: 'coffee', category: 'Lifestyle & Habits'),
  const TriggerOption(id: 't_alcohol', name: 'Alcohol', description: 'Wine, beer, or cocktails, especially late in the evening.', iconName: 'local_bar', category: 'Lifestyle & Habits'),
  const TriggerOption(id: 't_stress', name: 'Stress', description: 'High mental or emotional pressure from work, home, or personal life.', iconName: 'psychology', category: 'Emotional & Environmental'),
  const TriggerOption(id: 't_exercise', name: 'Exercise', description: 'Physical exertion, intense workouts, or new activity levels.', iconName: 'fitness_center', category: 'Lifestyle & Habits'),
  const TriggerOption(id: 't_weather', name: 'Weather', description: 'Extreme heat, high humidity, or sudden temperature shifts.', iconName: 'thermostat', category: 'Emotional & Environmental'),
  const TriggerOption(id: 't_foods', name: 'Foods', description: 'Spicy foods, sugary snacks, or heavy meals before bed.', iconName: 'restaurant', category: 'Diet & Nutrition'),
  const TriggerOption(id: 't_smoking', name: 'Smoking/Tobacco', description: 'Cigarettes, vaping, or exposure to tobacco smoke.', iconName: 'smoking', category: 'Lifestyle & Habits'),
  const TriggerOption(id: 't_sleep', name: 'Poor Sleep', description: 'Lack of sleep, disrupted rest, or irregular bedtime hours.', iconName: 'bedtime', category: 'Lifestyle & Habits'),
  const TriggerOption(id: 't_dehydration', name: 'Dehydration', description: 'Not drinking enough water throughout the day.', iconName: 'water_drop', category: 'Diet & Nutrition'),
  const TriggerOption(id: 't_travel', name: 'Travel', description: 'Long trips, jetlag, or changing climates and timezones.', iconName: 'flight', category: 'Lifestyle & Habits'),
  const TriggerOption(id: 't_work', name: 'Overworking', description: 'Long working hours, physical strain, or intense workplace pressure.', iconName: 'work', category: 'Emotional & Environmental'),
  const TriggerOption(id: 't_sugar', name: 'Sugar & Sweets', description: 'High-sugar foods, chocolate, or processed desserts.', iconName: 'restaurant', category: 'Diet & Nutrition'),
  const TriggerOption(id: 't_relaxation', name: 'Lack of Rest', description: 'Insufficient time for relaxation, mindfulness, or self-care.', iconName: 'spa', category: 'Emotional & Environmental'),
];

class TriggersState {
  final List<TriggerOption> customTriggers;
  final List<String> activeTriggerIds;
  final String? error;

  TriggersState({
    this.customTriggers = const [],
    this.activeTriggerIds = const [
      't_caffeine',
      't_alcohol',
      't_stress',
      't_exercise',
      't_weather',
      't_foods',
      't_smoking',
      't_sleep',
      't_dehydration',
      't_travel',
      't_work',
      't_sugar',
      't_relaxation'
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
