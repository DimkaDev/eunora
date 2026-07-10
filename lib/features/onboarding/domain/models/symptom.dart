import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Symptom {
  final String id;
  final String name;
  final String iconName;
  final String? category;
  final bool isCustom;

  const Symptom({
    required this.id,
    required this.name,
    required this.iconName,
    this.category,
    this.isCustom = false,
  });

  Symptom copyWith({
    String? id,
    String? name,
    String? iconName,
    String? category,
    bool? isCustom,
  }) {
    return Symptom(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  IconData getIconData() {
    switch (iconName) {
      case 'thermostat':
        return Icons.thermostat;
      case 'mood':
        return Icons.mood;
      case 'dark_mode':
        return Icons.dark_mode;
      case 'opacity':
        return Icons.opacity;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'bedtime':
        return Icons.bedtime;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'psychology':
        return Icons.psychology;
      case 'sentiment_dissatisfied':
        return Icons.sentiment_dissatisfied;
      case 'reorder':
        return Icons.reorder;
      case 'cloud':
        return Icons.cloud;
      case 'settings_backup_restore':
        return Icons.settings_backup_restore;
      case 'battery_low':
        return Icons.battery_0_bar;
      case 'favorite':
        return Icons.favorite;
      case 'dry_cleaning':
        return Icons.dry_cleaning;
      case 'bed':
        return Icons.bed;
      case 'alarm_on':
        return Icons.alarm_on;
      case 'bolt':
        return Icons.bolt;
      case 'skull':
        return Icons.sentiment_neutral;
      default:
        return Icons.medical_services;
    }
  }

  Color getIconColor() {
    final cleanId = id.toLowerCase();
    final cleanName = name.toLowerCase();
    final cleanCat = category?.toLowerCase() ?? '';

    // Vasomotor: Rose/Peach
    if (cleanId.contains('hot_flash') || cleanId.contains('night_sweats') || cleanId.contains('chills') || cleanCat.contains('vasomotor') || cleanName.contains('hot flash') || cleanName.contains('night sweat') || cleanName.contains('chill')) {
      return const Color(0xFFD4A5A5);
    }
    // Sleep: Lavender
    if (cleanId.contains('sleep') || cleanId.contains('night_waking') || cleanId.contains('insomnia') || cleanCat.contains('sleep') || cleanName.contains('sleep') || cleanName.contains('waking')) {
      return const Color(0xFFB8A7C5);
    }
    // Mood/Cognitive: Blue/Sky
    if (cleanId.contains('mood') || cleanId.contains('anxiety') || cleanId.contains('fog') || cleanId.contains('irritability') || cleanId.contains('panic') || cleanId.contains('tense') || cleanId.contains('confidence') || cleanId.contains('memory') || cleanCat.contains('mood') || cleanCat.contains('cognitive') || cleanCat.contains('emotional') || cleanName.contains('mood') || cleanName.contains('anxiet') || cleanName.contains('fog') || cleanName.contains('irritab') || cleanName.contains('tension') || cleanName.contains('nervous') || cleanName.contains('confid') || cleanName.contains('memor') || cleanName.contains('panic')) {
      return const Color(0xFFA7C5D8);
    }
    // Physical: Green/Sage
    if (cleanId.contains('pain') || cleanId.contains('ache') || cleanId.contains('headache') || cleanId.contains('fatigue') || cleanId.contains('dry_skin') || cleanId.contains('skin_dryness') || cleanId.contains('weight') || cleanId.contains('hair') || cleanId.contains('breast') || cleanId.contains('dizziness') || cleanId.contains('bloating') || cleanId.contains('formication') || cleanId.contains('dry_mouth') || cleanCat.contains('physical') || cleanName.contains('pain') || cleanName.contains('ache') || cleanName.contains('head') || cleanName.contains('fatigue') || cleanName.contains('skin') || cleanName.contains('weight') || cleanName.contains('hair') || cleanName.contains('breast') || cleanName.contains('dizz') || cleanName.contains('bloat') || cleanName.contains('formic') || cleanName.contains('mouth') || cleanName.contains('eye')) {
      return const Color(0xFFA9B388);
    }
    // Urogenital: Teal
    if (cleanId.contains('libido') || cleanId.contains('dryness') || cleanId.contains('incontinence') || cleanId.contains('sex') || cleanId.contains('uti') || cleanCat.contains('urogenital') || cleanName.contains('libido') || cleanName.contains('dryness') || cleanName.contains('incont') || cleanName.contains('sex') || cleanName.contains('uti')) {
      return const Color(0xFF8EB8B5);
    }
    // Cycle: Ochre/Tawny
    if (cleanId.contains('bleeding') || cleanId.contains('spotting') || cleanId.contains('flow') || cleanCat.contains('cycle') || cleanName.contains('bleed') || cleanName.contains('spot') || cleanName.contains('flow')) {
      return const Color(0xFFD4B28A);
    }

    return const Color(0xFF9B8B7E);
  }

  factory Symptom.custom(String name) {
    return Symptom(
      id: const Uuid().v4(),
      name: name,
      iconName: 'medical_services', // Default icon for custom symptoms
      isCustom: true,
      category: 'Custom',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'category': category,
      'isCustom': isCustom,
    };
  }

  factory Symptom.fromMap(Map<String, dynamic> map) {
    return Symptom(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      iconName: map['iconName'] as String? ?? '',
      category: map['category'] as String?,
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Symptom && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class LoggedSymptom {
  final String id;
  final Symptom symptom;
  final int? intensity; // 0-10, nullable if not yet set
  final String? severity; // 'Mild', 'Moderate', 'Severe'
  final int? durationMinutes; // minutes

  LoggedSymptom({
    String? id,
    required this.symptom,
    this.intensity,
    this.severity,
    this.durationMinutes,
  }) : id = id ?? const Uuid().v4();

  LoggedSymptom copyWith({
    int? intensity,
    String? severity,
    int? durationMinutes,
  }) {
    return LoggedSymptom(
      id: id,
      symptom: symptom,
      intensity: intensity ?? this.intensity,
      severity: severity ?? this.severity,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symptom': symptom.toMap(),
      'intensity': intensity,
      'severity': severity,
      'durationMinutes': durationMinutes,
    };
  }

  factory LoggedSymptom.fromMap(Map<String, dynamic> map) {
    // Support two formats:
    // 1. Nested: {'id': uuid, 'symptom': {'id': 's_...', 'name': ...}, 'intensity': ...}
    // 2. Flat:   {'id': 's_hot_flashes', 'name': 'Hot Flashes', 'intensity': ...}  ← used by demo seeder & insights engine
    final Symptom symptom;
    if (map['symptom'] != null && map['symptom'] is Map) {
      symptom = Symptom.fromMap(Map<String, dynamic>.from(map['symptom'] as Map));
    } else {
      // Flat format — symptom fields are at the top level
      symptom = Symptom.fromMap(map);
    }
    return LoggedSymptom(
      id: map['id'] as String?,
      symptom: symptom,
      intensity: (map['intensity'] as num?)?.toInt(),
      severity: map['severity'] as String?,
      durationMinutes: map['durationMinutes'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoggedSymptom &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

