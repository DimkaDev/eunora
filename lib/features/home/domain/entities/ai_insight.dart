class AiInsight {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String type; // correlation, trend, recommendation, prediction
  final String category; // sleep, caffeine, alcohol, exercise, weight
  final double? impactPercentage;
  final bool? isImprovement;
  final DateTime generatedAt;
  final bool isRead;

  AiInsight({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    this.impactPercentage,
    this.isImprovement,
    required this.generatedAt,
    this.isRead = false,
  });

  AiInsight copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? type,
    String? category,
    double? impactPercentage,
    bool? isImprovement,
    DateTime? generatedAt,
    bool? isRead,
  }) {
    return AiInsight(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      impactPercentage: impactPercentage ?? this.impactPercentage,
      isImprovement: isImprovement ?? this.isImprovement,
      generatedAt: generatedAt ?? this.generatedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'impactPercentage': impactPercentage,
      'isImprovement': isImprovement,
      'generatedAt': generatedAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AiInsight.fromMap(Map<String, dynamic> map) {
    return AiInsight(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? '',
      category: map['category'] as String? ?? '',
      impactPercentage: (map['impactPercentage'] as num?)?.toDouble(),
      isImprovement: map['isImprovement'] as bool?,
      generatedAt: _parseDateTime(map['generatedAt']) ?? DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is String) return DateTime.tryParse(val);
    try {
      if (val.runtimeType.toString() == 'Timestamp') {
        return (val as dynamic).toDate();
      }
    } catch (_) {}
    return null;
  }
}
