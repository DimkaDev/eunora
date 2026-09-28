/// Medically reviewed, evidence-informed lifestyle tips keyed by trigger ID.
/// Adheres strictly to SD-8:
/// - Plain, calm language
/// - Non-prescriptive lifestyle observations
/// - NEVER mentions hours or time of day (e.g. no "after 12 PM", no "4 hours prior")
/// - No medication, diagnosis, or dose advice
const Map<String, String> kReviewedTriggerTips = {
  'coffee':
      'Consider experimenting with decaffeinated alternatives or smaller servings to see if symptoms ease.',
  'caffeine':
      'Consider experimenting with decaffeinated alternatives or smaller servings to see if symptoms ease.',
  'alcohol':
      'Hydrating between drinks or opting for non-alcoholic alternatives can help reduce symptom intensity.',
  'stress':
      'Gentle breathing techniques or a short walk may help regulate your nervous system on high-stress days.',
  'exercise':
      'Regular, moderate movement often supports overall comfort — adjust intensity according to how your body responds.',
  'hot_weather':
      'Dressing in removable layers and keeping a cool beverage on hand can help manage temperature shifts.',
  'weather':
      'Dressing in removable layers and keeping a cool beverage on hand can help manage temperature shifts.',
  'spicy_food':
      'Choosing milder seasonings or pairing spicy meals with cooling foods may help moderate responses.',
  'sugar_processed_food':
      'Balanced meals with protein and fiber can help maintain steady blood sugar and comfort levels.',
  'hot_drinks_food':
      'Allowing hot drinks and soups to cool slightly before consuming may help avoid sudden temperature spikes.',
  'skipped_meals':
      'Eating regular, balanced meals can help stabilize energy and body temperature regulation.',
  'smoking':
      'Reducing exposure to tobacco smoke supports cardiovascular health and temperature regulation.',
  'tight_clothing':
      'Choosing loose, breathable layers can allow better airflow and comfort.',
  'warm_bedroom':
      'Keeping your bedroom cool and using breathable cotton or linen bedding may help improve nighttime comfort.',
};

/// Retrieves a reviewed lifestyle tip for a trigger, or `null` if no reviewed tip exists.
String? getReviewedTip(String triggerId) {
  final normalized = triggerId.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  if (kReviewedTriggerTips.containsKey(normalized)) {
    return kReviewedTriggerTips[normalized];
  }
  for (final entry in kReviewedTriggerTips.entries) {
    if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
      return entry.value;
    }
  }
  return null;
}
