// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insight_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InsightResult _$InsightResultFromJson(Map<String, dynamic> json) {
  return _InsightResult.fromJson(json);
}

/// @nodoc
mixin _$InsightResult {
  String get id => throw _privateConstructorUsedError;
  InsightType get type => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String? get disclaimer => throw _privateConstructorUsedError;
  String? get triggerId => throw _privateConstructorUsedError;
  String? get symptomId => throw _privateConstructorUsedError;
  double? get effectSize => throw _privateConstructorUsedError;
  int? get correlationPercent => throw _privateConstructorUsedError;
  int? get eventCount => throw _privateConstructorUsedError;
  String? get direction => throw _privateConstructorUsedError;
  int? get progressCurrent => throw _privateConstructorUsedError;
  int? get progressTarget => throw _privateConstructorUsedError;
  int? get estimatedDaysRemaining => throw _privateConstructorUsedError;
  DateTime get calculatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InsightResultCopyWith<InsightResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InsightResultCopyWith<$Res> {
  factory $InsightResultCopyWith(
          InsightResult value, $Res Function(InsightResult) then) =
      _$InsightResultCopyWithImpl<$Res, InsightResult>;
  @useResult
  $Res call(
      {String id,
      InsightType type,
      String label,
      String? disclaimer,
      String? triggerId,
      String? symptomId,
      double? effectSize,
      int? correlationPercent,
      int? eventCount,
      String? direction,
      int? progressCurrent,
      int? progressTarget,
      int? estimatedDaysRemaining,
      DateTime calculatedAt});
}

/// @nodoc
class _$InsightResultCopyWithImpl<$Res, $Val extends InsightResult>
    implements $InsightResultCopyWith<$Res> {
  _$InsightResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? label = null,
    Object? disclaimer = freezed,
    Object? triggerId = freezed,
    Object? symptomId = freezed,
    Object? effectSize = freezed,
    Object? correlationPercent = freezed,
    Object? eventCount = freezed,
    Object? direction = freezed,
    Object? progressCurrent = freezed,
    Object? progressTarget = freezed,
    Object? estimatedDaysRemaining = freezed,
    Object? calculatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as InsightType,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      disclaimer: freezed == disclaimer
          ? _value.disclaimer
          : disclaimer // ignore: cast_nullable_to_non_nullable
              as String?,
      triggerId: freezed == triggerId
          ? _value.triggerId
          : triggerId // ignore: cast_nullable_to_non_nullable
              as String?,
      symptomId: freezed == symptomId
          ? _value.symptomId
          : symptomId // ignore: cast_nullable_to_non_nullable
              as String?,
      effectSize: freezed == effectSize
          ? _value.effectSize
          : effectSize // ignore: cast_nullable_to_non_nullable
              as double?,
      correlationPercent: freezed == correlationPercent
          ? _value.correlationPercent
          : correlationPercent // ignore: cast_nullable_to_non_nullable
              as int?,
      eventCount: freezed == eventCount
          ? _value.eventCount
          : eventCount // ignore: cast_nullable_to_non_nullable
              as int?,
      direction: freezed == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as String?,
      progressCurrent: freezed == progressCurrent
          ? _value.progressCurrent
          : progressCurrent // ignore: cast_nullable_to_non_nullable
              as int?,
      progressTarget: freezed == progressTarget
          ? _value.progressTarget
          : progressTarget // ignore: cast_nullable_to_non_nullable
              as int?,
      estimatedDaysRemaining: freezed == estimatedDaysRemaining
          ? _value.estimatedDaysRemaining
          : estimatedDaysRemaining // ignore: cast_nullable_to_non_nullable
              as int?,
      calculatedAt: null == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InsightResultImplCopyWith<$Res>
    implements $InsightResultCopyWith<$Res> {
  factory _$$InsightResultImplCopyWith(
          _$InsightResultImpl value, $Res Function(_$InsightResultImpl) then) =
      __$$InsightResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      InsightType type,
      String label,
      String? disclaimer,
      String? triggerId,
      String? symptomId,
      double? effectSize,
      int? correlationPercent,
      int? eventCount,
      String? direction,
      int? progressCurrent,
      int? progressTarget,
      int? estimatedDaysRemaining,
      DateTime calculatedAt});
}

