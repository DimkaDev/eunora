enum SymptomCategory {
  vasomotor,
  sleep,
  moodCognitive,
  physical,
  urogenital,
  cycle, // perimenopause-only, gated by user stage
}

extension SymptomCategoryExtension on SymptomCategory {
  String get displayName {
    switch (this) {
      case SymptomCategory.vasomotor:
        return 'Vasomotor';
      case SymptomCategory.sleep:
        return 'Sleep';
      case SymptomCategory.moodCognitive:
        return 'Mood & Cognitive';
      case SymptomCategory.physical:
        return 'Physical';
      case SymptomCategory.urogenital:
        return 'Urogenital';
      case SymptomCategory.cycle:
        return 'Cycle';
    }
  }
}

/// Tier 1 = shown as default Quick Log chips (15, ranked by real-world prevalence).
/// Tier 2 = shown only in the expandable "More symptoms" sheet.
enum SymptomTier { core, extended }

class SymptomDefinition {
  final String id;           // stable key, e.g. 'hot_flash', 'brain_fog'
  final String label;        // display text
  final SymptomCategory category;
  final SymptomTier tier;
  final bool perimenopauseOnly; // true only for `cycle` category
  /// Input method: 'intensity_duration', 'severity', 'presence_severity', 'flow_notes'
  final String inputMethod;

  const SymptomDefinition({
    required this.id,
    required this.label,
    required this.category,
    required this.tier,
    required this.inputMethod,
    this.perimenopauseOnly = false,
  });
}

