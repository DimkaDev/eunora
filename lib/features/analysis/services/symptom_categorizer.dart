import '../../symptom_log/data/symptom_library.dart';

/// Service responsible for mapping symptom IDs and names to categories
/// using the shared symptom library with robust fallbacks.
class SymptomCategorizer {
  const SymptomCategorizer();

  /// Map of normalized symptom key to definition in kSymptomLibrary
  static final Map<String, SymptomDefinition> _libraryMap = {
    for (final def in kSymptomLibrary) ...{
      def.id.toLowerCase(): def,
      def.label.toLowerCase(): def,
      _normalizeKey(def.id): def,
      _normalizeKey(def.label): def,
    }
  };

  static String _normalizeKey(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  /// Get the [SymptomCategory] for a given symptom ID or display name.
  SymptomCategory getCategory(String symptomIdOrName) {
    final key = symptomIdOrName.trim().toLowerCase();
    final normalized = _normalizeKey(key);

    // 1. Direct library match
    if (_libraryMap.containsKey(key)) {
      return _libraryMap[key]!.category;
    }
    if (_libraryMap.containsKey(normalized)) {
      return _libraryMap[normalized]!.category;
    }

    // 2. Substring library match
    for (final def in kSymptomLibrary) {
      if (key.contains(def.id.toLowerCase()) ||
          def.id.toLowerCase().contains(key) ||
          key.contains(def.label.toLowerCase()) ||
          def.label.toLowerCase().contains(key)) {
        return def.category;
      }
    }

    // 3. Fallback grouping per specification
    // Vasomotor: hot flashes, night sweats, etc.
    if (normalized.contains('hot_flash') ||
        normalized.contains('night_sweat') ||
        normalized.contains('flush') ||
        normalized.contains('sweat') ||
        normalized.contains('chill') ||
        normalized.contains('palpitation')) {
      return SymptomCategory.vasomotor;
    }

    // Sleep: night wakings, difficulty falling asleep, etc.
    if (normalized.contains('sleep') ||
        normalized.contains('waking') ||
        normalized.contains('insomnia')) {
      return SymptomCategory.sleep;
    }

    // Mood / Cognitive: anxiety, irritability, low mood, brain fog, etc.
    if (normalized.contains('anxiety') ||
        normalized.contains('irritab') ||
        normalized.contains('mood') ||
        normalized.contains('fog') ||
        normalized.contains('depress') ||
        normalized.contains('nervous') ||
        normalized.contains('memory') ||
        normalized.contains('panic') ||
        normalized.contains('concentrat')) {
      return SymptomCategory.moodCognitive;
    }

    // Urogenital: libido, vaginal, urinary, etc.
    if (normalized.contains('libido') ||
        normalized.contains('vagina') ||
        normalized.contains('urin') ||
        normalized.contains('sex') ||
        normalized.contains('uti')) {
      return SymptomCategory.urogenital;
    }

    // Cycle: bleed, period, cramp, flow
    if (normalized.contains('bleed') ||
        normalized.contains('period') ||
        normalized.contains('cycle') ||
        normalized.contains('flow')) {
      return SymptomCategory.cycle;
    }

    // Physical: everything else
    return SymptomCategory.physical;
  }

  /// Get the standard display label for a symptom ID.
  String getLabel(String symptomId) {
    final key = symptomId.trim().toLowerCase();
    final normalized = _normalizeKey(key);

    if (_libraryMap.containsKey(key)) {
      return _libraryMap[key]!.label;
    }
    if (_libraryMap.containsKey(normalized)) {
      return _libraryMap[normalized]!.label;
    }

    // Fallback: Title case from snake_case
    final words = symptomId.split(RegExp(r'[_\s]+'));
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
