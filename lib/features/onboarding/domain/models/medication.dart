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
  final DateTime? startedAt;
  final DateTime? endedAt;
  /// List of ISO weekday numbers (1 = Monday, ..., 7 = Sunday) on which this medication is scheduled.
  final List<int> selectedWeekdays;

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
    this.startedAt,
    this.endedAt,
    List<int>? selectedWeekdays,
  })  : selectedWeekdays = selectedWeekdays ?? defaultWeekdaysForFrequency(frequency),
        id = id ?? const Uuid().v4();

  static List<int> defaultWeekdaysForFrequency(String freq) {
    final lower = freq.toLowerCase();
    if (lower.contains('twice')) {
      return const [1, 4]; // Monday & Thursday
    } else if (lower.contains('weekly')) {
      return const [1]; // Monday
    } else if (lower.contains('needed')) {
      return const []; // As Needed
    }
    return const [1, 2, 3, 4, 5, 6, 7]; // Daily
  }

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
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearEndedAt = false,
    List<int>? selectedWeekdays,
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
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
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
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'selectedWeekdays': selectedWeekdays,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    final freq = map['frequency'] as String? ?? '';
    final rawWeekdays = map['selectedWeekdays'] as List<dynamic>?;
    final List<int>? parsedWeekdays = rawWeekdays != null
        ? rawWeekdays.map((e) => (e as num).toInt()).toList()
        : null;

    return Medication(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      type: MedicationType.values.byName(map['type'] as String? ?? 'other'),
      dose: (map['dose'] as num? ?? 0.0).toDouble(),
      unit: map['unit'] as String? ?? '',
      frequency: freq,
      notes: map['notes'] as String?,
      drugCategory: map['drugCategory'] as String? ?? 'systemicEstrogen',
      isCombinedProduct: map['isCombinedProduct'] as bool? ?? false,
      combinedComponents: map['combinedComponents'] as String?,
      market: map['market'] as String? ?? 'uk',
      startedAt: map['startedAt'] != null ? DateTime.tryParse(map['startedAt'] as String) : null,
      endedAt: map['endedAt'] != null ? DateTime.tryParse(map['endedAt'] as String) : null,
      selectedWeekdays: parsedWeekdays,
    );
  }

  String get weekdaysString {
    final lowerFreq = frequency.toLowerCase();
    if (lowerFreq.contains('daily') ||
        lowerFreq.contains('needed') ||
        selectedWeekdays.isEmpty ||
        selectedWeekdays.length == 7) {
      return '';
    }
    final names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(selectedWeekdays)..sort();
    return sorted.map((w) => names[w - 1]).join(', ');
  }

  String get formattedFrequency {
    final days = weekdaysString;
    if (days.isNotEmpty) {
      return '$frequency ($days)';
    }
    return frequency;
  }

  String get doseAndFrequency {
    final formattedDose = dose.toStringAsFixed(dose == dose.toInt() ? 0 : 2);
    return '$formattedDose $unit • $formattedFrequency';
  }
}