/// @nodoc
class __$$InsightResultImplCopyWithImpl<$Res>
    extends _$InsightResultCopyWithImpl<$Res, _$InsightResultImpl>
    implements _$$InsightResultImplCopyWith<$Res> {
  __$$InsightResultImplCopyWithImpl(
      _$InsightResultImpl _value, $Res Function(_$InsightResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? label = null,
    Object? disclaimer = freezed,
    Object? triggerId = freezed,
    Object? symptomId = freezed,
    Object? effectSize = freezed,
    Object? correlationPercent = freezed,
    Object? eventCount = freezed,
    Object? direction = freezed,
    Object? progressCurrent = freezed,
    Object? progressTarget = freezed,
    Object? estimatedDaysRemaining = freezed,
    Object? calculatedAt = null,
  }) {
    return _then(_$InsightResultImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as InsightType,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      disclaimer: freezed == disclaimer
          ? _value.disclaimer
          : disclaimer // ignore: cast_nullable_to_non_nullable
              as String?,
      triggerId: freezed == triggerId
          ? _value.triggerId
          : triggerId // ignore: cast_nullable_to_non_nullable
              as String?,
      symptomId: freezed == symptomId
          ? _value.symptomId
          : symptomId // ignore: cast_nullable_to_non_nullable
              as String?,
      effectSize: freezed == effectSize
          ? _value.effectSize
          : effectSize // ignore: cast_nullable_to_non_nullable
              as double?,
      correlationPercent: freezed == correlationPercent
          ? _value.correlationPercent
          : correlationPercent // ignore: cast_nullable_to_non_nullable
              as int?,
      eventCount: freezed == eventCount
          ? _value.eventCount
          : eventCount // ignore: cast_nullable_to_non_nullable
              as int?,
      direction: freezed == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as String?,
      progressCurrent: freezed == progressCurrent
          ? _value.progressCurrent
          : progressCurrent // ignore: cast_nullable_to_non_nullable
              as int?,
      progressTarget: freezed == progressTarget
          ? _value.progressTarget
          : progressTarget // ignore: cast_nullable_to_non_nullable
              as int?,
      estimatedDaysRemaining: freezed == estimatedDaysRemaining
          ? _value.estimatedDaysRemaining
          : estimatedDaysRemaining // ignore: cast_nullable_to_non_nullable
              as int?,
      calculatedAt: null == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InsightResultImpl implements _InsightResult {
  const _$InsightResultImpl(
      {required this.id,
      required this.type,
      required this.label,
      required this.disclaimer,
      this.triggerId,
      this.symptomId,
      this.effectSize,
      this.correlationPercent,
      this.eventCount,
      this.direction,
      this.progressCurrent,
      this.progressTarget,
      this.estimatedDaysRemaining,
      required this.calculatedAt});

  factory _$InsightResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$InsightResultImplFromJson(json);

  @override
  final String id;
  @override
  final InsightType type;
  @override
  final String label;
  @override
  final String? disclaimer;
  @override
  final String? triggerId;
  @override
  final String? symptomId;
  @override
  final double? effectSize;
  @override
  final int? correlationPercent;
  @override
  final int? eventCount;
  @override
  final String? direction;
  @override
  final int? progressCurrent;
  @override
  final int? progressTarget;
  @override
  final int? estimatedDaysRemaining;
  @override
  final DateTime calculatedAt;

  @override
  String toString() {
    return 'InsightResult(id: $id, type: $type, label: $label, disclaimer: $disclaimer, triggerId: $triggerId, symptomId: $symptomId, effectSize: $effectSize, correlationPercent: $correlationPercent, eventCount: $eventCount, direction: $direction, progressCurrent: $progressCurrent, progressTarget: $progressTarget, estimatedDaysRemaining: $estimatedDaysRemaining, calculatedAt: $calculatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InsightResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.disclaimer, disclaimer) ||
                other.disclaimer == disclaimer) &&
            (identical(other.triggerId, triggerId) ||
                other.triggerId == triggerId) &&
            (identical(other.symptomId, symptomId) ||
                other.symptomId == symptomId) &&
            (identical(other.effectSize, effectSize) ||
                other.effectSize == effectSize) &&
            (identical(other.correlationPercent, correlationPercent) ||
                other.correlationPercent == correlationPercent) &&
            (identical(other.eventCount, eventCount) ||
                other.eventCount == eventCount) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.progressCurrent, progressCurrent) ||
                other.progressCurrent == progressCurrent) &&
            (identical(other.progressTarget, progressTarget) ||
                other.progressTarget == progressTarget) &&
            (identical(other.estimatedDaysRemaining, estimatedDaysRemaining) ||
                other.estimatedDaysRemaining == estimatedDaysRemaining) &&
            (identical(other.calculatedAt, calculatedAt) ||
                other.calculatedAt == calculatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      label,
      disclaimer,
      triggerId,
      symptomId,
      effectSize,
      correlationPercent,
      eventCount,
      direction,
      progressCurrent,
      progressTarget,
      estimatedDaysRemaining,
      calculatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InsightResultImplCopyWith<_$InsightResultImpl> get copyWith =>
      __$$InsightResultImplCopyWithImpl<_$InsightResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InsightResultImplToJson(
      this,
    );
  }
}

abstract class _InsightResult implements InsightResult {
  const factory _InsightResult(
      {required final String id,
      required final InsightType type,
      required final String label,
      required final String? disclaimer,
      final String? triggerId,
      final String? symptomId,
      final double? effectSize,
      final int? correlationPercent,
      final int? eventCount,
      final String? direction,
      final int? progressCurrent,
      final int? progressTarget,
      final int? estimatedDaysRemaining,
      required final DateTime calculatedAt}) = _$InsightResultImpl;

  factory _InsightResult.fromJson(Map<String, dynamic> json) =
      _$InsightResultImpl.fromJson;

  @override
  String get id;
  @override
  InsightType get type;
  @override
  String get label;
  @override
  String? get disclaimer;
  @override
  String? get triggerId;
  @override
  String? get symptomId;
  @override
  double? get effectSize;
  @override
  int? get correlationPercent;
  @override
  int? get eventCount;
  @override
  String? get direction;
  @override
  int? get progressCurrent;
  @override
  int? get progressTarget;
  @override
  int? get estimatedDaysRemaining;
  @override
  DateTime get calculatedAt;
  @override
  @JsonKey(ignore: true)
  _$$InsightResultImplCopyWith<_$InsightResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
