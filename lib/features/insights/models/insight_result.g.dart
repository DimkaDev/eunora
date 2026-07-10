// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insight_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InsightResultImpl _$$InsightResultImplFromJson(Map<String, dynamic> json) =>
    _$InsightResultImpl(
      id: json['id'] as String,
      type: $enumDecode(_$InsightTypeEnumMap, json['type']),
      label: json['label'] as String,
      disclaimer: json['disclaimer'] as String?,
      triggerId: json['triggerId'] as String?,
      symptomId: json['symptomId'] as String?,
      effectSize: (json['effectSize'] as num?)?.toDouble(),
      correlationPercent: (json['correlationPercent'] as num?)?.toInt(),
      eventCount: (json['eventCount'] as num?)?.toInt(),
      direction: json['direction'] as String?,
      progressCurrent: (json['progressCurrent'] as num?)?.toInt(),
      progressTarget: (json['progressTarget'] as num?)?.toInt(),
      estimatedDaysRemaining: (json['estimatedDaysRemaining'] as num?)?.toInt(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );

Map<String, dynamic> _$$InsightResultImplToJson(_$InsightResultImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$InsightTypeEnumMap[instance.type]!,
      'label': instance.label,
      'disclaimer': instance.disclaimer,
      'triggerId': instance.triggerId,
      'symptomId': instance.symptomId,
      'effectSize': instance.effectSize,
      'correlationPercent': instance.correlationPercent,
      'eventCount': instance.eventCount,
      'direction': instance.direction,
      'progressCurrent': instance.progressCurrent,
      'progressTarget': instance.progressTarget,
      'estimatedDaysRemaining': instance.estimatedDaysRemaining,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
    };

const _$InsightTypeEnumMap = {
  InsightType.trigger: 'trigger',
  InsightType.doseChange: 'doseChange',
  InsightType.progress: 'progress',
};
