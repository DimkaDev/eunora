enum TriggerCategory { dietary, lifestyle, environmental }

extension TriggerCategoryExtension on TriggerCategory {
  String get displayName {
    switch (this) {
      case TriggerCategory.dietary:
        return 'Dietary';
      case TriggerCategory.lifestyle:
        return 'Lifestyle';
      case TriggerCategory.environmental:
        return 'Environmental';
    }
  }
}

enum TriggerTier { core, extended }

class TriggerDefinition {
  final String id;
  final String label;
  final TriggerCategory category;
  final TriggerTier tier;

  const TriggerDefinition({
    required this.id,
    required this.label,
    required this.category,
    required this.tier,
  });
}

/// Sourced from hot-flash trigger literature.
const List<TriggerDefinition> kTriggerLibrary = [
  // ============ TIER 1 — CORE (default Quick Log chips, 5 total) ============
  TriggerDefinition(id: 'coffee', label: 'Coffee / caffeine', category: TriggerCategory.dietary, tier: TriggerTier.core),
  TriggerDefinition(id: 'alcohol', label: 'Alcohol', category: TriggerCategory.dietary, tier: TriggerTier.core),
  TriggerDefinition(id: 'stress', label: 'Stress', category: TriggerCategory.lifestyle, tier: TriggerTier.core),
  TriggerDefinition(id: 'exercise', label: 'Exercise', category: TriggerCategory.lifestyle, tier: TriggerTier.core),
  TriggerDefinition(id: 'weather', label: 'Hot weather', category: TriggerCategory.environmental, tier: TriggerTier.core),

  // ============ TIER 2 — EXTENDED ============
  TriggerDefinition(id: 'spicy_food', label: 'Spicy food', category: TriggerCategory.dietary, tier: TriggerTier.extended),
  TriggerDefinition(id: 'sugar_processed_food', label: 'Sugar / processed food', category: TriggerCategory.dietary, tier: TriggerTier.extended),
  TriggerDefinition(id: 'hot_drinks_food', label: 'Hot drinks or food', category: TriggerCategory.dietary, tier: TriggerTier.extended),
  TriggerDefinition(id: 'skipped_meals', label: 'Skipped meals', category: TriggerCategory.dietary, tier: TriggerTier.extended),
  TriggerDefinition(id: 'smoking', label: 'Smoking / tobacco', category: TriggerCategory.lifestyle, tier: TriggerTier.extended),
  TriggerDefinition(id: 'tight_clothing', label: 'Tight clothing or heavy layers', category: TriggerCategory.lifestyle, tier: TriggerTier.extended),
  TriggerDefinition(id: 'warm_bedroom', label: 'Warm bedroom at night', category: TriggerCategory.environmental, tier: TriggerTier.extended),
];
