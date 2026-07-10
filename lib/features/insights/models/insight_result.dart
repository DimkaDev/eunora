import 'package:freezed_annotation/freezed_annotation.dart';

part 'insight_result.freezed.dart';
part 'insight_result.g.dart';

enum InsightType {
  trigger,
  doseChange,
  progress,
}

@freezed
class InsightResult with _$InsightResult {
  const factory InsightResult({
    required String id,
    required InsightType type,
    required String label,
    required String? disclaimer,
    String? triggerId,
    String? symptomId,
    double? effectSize,
    int? correlationPercent,
    int? eventCount,
    String? direction,
    int? progressCurrent,
    int? progressTarget,
    int? estimatedDaysRemaining,
    required DateTime calculatedAt,
  }) = _InsightResult;

  factory InsightResult.fromJson(Map<String, dynamic> json) =>
      _$InsightResultFromJson(json);
}
