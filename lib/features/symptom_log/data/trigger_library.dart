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

enum TriggerInputMethod { presence, presenceQuantity, presenceSeverity }

class TriggerDefinition {
  final String id;
  final String label;
  final TriggerCategory category;
  final TriggerTier tier;
  final TriggerInputMethod inputMethod;
  final String? quantityUnit;

  const TriggerDefinition({
    required this.id,
    required this.label,
    required this.category,
    required this.tier,
    this.inputMethod = TriggerInputMethod.presence,
    this.quantityUnit,
  });
}

/// Sourced from hot-flash trigger literature.
const List<TriggerDefinition> kTriggerLibrary = [
  // ============ TIER 1 — CORE (default Quick Log chips, 5 total) ============
  TriggerDefinition(
    id: 'coffee',
    label: 'Coffee / caffeine',
    category: TriggerCategory.dietary,
    tier: TriggerTier.core,
    inputMethod: TriggerInputMethod.presenceQuantity,
    quantityUnit: 'cups',
  ),
  TriggerDefinition(
    id: 'alcohol',
    label: 'Alcohol',
    category: TriggerCategory.dietary,
    tier: TriggerTier.core,
    inputMethod: TriggerInputMethod.presenceQuantity,
    quantityUnit: 'drinks',
  ),
  TriggerDefinition(
    id: 'stress',
    label: 'Stress',
    category: TriggerCategory.lifestyle,
    tier: TriggerTier.core,
    inputMethod: TriggerInputMethod.presenceSeverity,
  ),
  TriggerDefinition(
    id: 'exercise',
    label: 'Exercise',
    category: TriggerCategory.lifestyle,
    tier: TriggerTier.core,
    inputMethod: TriggerInputMethod.presenceQuantity,
    quantityUnit: 'min',
  ),
  TriggerDefinition(
    id: 'weather',
    label: 'Hot weather',
    category: TriggerCategory.environmental,
    tier: TriggerTier.core,
    inputMethod: TriggerInputMethod.presence,
  ),

  // ============ TIER 2 — EXTENDED ============
  TriggerDefinition(
    id: 'spicy_food',
    label: 'Spicy food',
    category: TriggerCategory.dietary,
    tier: TriggerTier.extended,
    inputMethod: TriggerInputMethod.presence,
  ),
  TriggerDefinition(
    id: 'sugar_processed_food',
    label: 'Sugar / processed food',
    category: TriggerCategory.dietary,
    tier: TriggerTier.extended,
    inputMethod: TriggerInputMethod.presence,
  ),
  TriggerDefinition(
    id: 'hot_drinks_food',
    label: 'Hot drinks or food',
    category: TriggerCategory.dietary,
    tier: TriggerTier.extended,
    inputMethod: TriggerInputMethod.presence,
  ),
  TriggerDefinition(
    id: 'skipped_meals',
    label: 'Skipped meals',
    category: TriggerCategory.dietary,
    tier: TriggerTier.extended,
    inputMethod: TriggerInputMethod.presence,
  ),
  TriggerDefinition(
    id: 'smoking',
    label: 'Smoking / tobacco',
    category: TriggerCategory.lifestyle,
    tier: TriggerTier.extended,
    inputMethod: TriggerInputMethod.presence,
  ),
  TriggerDefinition(
    id: 'tight_clothing',
    label: 'Tight clothing or heavy layers',
    category: TriggerCategory.lifestyle,
    tier: TriggerTier.extended,
    inputMethod: TriggerInputMethod.presence,
  ),
  TriggerDefinition(
    id: 'warm_bedroom',
    label: 'Warm bedroom at night',
    category: TriggerCategory.environmental,
    tier: TriggerTier.extended,
    inputMethod: TriggerInputMethod.presence,
  ),
];
