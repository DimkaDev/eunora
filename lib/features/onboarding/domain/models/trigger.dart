import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class TriggerOption {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String category;
  final bool isCustom;

  const TriggerOption({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.category,
    this.isCustom = false,
  });

  IconData getIconData() {
    switch (iconName) {
      case 'coffee': return Icons.coffee;
      case 'local_bar': return Icons.local_bar;
      case 'psychology': return Icons.psychology;
      case 'fitness_center': return Icons.fitness_center;
      case 'thermostat': return Icons.thermostat;
      case 'restaurant': return Icons.restaurant;
      case 'smoking': return Icons.smoke_free;
      case 'bedtime': return Icons.bedtime;
      case 'water_drop': return Icons.water_drop;
      case 'flight': return Icons.flight;
      case 'work': return Icons.work;
      case 'spa': return Icons.spa;
      default: return Icons.spa;
    }
  }

  Color getIconColor() {
    switch (category) {
      case 'Lifestyle & Habits':
        return const Color(0xFFB8A7C5); // brand-lavender
      case 'Diet & Nutrition':
        return const Color(0xFF8EB8B5); // brand-teal
      case 'Emotional & Environmental':
        return const Color(0xFFD4A5A5); // brand-rose
      default:
        return const Color(0xFF9B8B7E);
    }
  }

  factory TriggerOption.custom(String name, String category) {
    return TriggerOption(
      id: const Uuid().v4(),
      name: name,
      description: 'Custom trigger',
      iconName: 'spa',
      category: category,
      isCustom: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'category': category,
      'isCustom': isCustom,
    };
  }

  factory TriggerOption.fromMap(Map<String, dynamic> map) {
    return TriggerOption(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['iconName'] as String? ?? '',
      category: map['category'] as String? ?? '',
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }
}
