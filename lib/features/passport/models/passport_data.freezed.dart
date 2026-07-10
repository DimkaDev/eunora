// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'passport_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CurrentHrtSummary _$CurrentHrtSummaryFromJson(Map<String, dynamic> json) {
  return _CurrentHrtSummary.fromJson(json);
}

/// @nodoc
mixin _$CurrentHrtSummary {
  String get drugName => throw _privateConstructorUsedError;
  double get doseValue => throw _privateConstructorUsedError;
  String get doseUnit => throw _privateConstructorUsedError;
  String get form => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CurrentHrtSummaryCopyWith<CurrentHrtSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CurrentHrtSummaryCopyWith<$Res> {
  factory $CurrentHrtSummaryCopyWith(
          CurrentHrtSummary value, $Res Function(CurrentHrtSummary) then) =
      _$CurrentHrtSummaryCopyWithImpl<$Res, CurrentHrtSummary>;
  @useResult
  $Res call(
      {String drugName,
      double doseValue,
      String doseUnit,
      String form,
      DateTime startDate});
}

/// @nodoc
class _$CurrentHrtSummaryCopyWithImpl<$Res, $Val extends CurrentHrtSummary>
    implements $CurrentHrtSummaryCopyWith<$Res> {
  _$CurrentHrtSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? drugName = null,
    Object? doseValue = null,
    Object? doseUnit = null,
    Object? form = null,
    Object? startDate = null,
  }) {
    return _then(_value.copyWith(
      drugName: null == drugName
          ? _value.drugName
          : drugName // ignore: cast_nullable_to_non_nullable
              as String,
      doseValue: null == doseValue
          ? _value.doseValue
          : doseValue // ignore: cast_nullable_to_non_nullable
              as double,
      doseUnit: null == doseUnit
          ? _value.doseUnit
          : doseUnit // ignore: cast_nullable_to_non_nullable
              as String,
      form: null == form
          ? _value.form
          : form // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CurrentHrtSummaryImplCopyWith<$Res>
    implements $CurrentHrtSummaryCopyWith<$Res> {
  factory _$$CurrentHrtSummaryImplCopyWith(_$CurrentHrtSummaryImpl value,
          $Res Function(_$CurrentHrtSummaryImpl) then) =
      __$$CurrentHrtSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String drugName,
      double doseValue,
      String doseUnit,
      String form,
      DateTime startDate});
}

/// @nodoc
class __$$CurrentHrtSummaryImplCopyWithImpl<$Res>
    extends _$CurrentHrtSummaryCopyWithImpl<$Res, _$CurrentHrtSummaryImpl>
    implements _$$CurrentHrtSummaryImplCopyWith<$Res> {
  __$$CurrentHrtSummaryImplCopyWithImpl(_$CurrentHrtSummaryImpl _value,
      $Res Function(_$CurrentHrtSummaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? drugName = null,
    Object? doseValue = null,
    Object? doseUnit = null,
    Object? form = null,
    Object? startDate = null,
  }) {
    return _then(_$CurrentHrtSummaryImpl(
      drugName: null == drugName
          ? _value.drugName
          : drugName // ignore: cast_nullable_to_non_nullable
              as String,
      doseValue: null == doseValue
          ? _value.doseValue
          : doseValue // ignore: cast_nullable_to_non_nullable
              as double,
      doseUnit: null == doseUnit
          ? _value.doseUnit
          : doseUnit // ignore: cast_nullable_to_non_nullable
              as String,
      form: null == form
          ? _value.form
          : form // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CurrentHrtSummaryImpl implements _CurrentHrtSummary {
  const _$CurrentHrtSummaryImpl(
      {required this.drugName,
      required this.doseValue,
      required this.doseUnit,
      required this.form,
      required this.startDate});

  factory _$CurrentHrtSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CurrentHrtSummaryImplFromJson(json);

  @override
  final String drugName;
  @override
  final double doseValue;
  @override
  final String doseUnit;
  @override
  final String form;
  @override
  final DateTime startDate;

  @override
  String toString() {
    return 'CurrentHrtSummary(drugName: $drugName, doseValue: $doseValue, doseUnit: $doseUnit, form: $form, startDate: $startDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CurrentHrtSummaryImpl &&
            (identical(other.drugName, drugName) ||
                other.drugName == drugName) &&
            (identical(other.doseValue, doseValue) ||
                other.doseValue == doseValue) &&
            (identical(other.doseUnit, doseUnit) ||
                other.doseUnit == doseUnit) &&
            (identical(other.form, form) || other.form == form) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, drugName, doseValue, doseUnit, form, startDate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CurrentHrtSummaryImplCopyWith<_$CurrentHrtSummaryImpl> get copyWith =>
      __$$CurrentHrtSummaryImplCopyWithImpl<_$CurrentHrtSummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CurrentHrtSummaryImplToJson(
      this,
    );
  }
}

abstract class _CurrentHrtSummary implements CurrentHrtSummary {
  const factory _CurrentHrtSummary(
      {required final String drugName,
      required final double doseValue,
      required final String doseUnit,
      required final String form,
      required final DateTime startDate}) = _$CurrentHrtSummaryImpl;

  factory _CurrentHrtSummary.fromJson(Map<String, dynamic> json) =
      _$CurrentHrtSummaryImpl.fromJson;

  @override
  String get drugName;
  @override
  double get doseValue;
  @override
  String get doseUnit;
  @override
  String get form;
  @override
  DateTime get startDate;
  @override
  @JsonKey(ignore: true)
  _$$CurrentHrtSummaryImplCopyWith<_$CurrentHrtSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SymptomStatRow _$SymptomStatRowFromJson(Map<String, dynamic> json) {
  return _SymptomStatRow.fromJson(json);
}

/// @nodoc
mixin _$SymptomStatRow {
  String get category => throw _privateConstructorUsedError;
  int get daysLogged => throw _privateConstructorUsedError;
  double get avgSeverity => throw _privateConstructorUsedError;
  DateTime? get peakDay => throw _privateConstructorUsedError;
  String get trend => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SymptomStatRowCopyWith<SymptomStatRow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SymptomStatRowCopyWith<$Res> {
  factory $SymptomStatRowCopyWith(
          SymptomStatRow value, $Res Function(SymptomStatRow) then) =
      _$SymptomStatRowCopyWithImpl<$Res, SymptomStatRow>;
  @useResult
  $Res call(
      {String category,
      int daysLogged,
      double avgSeverity,
      DateTime? peakDay,
      String trend});
}

/// @nodoc
class _$SymptomStatRowCopyWithImpl<$Res, $Val extends SymptomStatRow>
    implements $SymptomStatRowCopyWith<$Res> {
  _$SymptomStatRowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? daysLogged = null,
    Object? avgSeverity = null,
    Object? peakDay = freezed,
    Object? trend = null,
  }) {
    return _then(_value.copyWith(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      daysLogged: null == daysLogged
          ? _value.daysLogged
          : daysLogged // ignore: cast_nullable_to_non_nullable
              as int,
      avgSeverity: null == avgSeverity
          ? _value.avgSeverity
          : avgSeverity // ignore: cast_nullable_to_non_nullable
              as double,
      peakDay: freezed == peakDay
          ? _value.peakDay
          : peakDay // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      trend: null == trend
          ? _value.trend
          : trend // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SymptomStatRowImplCopyWith<$Res>
    implements $SymptomStatRowCopyWith<$Res> {
  factory _$$SymptomStatRowImplCopyWith(_$SymptomStatRowImpl value,
          $Res Function(_$SymptomStatRowImpl) then) =
      __$$SymptomStatRowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String category,
      int daysLogged,
      double avgSeverity,
      DateTime? peakDay,
      String trend});
}

/// @nodoc
class __$$SymptomStatRowImplCopyWithImpl<$Res>
    extends _$SymptomStatRowCopyWithImpl<$Res, _$SymptomStatRowImpl>
    implements _$$SymptomStatRowImplCopyWith<$Res> {
  __$$SymptomStatRowImplCopyWithImpl(
      _$SymptomStatRowImpl _value, $Res Function(_$SymptomStatRowImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? daysLogged = null,
    Object? avgSeverity = null,
    Object? peakDay = freezed,
    Object? trend = null,
  }) {
    return _then(_$SymptomStatRowImpl(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      daysLogged: null == daysLogged
          ? _value.daysLogged
          : daysLogged // ignore: cast_nullable_to_non_nullable
              as int,
      avgSeverity: null == avgSeverity
          ? _value.avgSeverity
          : avgSeverity // ignore: cast_nullable_to_non_nullable
              as double,
      peakDay: freezed == peakDay
          ? _value.peakDay
          : peakDay // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      trend: null == trend
          ? _value.trend
          : trend // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SymptomStatRowImpl implements _SymptomStatRow {
  const _$SymptomStatRowImpl(
      {required this.category,
      required this.daysLogged,
      required this.avgSeverity,
      required this.peakDay,
      required this.trend});

  factory _$SymptomStatRowImpl.fromJson(Map<String, dynamic> json) =>
      _$$SymptomStatRowImplFromJson(json);

  @override
  final String category;
  @override
  final int daysLogged;
  @override
  final double avgSeverity;
  @override
  final DateTime? peakDay;
  @override
  final String trend;

  @override
  String toString() {
    return 'SymptomStatRow(category: $category, daysLogged: $daysLogged, avgSeverity: $avgSeverity, peakDay: $peakDay, trend: $trend)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SymptomStatRowImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.daysLogged, daysLogged) ||
                other.daysLogged == daysLogged) &&
            (identical(other.avgSeverity, avgSeverity) ||
                other.avgSeverity == avgSeverity) &&
            (identical(other.peakDay, peakDay) || other.peakDay == peakDay) &&
            (identical(other.trend, trend) || other.trend == trend));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, category, daysLogged, avgSeverity, peakDay, trend);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SymptomStatRowImplCopyWith<_$SymptomStatRowImpl> get copyWith =>
      __$$SymptomStatRowImplCopyWithImpl<_$SymptomStatRowImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SymptomStatRowImplToJson(
      this,
    );
  }
}

abstract class _SymptomStatRow implements SymptomStatRow {
  const factory _SymptomStatRow(
      {required final String category,
      required final int daysLogged,
      required final double avgSeverity,
      required final DateTime? peakDay,
      required final String trend}) = _$SymptomStatRowImpl;

  factory _SymptomStatRow.fromJson(Map<String, dynamic> json) =
      _$SymptomStatRowImpl.fromJson;

  @override
  String get category;
  @override
  int get daysLogged;
  @override
  double get avgSeverity;
  @override
  DateTime? get peakDay;
  @override
  String get trend;
  @override
  @JsonKey(ignore: true)
  _$$SymptomStatRowImplCopyWith<_$SymptomStatRowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChartDataPoint _$ChartDataPointFromJson(Map<String, dynamic> json) {
  return _ChartDataPoint.fromJson(json);
}

/// @nodoc
mixin _$ChartDataPoint {
  DateTime get date => throw _privateConstructorUsedError;
  double get value => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChartDataPointCopyWith<ChartDataPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChartDataPointCopyWith<$Res> {
  factory $ChartDataPointCopyWith(
          ChartDataPoint value, $Res Function(ChartDataPoint) then) =
      _$ChartDataPointCopyWithImpl<$Res, ChartDataPoint>;
  @useResult
  $Res call({DateTime date, double value});
}

/// @nodoc
class _$ChartDataPointCopyWithImpl<$Res, $Val extends ChartDataPoint>
    implements $ChartDataPointCopyWith<$Res> {
  _$ChartDataPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? value = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChartDataPointImplCopyWith<$Res>
    implements $ChartDataPointCopyWith<$Res> {
  factory _$$ChartDataPointImplCopyWith(_$ChartDataPointImpl value,
          $Res Function(_$ChartDataPointImpl) then) =
      __$$ChartDataPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, double value});
}

/// @nodoc
class __$$ChartDataPointImplCopyWithImpl<$Res>
    extends _$ChartDataPointCopyWithImpl<$Res, _$ChartDataPointImpl>
    implements _$$ChartDataPointImplCopyWith<$Res> {
  __$$ChartDataPointImplCopyWithImpl(
      _$ChartDataPointImpl _value, $Res Function(_$ChartDataPointImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? value = null,
  }) {
    return _then(_$ChartDataPointImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChartDataPointImpl implements _ChartDataPoint {
  const _$ChartDataPointImpl({required this.date, required this.value});

  factory _$ChartDataPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChartDataPointImplFromJson(json);

  @override
  final DateTime date;
  @override
  final double value;

  @override
  String toString() {
    return 'ChartDataPoint(date: $date, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChartDataPointImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, date, value);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChartDataPointImplCopyWith<_$ChartDataPointImpl> get copyWith =>
      __$$ChartDataPointImplCopyWithImpl<_$ChartDataPointImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChartDataPointImplToJson(
      this,
    );
  }
}

abstract class _ChartDataPoint implements ChartDataPoint {
  const factory _ChartDataPoint(
      {required final DateTime date,
      required final double value}) = _$ChartDataPointImpl;

  factory _ChartDataPoint.fromJson(Map<String, dynamic> json) =
      _$ChartDataPointImpl.fromJson;

  @override
  DateTime get date;
  @override
  double get value;
  @override
  @JsonKey(ignore: true)
  _$$ChartDataPointImplCopyWith<_$ChartDataPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WeeklyMoodPoint _$WeeklyMoodPointFromJson(Map<String, dynamic> json) {
  return _WeeklyMoodPoint.fromJson(json);
}

/// @nodoc
mixin _$WeeklyMoodPoint {
  DateTime get weekStart => throw _privateConstructorUsedError;
  double get anxiety => throw _privateConstructorUsedError;
  double get irritability => throw _privateConstructorUsedError;
  double get brainFog => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WeeklyMoodPointCopyWith<WeeklyMoodPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeeklyMoodPointCopyWith<$Res> {
  factory $WeeklyMoodPointCopyWith(
          WeeklyMoodPoint value, $Res Function(WeeklyMoodPoint) then) =
      _$WeeklyMoodPointCopyWithImpl<$Res, WeeklyMoodPoint>;
  @useResult
  $Res call(
      {DateTime weekStart,
      double anxiety,
      double irritability,
      double brainFog});
}

/// @nodoc
class _$WeeklyMoodPointCopyWithImpl<$Res, $Val extends WeeklyMoodPoint>
    implements $WeeklyMoodPointCopyWith<$Res> {
  _$WeeklyMoodPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekStart = null,
    Object? anxiety = null,
    Object? irritability = null,
    Object? brainFog = null,
  }) {
    return _then(_value.copyWith(
      weekStart: null == weekStart
          ? _value.weekStart
          : weekStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      anxiety: null == anxiety
          ? _value.anxiety
          : anxiety // ignore: cast_nullable_to_non_nullable
              as double,
      irritability: null == irritability
          ? _value.irritability
          : irritability // ignore: cast_nullable_to_non_nullable
              as double,
      brainFog: null == brainFog
          ? _value.brainFog
          : brainFog // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WeeklyMoodPointImplCopyWith<$Res>
    implements $WeeklyMoodPointCopyWith<$Res> {
  factory _$$WeeklyMoodPointImplCopyWith(_$WeeklyMoodPointImpl value,
          $Res Function(_$WeeklyMoodPointImpl) then) =
      __$$WeeklyMoodPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime weekStart,
      double anxiety,
      double irritability,
      double brainFog});
}

/// @nodoc
class __$$WeeklyMoodPointImplCopyWithImpl<$Res>
    extends _$WeeklyMoodPointCopyWithImpl<$Res, _$WeeklyMoodPointImpl>
    implements _$$WeeklyMoodPointImplCopyWith<$Res> {
  __$$WeeklyMoodPointImplCopyWithImpl(
      _$WeeklyMoodPointImpl _value, $Res Function(_$WeeklyMoodPointImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekStart = null,
    Object? anxiety = null,
    Object? irritability = null,
    Object? brainFog = null,
  }) {
    return _then(_$WeeklyMoodPointImpl(
      weekStart: null == weekStart
          ? _value.weekStart
          : weekStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      anxiety: null == anxiety
          ? _value.anxiety
          : anxiety // ignore: cast_nullable_to_non_nullable
              as double,
      irritability: null == irritability
          ? _value.irritability
          : irritability // ignore: cast_nullable_to_non_nullable
              as double,
      brainFog: null == brainFog
          ? _value.brainFog
          : brainFog // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WeeklyMoodPointImpl implements _WeeklyMoodPoint {
  const _$WeeklyMoodPointImpl(
      {required this.weekStart,
      required this.anxiety,
      required this.irritability,
      required this.brainFog});

  factory _$WeeklyMoodPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeeklyMoodPointImplFromJson(json);

  @override
  final DateTime weekStart;
  @override
  final double anxiety;
  @override
  final double irritability;
  @override
  final double brainFog;

  @override
  String toString() {
    return 'WeeklyMoodPoint(weekStart: $weekStart, anxiety: $anxiety, irritability: $irritability, brainFog: $brainFog)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeeklyMoodPointImpl &&
            (identical(other.weekStart, weekStart) ||
                other.weekStart == weekStart) &&
            (identical(other.anxiety, anxiety) || other.anxiety == anxiety) &&
            (identical(other.irritability, irritability) ||
                other.irritability == irritability) &&
            (identical(other.brainFog, brainFog) ||
                other.brainFog == brainFog));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, weekStart, anxiety, irritability, brainFog);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WeeklyMoodPointImplCopyWith<_$WeeklyMoodPointImpl> get copyWith =>
      __$$WeeklyMoodPointImplCopyWithImpl<_$WeeklyMoodPointImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WeeklyMoodPointImplToJson(
      this,
    );
  }
}

abstract class _WeeklyMoodPoint implements WeeklyMoodPoint {
  const factory _WeeklyMoodPoint(
      {required final DateTime weekStart,
      required final double anxiety,
      required final double irritability,
      required final double brainFog}) = _$WeeklyMoodPointImpl;

  factory _WeeklyMoodPoint.fromJson(Map<String, dynamic> json) =
      _$WeeklyMoodPointImpl.fromJson;

  @override
  DateTime get weekStart;
  @override
  double get anxiety;
  @override
  double get irritability;
  @override
  double get brainFog;
  @override
  @JsonKey(ignore: true)
  _$$WeeklyMoodPointImplCopyWith<_$WeeklyMoodPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChartData _$ChartDataFromJson(Map<String, dynamic> json) {
  return _ChartData.fromJson(json);
}

/// @nodoc
mixin _$ChartData {
  List<ChartDataPoint> get points => throw _privateConstructorUsedError;
  List<WeeklyMoodPoint> get weeklyMoods => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChartDataCopyWith<ChartData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChartDataCopyWith<$Res> {
  factory $ChartDataCopyWith(ChartData value, $Res Function(ChartData) then) =
      _$ChartDataCopyWithImpl<$Res, ChartData>;
  @useResult
  $Res call({List<ChartDataPoint> points, List<WeeklyMoodPoint> weeklyMoods});
}

/// @nodoc
class _$ChartDataCopyWithImpl<$Res, $Val extends ChartData>
    implements $ChartDataCopyWith<$Res> {
  _$ChartDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? points = null,
    Object? weeklyMoods = null,
  }) {
    return _then(_value.copyWith(
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as List<ChartDataPoint>,
      weeklyMoods: null == weeklyMoods
          ? _value.weeklyMoods
          : weeklyMoods // ignore: cast_nullable_to_non_nullable
              as List<WeeklyMoodPoint>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChartDataImplCopyWith<$Res>
    implements $ChartDataCopyWith<$Res> {
  factory _$$ChartDataImplCopyWith(
          _$ChartDataImpl value, $Res Function(_$ChartDataImpl) then) =
      __$$ChartDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ChartDataPoint> points, List<WeeklyMoodPoint> weeklyMoods});
}

/// @nodoc
class __$$ChartDataImplCopyWithImpl<$Res>
    extends _$ChartDataCopyWithImpl<$Res, _$ChartDataImpl>
    implements _$$ChartDataImplCopyWith<$Res> {
  __$$ChartDataImplCopyWithImpl(
      _$ChartDataImpl _value, $Res Function(_$ChartDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? points = null,
    Object? weeklyMoods = null,
  }) {
    return _then(_$ChartDataImpl(
      points: null == points
          ? _value._points
          : points // ignore: cast_nullable_to_non_nullable
              as List<ChartDataPoint>,
      weeklyMoods: null == weeklyMoods
          ? _value._weeklyMoods
          : weeklyMoods // ignore: cast_nullable_to_non_nullable
              as List<WeeklyMoodPoint>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChartDataImpl implements _ChartData {
  const _$ChartDataImpl(
      {required final List<ChartDataPoint> points,
      final List<WeeklyMoodPoint> weeklyMoods = const []})
      : _points = points,
        _weeklyMoods = weeklyMoods;

  factory _$ChartDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChartDataImplFromJson(json);

  final List<ChartDataPoint> _points;
  @override
  List<ChartDataPoint> get points {
    if (_points is EqualUnmodifiableListView) return _points;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_points);
  }

  final List<WeeklyMoodPoint> _weeklyMoods;
  @override
  @JsonKey()
  List<WeeklyMoodPoint> get weeklyMoods {
    if (_weeklyMoods is EqualUnmodifiableListView) return _weeklyMoods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_weeklyMoods);
  }

  @override
  String toString() {
    return 'ChartData(points: $points, weeklyMoods: $weeklyMoods)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChartDataImpl &&
            const DeepCollectionEquality().equals(other._points, _points) &&
            const DeepCollectionEquality()
                .equals(other._weeklyMoods, _weeklyMoods));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_points),
      const DeepCollectionEquality().hash(_weeklyMoods));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChartDataImplCopyWith<_$ChartDataImpl> get copyWith =>
      __$$ChartDataImplCopyWithImpl<_$ChartDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChartDataImplToJson(
      this,
    );
  }
}

abstract class _ChartData implements ChartData {
  const factory _ChartData(
      {required final List<ChartDataPoint> points,
      final List<WeeklyMoodPoint> weeklyMoods}) = _$ChartDataImpl;

  factory _ChartData.fromJson(Map<String, dynamic> json) =
      _$ChartDataImpl.fromJson;

  @override
  List<ChartDataPoint> get points;
  @override
  List<WeeklyMoodPoint> get weeklyMoods;
  @override
  @JsonKey(ignore: true)
  _$$ChartDataImplCopyWith<_$ChartDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HrtPhase _$HrtPhaseFromJson(Map<String, dynamic> json) {
  return _HrtPhase.fromJson(json);
}

/// @nodoc
mixin _$HrtPhase {
  String get periodLabel => throw _privateConstructorUsedError;
  String get drugName => throw _privateConstructorUsedError;
  double get dose => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  int get durationDays => throw _privateConstructorUsedError;
  String get observedEffect => throw _privateConstructorUsedError;
  bool get isDoseChangeMarker => throw _privateConstructorUsedError;
  String? get changeDirection =>
      throw _privateConstructorUsedError; // 'increased' | 'decreased'
  String? get changeReason => throw _privateConstructorUsedError;
  DateTime? get changeDate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HrtPhaseCopyWith<HrtPhase> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HrtPhaseCopyWith<$Res> {
  factory $HrtPhaseCopyWith(HrtPhase value, $Res Function(HrtPhase) then) =
      _$HrtPhaseCopyWithImpl<$Res, HrtPhase>;
  @useResult
  $Res call(
      {String periodLabel,
      String drugName,
      double dose,
      String unit,
      int durationDays,
      String observedEffect,
      bool isDoseChangeMarker,
      String? changeDirection,
      String? changeReason,
      DateTime? changeDate});
}

/// @nodoc
class _$HrtPhaseCopyWithImpl<$Res, $Val extends HrtPhase>
    implements $HrtPhaseCopyWith<$Res> {
  _$HrtPhaseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? periodLabel = null,
    Object? drugName = null,
    Object? dose = null,
    Object? unit = null,
    Object? durationDays = null,
    Object? observedEffect = null,
    Object? isDoseChangeMarker = null,
    Object? changeDirection = freezed,
    Object? changeReason = freezed,
    Object? changeDate = freezed,
  }) {
    return _then(_value.copyWith(
      periodLabel: null == periodLabel
          ? _value.periodLabel
          : periodLabel // ignore: cast_nullable_to_non_nullable
              as String,
      drugName: null == drugName
          ? _value.drugName
          : drugName // ignore: cast_nullable_to_non_nullable
              as String,
      dose: null == dose
          ? _value.dose
          : dose // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      durationDays: null == durationDays
          ? _value.durationDays
          : durationDays // ignore: cast_nullable_to_non_nullable
              as int,
      observedEffect: null == observedEffect
          ? _value.observedEffect
          : observedEffect // ignore: cast_nullable_to_non_nullable
              as String,
      isDoseChangeMarker: null == isDoseChangeMarker
          ? _value.isDoseChangeMarker
          : isDoseChangeMarker // ignore: cast_nullable_to_non_nullable
              as bool,
      changeDirection: freezed == changeDirection
          ? _value.changeDirection
          : changeDirection // ignore: cast_nullable_to_non_nullable
              as String?,
      changeReason: freezed == changeReason
          ? _value.changeReason
          : changeReason // ignore: cast_nullable_to_non_nullable
              as String?,
      changeDate: freezed == changeDate
          ? _value.changeDate
          : changeDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HrtPhaseImplCopyWith<$Res>
    implements $HrtPhaseCopyWith<$Res> {
  factory _$$HrtPhaseImplCopyWith(
          _$HrtPhaseImpl value, $Res Function(_$HrtPhaseImpl) then) =
      __$$HrtPhaseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String periodLabel,
      String drugName,
      double dose,
      String unit,
      int durationDays,
      String observedEffect,
      bool isDoseChangeMarker,
      String? changeDirection,
      String? changeReason,
      DateTime? changeDate});
}

/// @nodoc
class __$$HrtPhaseImplCopyWithImpl<$Res>
    extends _$HrtPhaseCopyWithImpl<$Res, _$HrtPhaseImpl>
    implements _$$HrtPhaseImplCopyWith<$Res> {
  __$$HrtPhaseImplCopyWithImpl(
      _$HrtPhaseImpl _value, $Res Function(_$HrtPhaseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? periodLabel = null,
    Object? drugName = null,
    Object? dose = null,
    Object? unit = null,
    Object? durationDays = null,
    Object? observedEffect = null,
    Object? isDoseChangeMarker = null,
    Object? changeDirection = freezed,
    Object? changeReason = freezed,
    Object? changeDate = freezed,
  }) {
    return _then(_$HrtPhaseImpl(
      periodLabel: null == periodLabel
          ? _value.periodLabel
          : periodLabel // ignore: cast_nullable_to_non_nullable
              as String,
      drugName: null == drugName
          ? _value.drugName
          : drugName // ignore: cast_nullable_to_non_nullable
              as String,
      dose: null == dose
          ? _value.dose
          : dose // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      durationDays: null == durationDays
          ? _value.durationDays
          : durationDays // ignore: cast_nullable_to_non_nullable
              as int,
      observedEffect: null == observedEffect
          ? _value.observedEffect
          : observedEffect // ignore: cast_nullable_to_non_nullable
              as String,
      isDoseChangeMarker: null == isDoseChangeMarker
          ? _value.isDoseChangeMarker
          : isDoseChangeMarker // ignore: cast_nullable_to_non_nullable
              as bool,
      changeDirection: freezed == changeDirection
          ? _value.changeDirection
          : changeDirection // ignore: cast_nullable_to_non_nullable
              as String?,
      changeReason: freezed == changeReason
          ? _value.changeReason
          : changeReason // ignore: cast_nullable_to_non_nullable
              as String?,
      changeDate: freezed == changeDate
          ? _value.changeDate
          : changeDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HrtPhaseImpl implements _HrtPhase {
  const _$HrtPhaseImpl(
      {required this.periodLabel,
      required this.drugName,
      required this.dose,
      required this.unit,
      required this.durationDays,
      required this.observedEffect,
      required this.isDoseChangeMarker,
      this.changeDirection,
      this.changeReason,
      this.changeDate});

  factory _$HrtPhaseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HrtPhaseImplFromJson(json);

  @override
  final String periodLabel;
  @override
  final String drugName;
  @override
  final double dose;
  @override
  final String unit;
  @override
  final int durationDays;
  @override
  final String observedEffect;
  @override
  final bool isDoseChangeMarker;
  @override
  final String? changeDirection;
// 'increased' | 'decreased'
  @override
  final String? changeReason;
  @override
  final DateTime? changeDate;

  @override
  String toString() {
    return 'HrtPhase(periodLabel: $periodLabel, drugName: $drugName, dose: $dose, unit: $unit, durationDays: $durationDays, observedEffect: $observedEffect, isDoseChangeMarker: $isDoseChangeMarker, changeDirection: $changeDirection, changeReason: $changeReason, changeDate: $changeDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HrtPhaseImpl &&
            (identical(other.periodLabel, periodLabel) ||
                other.periodLabel == periodLabel) &&
            (identical(other.drugName, drugName) ||
                other.drugName == drugName) &&
            (identical(other.dose, dose) || other.dose == dose) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.durationDays, durationDays) ||
                other.durationDays == durationDays) &&
            (identical(other.observedEffect, observedEffect) ||
                other.observedEffect == observedEffect) &&
            (identical(other.isDoseChangeMarker, isDoseChangeMarker) ||
                other.isDoseChangeMarker == isDoseChangeMarker) &&
            (identical(other.changeDirection, changeDirection) ||
                other.changeDirection == changeDirection) &&
            (identical(other.changeReason, changeReason) ||
                other.changeReason == changeReason) &&
            (identical(other.changeDate, changeDate) ||
                other.changeDate == changeDate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      periodLabel,
      drugName,
      dose,
      unit,
      durationDays,
      observedEffect,
      isDoseChangeMarker,
      changeDirection,
      changeReason,
      changeDate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HrtPhaseImplCopyWith<_$HrtPhaseImpl> get copyWith =>
      __$$HrtPhaseImplCopyWithImpl<_$HrtPhaseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HrtPhaseImplToJson(
      this,
    );
  }
}

abstract class _HrtPhase implements HrtPhase {
  const factory _HrtPhase(
      {required final String periodLabel,
      required final String drugName,
      required final double dose,
      required final String unit,
      required final int durationDays,
      required final String observedEffect,
      required final bool isDoseChangeMarker,
      final String? changeDirection,
      final String? changeReason,
      final DateTime? changeDate}) = _$HrtPhaseImpl;

  factory _HrtPhase.fromJson(Map<String, dynamic> json) =
      _$HrtPhaseImpl.fromJson;

  @override
  String get periodLabel;
  @override
  String get drugName;
  @override
  double get dose;
  @override
  String get unit;
  @override
  int get durationDays;
  @override
  String get observedEffect;
  @override
  bool get isDoseChangeMarker;
  @override
  String? get changeDirection;
  @override // 'increased' | 'decreased'
  String? get changeReason;
  @override
  DateTime? get changeDate;
  @override
  @JsonKey(ignore: true)
  _$$HrtPhaseImplCopyWith<_$HrtPhaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LogTableRow _$LogTableRowFromJson(Map<String, dynamic> json) {
  return _LogTableRow.fromJson(json);
}

/// @nodoc
mixin _$LogTableRow {
  DateTime get date => throw _privateConstructorUsedError;
  String get time => throw _privateConstructorUsedError;
  String get symptomsLogged => throw _privateConstructorUsedError;
  String get hrtTaken => throw _privateConstructorUsedError;
  String get triggers => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LogTableRowCopyWith<LogTableRow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LogTableRowCopyWith<$Res> {
  factory $LogTableRowCopyWith(
          LogTableRow value, $Res Function(LogTableRow) then) =
      _$LogTableRowCopyWithImpl<$Res, LogTableRow>;
  @useResult
  $Res call(
      {DateTime date,
      String time,
      String symptomsLogged,
      String hrtTaken,
      String triggers});
}

/// @nodoc
class _$LogTableRowCopyWithImpl<$Res, $Val extends LogTableRow>
    implements $LogTableRowCopyWith<$Res> {
  _$LogTableRowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? time = null,
    Object? symptomsLogged = null,
    Object? hrtTaken = null,
    Object? triggers = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      symptomsLogged: null == symptomsLogged
          ? _value.symptomsLogged
          : symptomsLogged // ignore: cast_nullable_to_non_nullable
              as String,
      hrtTaken: null == hrtTaken
          ? _value.hrtTaken
          : hrtTaken // ignore: cast_nullable_to_non_nullable
              as String,
      triggers: null == triggers
          ? _value.triggers
          : triggers // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LogTableRowImplCopyWith<$Res>
    implements $LogTableRowCopyWith<$Res> {
  factory _$$LogTableRowImplCopyWith(
          _$LogTableRowImpl value, $Res Function(_$LogTableRowImpl) then) =
      __$$LogTableRowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime date,
      String time,
      String symptomsLogged,
      String hrtTaken,
      String triggers});
}

/// @nodoc
class __$$LogTableRowImplCopyWithImpl<$Res>
    extends _$LogTableRowCopyWithImpl<$Res, _$LogTableRowImpl>
    implements _$$LogTableRowImplCopyWith<$Res> {
  __$$LogTableRowImplCopyWithImpl(
      _$LogTableRowImpl _value, $Res Function(_$LogTableRowImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? time = null,
    Object? symptomsLogged = null,
    Object? hrtTaken = null,
    Object? triggers = null,
  }) {
    return _then(_$LogTableRowImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      symptomsLogged: null == symptomsLogged
          ? _value.symptomsLogged
          : symptomsLogged // ignore: cast_nullable_to_non_nullable
              as String,
      hrtTaken: null == hrtTaken
          ? _value.hrtTaken
          : hrtTaken // ignore: cast_nullable_to_non_nullable
              as String,
      triggers: null == triggers
          ? _value.triggers
          : triggers // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LogTableRowImpl implements _LogTableRow {
  const _$LogTableRowImpl(
      {required this.date,
      required this.time,
      required this.symptomsLogged,
      required this.hrtTaken,
      required this.triggers});

  factory _$LogTableRowImpl.fromJson(Map<String, dynamic> json) =>
      _$$LogTableRowImplFromJson(json);

  @override
  final DateTime date;
  @override
  final String time;
  @override
  final String symptomsLogged;
  @override
  final String hrtTaken;
  @override
  final String triggers;

  @override
  String toString() {
    return 'LogTableRow(date: $date, time: $time, symptomsLogged: $symptomsLogged, hrtTaken: $hrtTaken, triggers: $triggers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LogTableRowImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.symptomsLogged, symptomsLogged) ||
                other.symptomsLogged == symptomsLogged) &&
            (identical(other.hrtTaken, hrtTaken) ||
                other.hrtTaken == hrtTaken) &&
            (identical(other.triggers, triggers) ||
                other.triggers == triggers));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, date, time, symptomsLogged, hrtTaken, triggers);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LogTableRowImplCopyWith<_$LogTableRowImpl> get copyWith =>
      __$$LogTableRowImplCopyWithImpl<_$LogTableRowImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LogTableRowImplToJson(
      this,
    );
  }
}

abstract class _LogTableRow implements LogTableRow {
  const factory _LogTableRow(
      {required final DateTime date,
      required final String time,
      required final String symptomsLogged,
      required final String hrtTaken,
      required final String triggers}) = _$LogTableRowImpl;

  factory _LogTableRow.fromJson(Map<String, dynamic> json) =
      _$LogTableRowImpl.fromJson;

  @override
  DateTime get date;
  @override
  String get time;
  @override
  String get symptomsLogged;
  @override
  String get hrtTaken;
  @override
  String get triggers;
  @override
  @JsonKey(ignore: true)
  _$$LogTableRowImplCopyWith<_$LogTableRowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PassportData _$PassportDataFromJson(Map<String, dynamic> json) {
  return _PassportData.fromJson(json);
}

/// @nodoc
mixin _$PassportData {
  String get displayName => throw _privateConstructorUsedError;
  DateTime? get dateOfBirth => throw _privateConstructorUsedError;
  String get stage => throw _privateConstructorUsedError;
  DateTime get firstLogDate => throw _privateConstructorUsedError;
  DateTime get reportStart => throw _privateConstructorUsedError;
  DateTime get reportEnd => throw _privateConstructorUsedError;
  int get totalEntries => throw _privateConstructorUsedError;
  List<CurrentHrtSummary> get currentHrt => throw _privateConstructorUsedError;
  List<SymptomStatRow> get symptomStats => throw _privateConstructorUsedError;
  ChartData get hotFlashFrequency => throw _privateConstructorUsedError;
  ChartData get sleepQualityRollingAvg => throw _privateConstructorUsedError;
  ChartData get moodStackedWeekly => throw _privateConstructorUsedError;
  List<InsightResult> get topPatterns => throw _privateConstructorUsedError;
  List<HrtPhase> get hrtHistory => throw _privateConstructorUsedError;
  List<LogTableRow> get fullLog => throw _privateConstructorUsedError;
  DateTime get generatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PassportDataCopyWith<PassportData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PassportDataCopyWith<$Res> {
  factory $PassportDataCopyWith(
          PassportData value, $Res Function(PassportData) then) =
      _$PassportDataCopyWithImpl<$Res, PassportData>;
  @useResult
  $Res call(
      {String displayName,
      DateTime? dateOfBirth,
      String stage,
      DateTime firstLogDate,
      DateTime reportStart,
      DateTime reportEnd,
      int totalEntries,
      List<CurrentHrtSummary> currentHrt,
      List<SymptomStatRow> symptomStats,
      ChartData hotFlashFrequency,
      ChartData sleepQualityRollingAvg,
      ChartData moodStackedWeekly,
      List<InsightResult> topPatterns,
      List<HrtPhase> hrtHistory,
      List<LogTableRow> fullLog,
      DateTime generatedAt});

  $ChartDataCopyWith<$Res> get hotFlashFrequency;
  $ChartDataCopyWith<$Res> get sleepQualityRollingAvg;
  $ChartDataCopyWith<$Res> get moodStackedWeekly;
}

/// @nodoc
class _$PassportDataCopyWithImpl<$Res, $Val extends PassportData>
    implements $PassportDataCopyWith<$Res> {
  _$PassportDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? displayName = null,
    Object? dateOfBirth = freezed,
    Object? stage = null,
    Object? firstLogDate = null,
    Object? reportStart = null,
    Object? reportEnd = null,
    Object? totalEntries = null,
    Object? currentHrt = null,
    Object? symptomStats = null,
    Object? hotFlashFrequency = null,
    Object? sleepQualityRollingAvg = null,
    Object? moodStackedWeekly = null,
    Object? topPatterns = null,
    Object? hrtHistory = null,
    Object? fullLog = null,
    Object? generatedAt = null,
  }) {
    return _then(_value.copyWith(
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stage: null == stage
          ? _value.stage
          : stage // ignore: cast_nullable_to_non_nullable
              as String,
      firstLogDate: null == firstLogDate
          ? _value.firstLogDate
          : firstLogDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reportStart: null == reportStart
          ? _value.reportStart
          : reportStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reportEnd: null == reportEnd
          ? _value.reportEnd
          : reportEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalEntries: null == totalEntries
          ? _value.totalEntries
          : totalEntries // ignore: cast_nullable_to_non_nullable
              as int,
      currentHrt: null == currentHrt
          ? _value.currentHrt
          : currentHrt // ignore: cast_nullable_to_non_nullable
              as List<CurrentHrtSummary>,
      symptomStats: null == symptomStats
          ? _value.symptomStats
          : symptomStats // ignore: cast_nullable_to_non_nullable
              as List<SymptomStatRow>,
      hotFlashFrequency: null == hotFlashFrequency
          ? _value.hotFlashFrequency
          : hotFlashFrequency // ignore: cast_nullable_to_non_nullable
              as ChartData,
      sleepQualityRollingAvg: null == sleepQualityRollingAvg
          ? _value.sleepQualityRollingAvg
          : sleepQualityRollingAvg // ignore: cast_nullable_to_non_nullable
              as ChartData,
      moodStackedWeekly: null == moodStackedWeekly
          ? _value.moodStackedWeekly
          : moodStackedWeekly // ignore: cast_nullable_to_non_nullable
              as ChartData,
      topPatterns: null == topPatterns
          ? _value.topPatterns
          : topPatterns // ignore: cast_nullable_to_non_nullable
              as List<InsightResult>,
      hrtHistory: null == hrtHistory
          ? _value.hrtHistory
          : hrtHistory // ignore: cast_nullable_to_non_nullable
              as List<HrtPhase>,
      fullLog: null == fullLog
          ? _value.fullLog
          : fullLog // ignore: cast_nullable_to_non_nullable
              as List<LogTableRow>,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ChartDataCopyWith<$Res> get hotFlashFrequency {
    return $ChartDataCopyWith<$Res>(_value.hotFlashFrequency, (value) {
      return _then(_value.copyWith(hotFlashFrequency: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $ChartDataCopyWith<$Res> get sleepQualityRollingAvg {
    return $ChartDataCopyWith<$Res>(_value.sleepQualityRollingAvg, (value) {
      return _then(_value.copyWith(sleepQualityRollingAvg: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $ChartDataCopyWith<$Res> get moodStackedWeekly {
    return $ChartDataCopyWith<$Res>(_value.moodStackedWeekly, (value) {
      return _then(_value.copyWith(moodStackedWeekly: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PassportDataImplCopyWith<$Res>
    implements $PassportDataCopyWith<$Res> {
  factory _$$PassportDataImplCopyWith(
          _$PassportDataImpl value, $Res Function(_$PassportDataImpl) then) =
      __$$PassportDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String displayName,
      DateTime? dateOfBirth,
      String stage,
      DateTime firstLogDate,
      DateTime reportStart,
      DateTime reportEnd,
      int totalEntries,
      List<CurrentHrtSummary> currentHrt,
      List<SymptomStatRow> symptomStats,
      ChartData hotFlashFrequency,
      ChartData sleepQualityRollingAvg,
      ChartData moodStackedWeekly,
      List<InsightResult> topPatterns,
      List<HrtPhase> hrtHistory,
      List<LogTableRow> fullLog,
      DateTime generatedAt});

  @override
  $ChartDataCopyWith<$Res> get hotFlashFrequency;
  @override
  $ChartDataCopyWith<$Res> get sleepQualityRollingAvg;
  @override
  $ChartDataCopyWith<$Res> get moodStackedWeekly;
}

/// @nodoc
class __$$PassportDataImplCopyWithImpl<$Res>
    extends _$PassportDataCopyWithImpl<$Res, _$PassportDataImpl>
    implements _$$PassportDataImplCopyWith<$Res> {
  __$$PassportDataImplCopyWithImpl(
      _$PassportDataImpl _value, $Res Function(_$PassportDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? displayName = null,
    Object? dateOfBirth = freezed,
    Object? stage = null,
    Object? firstLogDate = null,
    Object? reportStart = null,
    Object? reportEnd = null,
    Object? totalEntries = null,
    Object? currentHrt = null,
    Object? symptomStats = null,
    Object? hotFlashFrequency = null,
    Object? sleepQualityRollingAvg = null,
    Object? moodStackedWeekly = null,
    Object? topPatterns = null,
    Object? hrtHistory = null,
    Object? fullLog = null,
    Object? generatedAt = null,
  }) {
    return _then(_$PassportDataImpl(
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stage: null == stage
          ? _value.stage
          : stage // ignore: cast_nullable_to_non_nullable
              as String,
      firstLogDate: null == firstLogDate
          ? _value.firstLogDate
          : firstLogDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reportStart: null == reportStart
          ? _value.reportStart
          : reportStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      reportEnd: null == reportEnd
          ? _value.reportEnd
          : reportEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalEntries: null == totalEntries
          ? _value.totalEntries
          : totalEntries // ignore: cast_nullable_to_non_nullable
              as int,
      currentHrt: null == currentHrt
          ? _value._currentHrt
          : currentHrt // ignore: cast_nullable_to_non_nullable
              as List<CurrentHrtSummary>,
      symptomStats: null == symptomStats
          ? _value._symptomStats
          : symptomStats // ignore: cast_nullable_to_non_nullable
              as List<SymptomStatRow>,
      hotFlashFrequency: null == hotFlashFrequency
          ? _value.hotFlashFrequency
          : hotFlashFrequency // ignore: cast_nullable_to_non_nullable
              as ChartData,
      sleepQualityRollingAvg: null == sleepQualityRollingAvg
          ? _value.sleepQualityRollingAvg
          : sleepQualityRollingAvg // ignore: cast_nullable_to_non_nullable
              as ChartData,
      moodStackedWeekly: null == moodStackedWeekly
          ? _value.moodStackedWeekly
          : moodStackedWeekly // ignore: cast_nullable_to_non_nullable
              as ChartData,
      topPatterns: null == topPatterns
          ? _value._topPatterns
          : topPatterns // ignore: cast_nullable_to_non_nullable
              as List<InsightResult>,
      hrtHistory: null == hrtHistory
          ? _value._hrtHistory
          : hrtHistory // ignore: cast_nullable_to_non_nullable
              as List<HrtPhase>,
      fullLog: null == fullLog
          ? _value._fullLog
          : fullLog // ignore: cast_nullable_to_non_nullable
              as List<LogTableRow>,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PassportDataImpl implements _PassportData {
  const _$PassportDataImpl(
      {required this.displayName,
      this.dateOfBirth,
      required this.stage,
      required this.firstLogDate,
      required this.reportStart,
      required this.reportEnd,
      required this.totalEntries,
      required final List<CurrentHrtSummary> currentHrt,
      required final List<SymptomStatRow> symptomStats,
      required this.hotFlashFrequency,
      required this.sleepQualityRollingAvg,
      required this.moodStackedWeekly,
      required final List<InsightResult> topPatterns,
      required final List<HrtPhase> hrtHistory,
      required final List<LogTableRow> fullLog,
      required this.generatedAt})
      : _currentHrt = currentHrt,
        _symptomStats = symptomStats,
        _topPatterns = topPatterns,
        _hrtHistory = hrtHistory,
        _fullLog = fullLog;

  factory _$PassportDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$PassportDataImplFromJson(json);

  @override
  final String displayName;
  @override
  final DateTime? dateOfBirth;
  @override
  final String stage;
  @override
  final DateTime firstLogDate;
  @override
  final DateTime reportStart;
  @override
  final DateTime reportEnd;
  @override
  final int totalEntries;
  final List<CurrentHrtSummary> _currentHrt;
  @override
  List<CurrentHrtSummary> get currentHrt {
    if (_currentHrt is EqualUnmodifiableListView) return _currentHrt;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_currentHrt);
  }

  final List<SymptomStatRow> _symptomStats;
  @override
  List<SymptomStatRow> get symptomStats {
    if (_symptomStats is EqualUnmodifiableListView) return _symptomStats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_symptomStats);
  }

  @override
  final ChartData hotFlashFrequency;
  @override
  final ChartData sleepQualityRollingAvg;
  @override
  final ChartData moodStackedWeekly;
  final List<InsightResult> _topPatterns;
  @override
  List<InsightResult> get topPatterns {
    if (_topPatterns is EqualUnmodifiableListView) return _topPatterns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topPatterns);
  }

  final List<HrtPhase> _hrtHistory;
  @override
  List<HrtPhase> get hrtHistory {
    if (_hrtHistory is EqualUnmodifiableListView) return _hrtHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hrtHistory);
  }

  final List<LogTableRow> _fullLog;
  @override
  List<LogTableRow> get fullLog {
    if (_fullLog is EqualUnmodifiableListView) return _fullLog;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fullLog);
  }

  @override
  final DateTime generatedAt;

  @override
  String toString() {
    return 'PassportData(displayName: $displayName, dateOfBirth: $dateOfBirth, stage: $stage, firstLogDate: $firstLogDate, reportStart: $reportStart, reportEnd: $reportEnd, totalEntries: $totalEntries, currentHrt: $currentHrt, symptomStats: $symptomStats, hotFlashFrequency: $hotFlashFrequency, sleepQualityRollingAvg: $sleepQualityRollingAvg, moodStackedWeekly: $moodStackedWeekly, topPatterns: $topPatterns, hrtHistory: $hrtHistory, fullLog: $fullLog, generatedAt: $generatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PassportDataImpl &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.stage, stage) || other.stage == stage) &&
            (identical(other.firstLogDate, firstLogDate) ||
                other.firstLogDate == firstLogDate) &&
            (identical(other.reportStart, reportStart) ||
                other.reportStart == reportStart) &&
            (identical(other.reportEnd, reportEnd) ||
                other.reportEnd == reportEnd) &&
            (identical(other.totalEntries, totalEntries) ||
                other.totalEntries == totalEntries) &&
            const DeepCollectionEquality()
                .equals(other._currentHrt, _currentHrt) &&
            const DeepCollectionEquality()
                .equals(other._symptomStats, _symptomStats) &&
            (identical(other.hotFlashFrequency, hotFlashFrequency) ||
                other.hotFlashFrequency == hotFlashFrequency) &&
            (identical(other.sleepQualityRollingAvg, sleepQualityRollingAvg) ||
                other.sleepQualityRollingAvg == sleepQualityRollingAvg) &&
            (identical(other.moodStackedWeekly, moodStackedWeekly) ||
                other.moodStackedWeekly == moodStackedWeekly) &&
            const DeepCollectionEquality()
                .equals(other._topPatterns, _topPatterns) &&
            const DeepCollectionEquality()
                .equals(other._hrtHistory, _hrtHistory) &&
            const DeepCollectionEquality().equals(other._fullLog, _fullLog) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      displayName,
      dateOfBirth,
      stage,
      firstLogDate,
      reportStart,
      reportEnd,
      totalEntries,
      const DeepCollectionEquality().hash(_currentHrt),
      const DeepCollectionEquality().hash(_symptomStats),
      hotFlashFrequency,
      sleepQualityRollingAvg,
      moodStackedWeekly,
      const DeepCollectionEquality().hash(_topPatterns),
      const DeepCollectionEquality().hash(_hrtHistory),
      const DeepCollectionEquality().hash(_fullLog),
      generatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PassportDataImplCopyWith<_$PassportDataImpl> get copyWith =>
      __$$PassportDataImplCopyWithImpl<_$PassportDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PassportDataImplToJson(
      this,
    );
  }
}

abstract class _PassportData implements PassportData {
  const factory _PassportData(
      {required final String displayName,
      final DateTime? dateOfBirth,
      required final String stage,
      required final DateTime firstLogDate,
      required final DateTime reportStart,
      required final DateTime reportEnd,
      required final int totalEntries,
      required final List<CurrentHrtSummary> currentHrt,
      required final List<SymptomStatRow> symptomStats,
      required final ChartData hotFlashFrequency,
      required final ChartData sleepQualityRollingAvg,
      required final ChartData moodStackedWeekly,
      required final List<InsightResult> topPatterns,
      required final List<HrtPhase> hrtHistory,
      required final List<LogTableRow> fullLog,
      required final DateTime generatedAt}) = _$PassportDataImpl;

  factory _PassportData.fromJson(Map<String, dynamic> json) =
      _$PassportDataImpl.fromJson;

  @override
  String get displayName;
  @override
  DateTime? get dateOfBirth;
  @override
  String get stage;
  @override
  DateTime get firstLogDate;
  @override
  DateTime get reportStart;
  @override
  DateTime get reportEnd;
  @override
  int get totalEntries;
  @override
  List<CurrentHrtSummary> get currentHrt;
  @override
  List<SymptomStatRow> get symptomStats;
  @override
  ChartData get hotFlashFrequency;
  @override
  ChartData get sleepQualityRollingAvg;
  @override
  ChartData get moodStackedWeekly;
  @override
  List<InsightResult> get topPatterns;
  @override
  List<HrtPhase> get hrtHistory;
  @override
  List<LogTableRow> get fullLog;
  @override
  DateTime get generatedAt;
  @override
  @JsonKey(ignore: true)
  _$$PassportDataImplCopyWith<_$PassportDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