/// Ordering and tier assignment sourced from evidence-informed defaults.
const List<SymptomDefinition> kSymptomLibrary = [
  // ============ TIER 1 — CORE (default Quick Log chips, 15 total) ============
  SymptomDefinition(id: 'fatigue', label: 'Fatigue', category: SymptomCategory.physical, tier: SymptomTier.core, inputMethod: 'severity'),
  SymptomDefinition(id: 'night_wakings', label: 'Night wakings', category: SymptomCategory.sleep, tier: SymptomTier.core, inputMethod: 'severity'),
  SymptomDefinition(id: 'hot_flash', label: 'Hot flashes', category: SymptomCategory.vasomotor, tier: SymptomTier.core, inputMethod: 'intensity_duration'),
  SymptomDefinition(id: 'night_sweats', label: 'Night sweats', category: SymptomCategory.vasomotor, tier: SymptomTier.core, inputMethod: 'severity'),
  SymptomDefinition(id: 'memory_problems', label: 'Memory problems', category: SymptomCategory.moodCognitive, tier: SymptomTier.core, inputMethod: 'severity'),
  SymptomDefinition(id: 'brain_fog', label: 'Brain fog / concentration', category: SymptomCategory.moodCognitive, tier: SymptomTier.core, inputMethod: 'severity'),
  SymptomDefinition(id: 'irritability', label: 'Irritability', category: SymptomCategory.moodCognitive, tier: SymptomTier.core, inputMethod: 'severity'),
  SymptomDefinition(id: 'anxiety', label: 'Anxiety', category: SymptomCategory.moodCognitive, tier: SymptomTier.core, inputMethod: 'severity'),
  SymptomDefinition(id: 'low_mood', label: 'Low mood', category: SymptomCategory.moodCognitive, tier: SymptomTier.core, inputMethod: 'severity'),
  SymptomDefinition(id: 'joint_pain', label: 'Joint pain', category: SymptomCategory.physical, tier: SymptomTier.core, inputMethod: 'presence_severity'),
  SymptomDefinition(id: 'low_libido', label: 'Low libido', category: SymptomCategory.urogenital, tier: SymptomTier.core, inputMethod: 'severity'),
  SymptomDefinition(id: 'vaginal_dryness', label: 'Vaginal dryness', category: SymptomCategory.urogenital, tier: SymptomTier.core, inputMethod: 'severity'),
  SymptomDefinition(id: 'urinary_incontinence', label: 'Urinary incontinence', category: SymptomCategory.urogenital, tier: SymptomTier.core, inputMethod: 'presence_severity'),
  SymptomDefinition(id: 'skin_dryness', label: 'Skin dryness', category: SymptomCategory.physical, tier: SymptomTier.core, inputMethod: 'presence_severity'),
  SymptomDefinition(id: 'headache', label: 'Headache', category: SymptomCategory.physical, tier: SymptomTier.core, inputMethod: 'presence_severity'),

  // ============ TIER 2 — EXTENDED (shown in "More symptoms" expandable sheet) ============
  // Vasomotor
  SymptomDefinition(id: 'heart_palpitations', label: 'Heart palpitations', category: SymptomCategory.vasomotor, tier: SymptomTier.extended, inputMethod: 'presence_severity'),
  SymptomDefinition(id: 'chills', label: 'Chills', category: SymptomCategory.vasomotor, tier: SymptomTier.extended, inputMethod: 'severity'),

  // Sleep
  SymptomDefinition(id: 'difficulty_falling_asleep', label: 'Difficulty falling asleep', category: SymptomCategory.sleep, tier: SymptomTier.extended, inputMethod: 'severity'),

  // Mood / Cognitive
  SymptomDefinition(id: 'mood_swings', label: 'Mood swings', category: SymptomCategory.moodCognitive, tier: SymptomTier.extended, inputMethod: 'severity'),
  SymptomDefinition(id: 'panic_attacks', label: 'Panic attacks', category: SymptomCategory.moodCognitive, tier: SymptomTier.extended, inputMethod: 'presence_severity'),
  SymptomDefinition(id: 'feeling_tense', label: 'Feeling tense or nervous', category: SymptomCategory.moodCognitive, tier: SymptomTier.extended, inputMethod: 'severity'),
  SymptomDefinition(id: 'low_confidence', label: 'Low confidence', category: SymptomCategory.moodCognitive, tier: SymptomTier.extended, inputMethod: 'severity'),

  // Physical
  SymptomDefinition(id: 'weight_gain', label: 'Weight changes', category: SymptomCategory.physical, tier: SymptomTier.extended, inputMethod: 'presence_severity'),
  SymptomDefinition(id: 'hair_changes', label: 'Hair thinning or texture changes', category: SymptomCategory.physical, tier: SymptomTier.extended, inputMethod: 'presence_severity'),
  SymptomDefinition(id: 'breast_tenderness', label: 'Breast tenderness', category: SymptomCategory.physical, tier: SymptomTier.extended, inputMethod: 'severity'),
  SymptomDefinition(id: 'muscle_aches', label: 'Muscle aches or stiffness', category: SymptomCategory.physical, tier: SymptomTier.extended, inputMethod: 'presence_severity'),
  SymptomDefinition(id: 'dizziness', label: 'Dizziness', category: SymptomCategory.physical, tier: SymptomTier.extended, inputMethod: 'presence_severity'),
  SymptomDefinition(id: 'bloating', label: 'Bloating', category: SymptomCategory.physical, tier: SymptomTier.extended, inputMethod: 'presence_severity'),
  SymptomDefinition(id: 'formication', label: 'Itchy or crawling skin sensation', category: SymptomCategory.physical, tier: SymptomTier.extended, inputMethod: 'severity'),
  SymptomDefinition(id: 'dry_mouth_eyes', label: 'Dry mouth or eyes', category: SymptomCategory.physical, tier: SymptomTier.extended, inputMethod: 'presence_severity'),

  // Urogenital
  SymptomDefinition(id: 'painful_sex', label: 'Painful sex', category: SymptomCategory.urogenital, tier: SymptomTier.extended, inputMethod: 'severity'),
  SymptomDefinition(id: 'recurrent_uti', label: 'Recurrent UTIs', category: SymptomCategory.urogenital, tier: SymptomTier.extended, inputMethod: 'presence_severity'),

  // Cycle (perimenopause path only)
  SymptomDefinition(id: 'bleeding', label: 'Bleeding', category: SymptomCategory.cycle, tier: SymptomTier.extended, inputMethod: 'flow_notes', perimenopauseOnly: true),
  SymptomDefinition(id: 'flow_intensity', label: 'Flow intensity', category: SymptomCategory.cycle, tier: SymptomTier.extended, inputMethod: 'flow_notes', perimenopauseOnly: true),
  SymptomDefinition(id: 'irregular_spotting', label: 'Irregular spotting', category: SymptomCategory.cycle, tier: SymptomTier.extended, inputMethod: 'flow_notes', perimenopauseOnly: true),
];
