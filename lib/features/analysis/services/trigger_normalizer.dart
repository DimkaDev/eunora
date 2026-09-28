import 'package:eunora/features/home/domain/entities/daily_log.dart';
import 'package:eunora/features/analysis/domain/models/day_analysis_picture.dart';

class TriggerNormalizer {
  const TriggerNormalizer();

  /// Canonical mapping for built-in and legacy trigger variants (SD-5).
  static const Map<String, String> _canonicalIdMap = {
    'coffee': 'coffee',
    'caffeine': 'coffee',
    't_caffeine': 'coffee',
    't_coffee': 'coffee',
    'coffee / caffeine': 'coffee',
    'coffee/caffeine': 'coffee',

    'alcohol': 'alcohol',
    't_alcohol': 'alcohol',
    'wine': 'alcohol',
    'red wine': 'alcohol',
    'beer': 'alcohol',

    'stress': 'stress',
    't_stress': 'stress',
    'work_stress': 'stress',
    'work stress': 'stress',
    'anxiety': 'stress',

    'smoking': 'smoking',
    'tobacco': 'smoking',
    't_smoking': 'smoking',
    'smoking / tobacco': 'smoking',

    'exercise': 'exercise',
    'workout': 'exercise',
    't_exercise': 'exercise',

    'hot_drinks_food': 'hot_drinks_food',
    't_hot_drinks_food': 'hot_drinks_food',
    'hot drinks': 'hot_drinks_food',
    'hot drinks / food': 'hot_drinks_food',

    'spicy_food': 'spicy_food',
    't_spicy_food': 'spicy_food',
    'spicy': 'spicy_food',

    'sugar_processed_food': 'sugar_processed_food',
    't_sugar_processed_food': 'sugar_processed_food',
    'sugar': 'sugar_processed_food',
    'sugar / processed foods': 'sugar_processed_food',

    'skipped_meals': 'skipped_meals',
    't_skipped_meals': 'skipped_meals',

    'poor_sleep': 'poor_sleep',
    't_poor_sleep': 'poor_sleep',

    'warm_environment': 'warm_environment',
    't_warm_environment': 'warm_environment',

    'tight_clothing': 'tight_clothing',
    't_tight_clothing': 'tight_clothing',
  };

  static const Map<String, String> _canonicalDisplayMap = {
    'coffee': 'Coffee / caffeine',
    'alcohol': 'Alcohol',
    'stress': 'Stress',
    'smoking': 'Smoking / tobacco',
    'exercise': 'Exercise',
    'hot_drinks_food': 'Hot drinks / food',
    'spicy_food': 'Spicy food',
    'sugar_processed_food': 'Sugar / processed foods',
    'skipped_meals': 'Skipped meals',
    'poor_sleep': 'Poor sleep',
    'warm_environment': 'Warm environment',
    'tight_clothing': 'Tight clothing',
  };

  /// Normalizes unit words per SD-5: "drinks" = "glasses" = "servings".
  String normalizeUnit(String unit) {
    final lower = unit.trim().toLowerCase();
    if (lower == 'glasses' || lower == 'servings' || lower == 'drinks' || lower == 'glass' || lower == 'serving' || lower == 'drink') {
      return 'drinks';
    }
    if (lower == 'cups' || lower == 'cup') {
      return 'cups';
    }
    if (lower == 'cigarettes' || lower == 'cigs' || lower == 'cig') {
      return 'cigarettes';
    }
    if (lower == 'min' || lower == 'minutes' || lower == 'mins') {
      return 'minutes';
    }
    return lower;
  }

  /// Extracts canonical identifier from any trigger string or key.
  String canonicalizeId(String raw) {
    final cleaned = raw.trim().toLowerCase().replaceAll('-', '_');
    return _canonicalIdMap[cleaned] ?? cleaned;
  }

