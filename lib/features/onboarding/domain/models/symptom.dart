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
    switch (name.toLowerCase()) {
      case 'hot flashes':
        return const Color(0xFFD4A5A5);
      case 'mood':
        return const Color(0xFFA7C5D8);
      case 'sleep':
        return const Color(0xFFB8A7C5);
      case 'dryness':
        return const Color(0xFF8EB8B5);
      case 'joint pain':
        return const Color(0xFFA9B388);
      default:
        if (category == 'Emotional & Cognitive') {
          return const Color(0xFFA7C5D8);
        } else if (category == 'Physical Wellbeing') {
          return const Color(0xFFA9B388);
        } else if (category == 'Vasomotor Symptoms') {
          return const Color(0xFFD4A5A5);
        } else if (category == 'Sleep & Energy') {
          return const Color(0xFFB8A7C5);
        } else {
          return const Color(0xFF9B8B7E);
        }
    }
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
    return LoggedSymptom(
      id: map['id'] as String?,
      symptom: Symptom.fromMap(Map<String, dynamic>.from(map['symptom'] as Map)),
      intensity: map['intensity'] as int?,
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

