class DoctorReport {
  final String id;
  final String userId;
  final String title;
  final int periodDays;
  final List<String> includedSections;
  final String? pdfUrl;
  final DateTime generatedAt;

  DoctorReport({
    required this.id,
    required this.userId,
    required this.title,
    required this.periodDays,
    required this.includedSections,
    this.pdfUrl,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'periodDays': periodDays,
      'includedSections': includedSections,
      'pdfUrl': pdfUrl,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory DoctorReport.fromMap(Map<String, dynamic> map) {
    return DoctorReport(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      periodDays: map['periodDays'] as int? ?? 30,
      includedSections: List<String>.from(map['includedSections'] ?? const []),
      pdfUrl: map['pdfUrl'] as String?,
      generatedAt: _parseDateTime(map['generatedAt']) ?? DateTime.now(),
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

  DoctorReport copyWith({
    String? id,
    String? userId,
    String? title,
    int? periodDays,
    List<String>? includedSections,
    String? pdfUrl,
    DateTime? generatedAt,
  }) {
    return DoctorReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      periodDays: periodDays ?? this.periodDays,
      includedSections: includedSections ?? this.includedSections,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
