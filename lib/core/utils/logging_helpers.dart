import 'package:flutter/material.dart';
import 'package:eunora/features/symptom_log/data/symptom_library.dart';
import 'package:eunora/features/symptom_log/data/trigger_library.dart';

/// Sanitizes symptom IDs by mapping legacy onboarding IDs (prefixed with 's_')
/// to their stable symptom library equivalents.
String sanitizeSymptomId(String id) {
  switch (id) {
    case 's_hot_flashes':
    case 'hot_flashes':
      return 'hot_flash';
    case 's_mood':
    case 'mood':
      return 'low_mood';
    case 's_sleep':
    case 's_sleep_problem':
    case 'sleep_problem':
    case 'sleep':
      return 'night_wakings';
    case 's_dryness':
    case 'dryness':
      return 'vaginal_dryness';
    case 's_joint_pain':
      return 'joint_pain';
    case 's_night_sweats':
      return 'night_sweats';
    case 's_fatigue':
      return 'fatigue';
    default:
      if (id.startsWith('s_')) {
        return id.substring(2);
      }
      return id;
  }
}

class LoggedTriggerInfo {
  final String id;
  final String label;
  final String? value;

  LoggedTriggerInfo({
    required this.id,
    required this.label,
    this.value,
  });
}

/// Formats a trigger ID and its associated value (intensity/frequency/counter)
/// into a user-friendly structured string to be saved in Firestore.
String formatTriggerString(
  String id, {
  int? caffeineCups,
  int? alcoholGlasses,
  String? stressLevel,
  String? foodsNotes,
  Map<String, String> customTriggerTexts = const {},
  Map<String, int> customTriggerCounters = const {},
}) {
  final cleanId = id.startsWith('t_') ? id.substring(2) : id;
  
  // Find trigger definition in library
  final def = kTriggerLibrary.firstWhere(
    (t) => t.id == cleanId,
    orElse: () => TriggerDefinition(
      id: cleanId,
      label: cleanId.replaceAll('_', ' '),
      category: TriggerCategory.lifestyle,
      tier: TriggerTier.extended,
    ),
  );

  String? value;
  if (cleanId == 'coffee' || cleanId == 'caffeine') {
    value = '${caffeineCups ?? 0} cups';
  } else if (cleanId == 'alcohol') {
    value = '${alcoholGlasses ?? 0} drinks';
  } else if (cleanId == 'stress') {
    value = stressLevel ?? 'Moderate';
  } else if (cleanId == 'exercise') {
    final mins = customTriggerCounters['t_exercise'] ?? customTriggerCounters['exercise'];
    if (mins != null && mins > 0) {
      value = '$mins min';
    } else {
      value = null;
    }
  } else if (cleanId == 'foods') {
    value = foodsNotes;
  } else {
    // Check custom trigger texts or counters
    value = customTriggerTexts['t_$cleanId'] ?? customTriggerTexts[cleanId];
    if (value == null) {
      final counter = customTriggerCounters['t_$cleanId'] ?? customTriggerCounters[cleanId];
      if (counter != null && counter > 0) {
        value = '$counter times';
      }
    }
  }

  if (value != null && value.isNotEmpty && value != 'Logged') {
    return '${def.label}: $value';
  } else {
    return def.label;
  }
}

/// Parses a structured trigger string from Firestore into its constituent ID, label, and value.
LoggedTriggerInfo parseTriggerString(String triggerStr) {
  final parts = triggerStr.split(':');
  final label = parts[0].trim();
  String? value = parts.length > 1 ? parts.sublist(1).join(':').trim() : null;
  if (value != null && (value == '0 min' || value == '0' || value == 'None' || value.isEmpty)) {
    value = null;
  }

  // Find trigger by label (case-insensitive) or by ID
  final def = kTriggerLibrary.firstWhere(
    (t) => t.label.toLowerCase() == label.toLowerCase() || t.id.toLowerCase() == label.toLowerCase(),
    orElse: () => TriggerDefinition(
      id: label.toLowerCase().replaceAll(' ', '_'),
      label: label,
      category: TriggerCategory.lifestyle,
      tier: TriggerTier.extended,
    ),
  );

  return LoggedTriggerInfo(id: def.id, label: def.label, value: value);
}
