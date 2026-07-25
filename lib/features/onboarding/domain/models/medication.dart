import 'package:uuid/uuid.dart';

enum MedicationType {
  patch,
  pill,
  gel,
  cream,
  spray,
  pessary,
  ring,
  other;

  String get displayName {
    switch (this) {
      case MedicationType.patch: return 'Patch';
      case MedicationType.pill: return 'Tablet';
      case MedicationType.gel: return 'Gel';
      case MedicationType.cream: return 'Cream';
      case MedicationType.spray: return 'Spray';
      case MedicationType.pessary: return 'Pessary';
      case MedicationType.ring: return 'Ring';
      case MedicationType.other: return 'Other';
    }
  }

  String get iconName {
    switch (this) {
      case MedicationType.patch: return 'rectangle';
      case MedicationType.pill: return 'pill';
      case MedicationType.gel:
      case MedicationType.cream: return 'clean_hands';
      case MedicationType.spray: return 'air';
      case MedicationType.pessary: return 'vaccines';
      case MedicationType.ring: return 'radio_button_unchecked';
      case MedicationType.other: return 'medical_services';
    }
  }
}

class Medication {
  final String id;
  final String name;
  final MedicationType type;
  final double dose;
  final String unit;
  final String frequency;
  final String? notes;

  // --- HRT Drug Library v2 fields ---
  /// Stores HrtDrugCategory.name (e.g. 'systemicEstrogen', 'combined', etc.)
  final String drugCategory;
  /// True when a single product contains both oestrogen and progestogen.
  final bool isCombinedProduct;
  /// Display-only free text, e.g. "estradiol+norethindrone".
  final String? combinedComponents;
  /// Stores HrtMarket.name ('uk', 'us', 'both') — informational only.
  final String market;
  final DateTime? endedAt;


  Medication({
    String? id,
    required this.name,
    required this.type,
    required this.dose,
    required this.unit,
    required this.frequency,
    this.notes,
    this.drugCategory = 'systemicEstrogen',
    this.isCombinedProduct = false,
    this.combinedComponents,
    this.market = 'uk',
    this.endedAt,
  }) : id = id ?? const Uuid().v4();

  Medication copyWith({
    String? name,
    MedicationType? type,
    double? dose,
    String? unit,
    String? frequency,
    String? notes,
    String? drugCategory,
    bool? isCombinedProduct,
    String? combinedComponents,
    String? market,
    DateTime? endedAt,
    bool clearEndedAt = false,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      dose: dose ?? this.dose,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      notes: notes ?? this.notes,
      drugCategory: drugCategory ?? this.drugCategory,
      isCombinedProduct: isCombinedProduct ?? this.isCombinedProduct,
      combinedComponents: combinedComponents ?? this.combinedComponents,
      market: market ?? this.market,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'dose': dose,
      'unit': unit,
      'frequency': frequency,
      'notes': notes,
      'drugCategory': drugCategory,
      'isCombinedProduct': isCombinedProduct,
      'combinedComponents': combinedComponents,
      'market': market,
      'endedAt': endedAt?.toIso8601String(),

    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      type: MedicationType.values.byName(map['type'] as String? ?? 'other'),
      dose: (map['dose'] as num? ?? 0.0).toDouble(),
      unit: map['unit'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      notes: map['notes'] as String?,
      drugCategory: map['drugCategory'] as String? ?? 'systemicEstrogen',
      isCombinedProduct: map['isCombinedProduct'] as bool? ?? false,
      combinedComponents: map['combinedComponents'] as String?,
      market: map['market'] as String? ?? 'uk',
      endedAt: map['endedAt'] != null ? DateTime.tryParse(map['endedAt'] as String) : null,
    );
  }

  String get doseAndFrequency => '${dose.toStringAsFixed(dose == dose.toInt() ? 0 : 2)} $unit • $frequency';
}