  /// Extracts display name for canonical identifier.
  String getDisplayName(String canonicalId, [String? originalRaw]) {
    if (_canonicalDisplayMap.containsKey(canonicalId)) {
      return _canonicalDisplayMap[canonicalId]!;
    }
    if (originalRaw != null && originalRaw.isNotEmpty) {
      // Clean display name from string
      final base = originalRaw.split('·').first.trim();
      return base;
    }
    return canonicalId;
  }

  /// Normalizes triggers present on a given day per SD-5.
  Map<String, NormalizedTrigger> normalizeTriggers(DailyLog log) => extractTriggers(log);

  /// A trigger is ONLY present if the user selected it that day (found in log.triggers).
  /// Default or leftover counters never imply presence.
  Map<String, NormalizedTrigger> extractTriggers(DailyLog log) {
    final Map<String, NormalizedTrigger> result = {};

    for (final rawTrigger in log.triggers) {
      final parts = rawTrigger.split('·').map((p) => p.trim()).toList();
      final rawName = parts.first;
      final canonicalId = canonicalizeId(rawName);
      final displayName = getDisplayName(canonicalId, rawName);

      double? quantity;
      String? unit;
      String? level;
      int? durationMinutes;

      // Extract details from string representation (e.g. 'Exercise · 30 min · Moderate' or 'Coffee · 2 cups')
      if (parts.length > 1) {
        for (int i = 1; i < parts.length; i++) {
          final part = parts[i];
          final partLower = part.toLowerCase();

          // Duration in minutes
          if (partLower.contains('min')) {
            final parsedMins = int.tryParse(partLower.replaceAll(RegExp(r'[^0-9]'), ''));
            if (parsedMins != null) {
              durationMinutes = parsedMins;
            }
          }
          // Level / intensity (e.g. 'Mild', 'Moderate', 'High', 'Severe', 'Low')
          else if (partLower == 'mild' ||
              partLower == 'moderate' ||
              partLower == 'severe' ||
              partLower == 'low' ||
              partLower == 'high') {
            level = part;
          }
          // Quantity with unit (e.g. '2 cups', '3 drinks', '4 servings')
          else {
            final digits = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(part);
            if (digits != null) {
              quantity = double.tryParse(digits.group(1)!);
              final unitPart = part.replaceAll(digits.group(1)!, '').trim();
              if (unitPart.isNotEmpty) {
                unit = normalizeUnit(unitPart);
              }
            }
          }
        }
      }

      // Check specialized DailyLog fields for enrichment, ONLY because the trigger is present in log.triggers
      if (canonicalId == 'coffee') {
        if (quantity == null && log.caffeineCups > 0) {
          quantity = log.caffeineCups.toDouble();
        }
        unit ??= 'cups';
      } else if (canonicalId == 'alcohol') {
        if (quantity == null && log.alcoholGlasses > 0) {
          quantity = log.alcoholGlasses.toDouble();
        }
        unit = unit != null ? normalizeUnit(unit) : 'drinks';
      } else if (canonicalId == 'stress') {
        level ??= log.stressLevel;
      }

      // Check custom trigger counters and texts
      if (log.customTriggerCounters.containsKey(canonicalId) || log.customTriggerCounters.containsKey(rawName)) {
        quantity ??= (log.customTriggerCounters[canonicalId] ?? log.customTriggerCounters[rawName])?.toDouble();
      }
      if (log.customTriggerTexts.containsKey(canonicalId) || log.customTriggerTexts.containsKey(rawName)) {
        final text = log.customTriggerTexts[canonicalId] ?? log.customTriggerTexts[rawName];
        if (text != null && text.isNotEmpty) {
          level ??= text;
        }
      }

      // Merge duplicates into canonicalId
      result[canonicalId] = NormalizedTrigger(
        id: canonicalId,
        displayName: displayName,
        quantity: quantity,
        unit: unit,
        level: level,
        durationMinutes: durationMinutes,
      );
    }

    return result;
  }
}
