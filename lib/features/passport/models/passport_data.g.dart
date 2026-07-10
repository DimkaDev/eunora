// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passport_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CurrentHrtSummaryImpl _$$CurrentHrtSummaryImplFromJson(
        Map<String, dynamic> json) =>
    _$CurrentHrtSummaryImpl(
      drugName: json['drugName'] as String,
      doseValue: (json['doseValue'] as num).toDouble(),
      doseUnit: json['doseUnit'] as String,
      form: json['form'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
    );

Map<String, dynamic> _$$CurrentHrtSummaryImplToJson(
        _$CurrentHrtSummaryImpl instance) =>
    <String, dynamic>{
      'drugName': instance.drugName,
      'doseValue': instance.doseValue,
      'doseUnit': instance.doseUnit,
      'form': instance.form,
      'startDate': instance.startDate.toIso8601String(),
    };

_$SymptomStatRowImpl _$$SymptomStatRowImplFromJson(Map<String, dynamic> json) =>
    _$SymptomStatRowImpl(
      category: json['category'] as String,
      daysLogged: (json['daysLogged'] as num).toInt(),
      avgSeverity: (json['avgSeverity'] as num).toDouble(),
      peakDay: json['peakDay'] == null
          ? null
          : DateTime.parse(json['peakDay'] as String),
      trend: json['trend'] as String,
    );

Map<String, dynamic> _$$SymptomStatRowImplToJson(
        _$SymptomStatRowImpl instance) =>
    <String, dynamic>{
      'category': instance.category,
      'daysLogged': instance.daysLogged,
      'avgSeverity': instance.avgSeverity,
      'peakDay': instance.peakDay?.toIso8601String(),
      'trend': instance.trend,
    };

_$ChartDataPointImpl _$$ChartDataPointImplFromJson(Map<String, dynamic> json) =>
    _$ChartDataPointImpl(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );

Map<String, dynamic> _$$ChartDataPointImplToJson(
        _$ChartDataPointImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'value': instance.value,
    };

_$WeeklyMoodPointImpl _$$WeeklyMoodPointImplFromJson(
        Map<String, dynamic> json) =>
    _$WeeklyMoodPointImpl(
      weekStart: DateTime.parse(json['weekStart'] as String),
      anxiety: (json['anxiety'] as num).toDouble(),
      irritability: (json['irritability'] as num).toDouble(),
      brainFog: (json['brainFog'] as num).toDouble(),
    );

Map<String, dynamic> _$$WeeklyMoodPointImplToJson(
        _$WeeklyMoodPointImpl instance) =>
    <String, dynamic>{
      'weekStart': instance.weekStart.toIso8601String(),
      'anxiety': instance.anxiety,
      'irritability': instance.irritability,
      'brainFog': instance.brainFog,
    };

_$ChartDataImpl _$$ChartDataImplFromJson(Map<String, dynamic> json) =>
    _$ChartDataImpl(
      points: (json['points'] as List<dynamic>)
          .map((e) => ChartDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      weeklyMoods: (json['weeklyMoods'] as List<dynamic>?)
              ?.map((e) => WeeklyMoodPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ChartDataImplToJson(_$ChartDataImpl instance) =>
    <String, dynamic>{
      'points': instance.points,
      'weeklyMoods': instance.weeklyMoods,
    };

_$HrtPhaseImpl _$$HrtPhaseImplFromJson(Map<String, dynamic> json) =>
    _$HrtPhaseImpl(
      periodLabel: json['periodLabel'] as String,
      drugName: json['drugName'] as String,
      dose: (json['dose'] as num).toDouble(),
      unit: json['unit'] as String,
      durationDays: (json['durationDays'] as num).toInt(),
      observedEffect: json['observedEffect'] as String,
      isDoseChangeMarker: json['isDoseChangeMarker'] as bool,
      changeDirection: json['changeDirection'] as String?,
      changeReason: json['changeReason'] as String?,
      changeDate: json['changeDate'] == null
          ? null
          : DateTime.parse(json['changeDate'] as String),
    );

Map<String, dynamic> _$$HrtPhaseImplToJson(_$HrtPhaseImpl instance) =>
    <String, dynamic>{
      'periodLabel': instance.periodLabel,
      'drugName': instance.drugName,
      'dose': instance.dose,
      'unit': instance.unit,
      'durationDays': instance.durationDays,
      'observedEffect': instance.observedEffect,
      'isDoseChangeMarker': instance.isDoseChangeMarker,
      'changeDirection': instance.changeDirection,
      'changeReason': instance.changeReason,
      'changeDate': instance.changeDate?.toIso8601String(),
    };

_$LogTableRowImpl _$$LogTableRowImplFromJson(Map<String, dynamic> json) =>
    _$LogTableRowImpl(
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      symptomsLogged: json['symptomsLogged'] as String,
      hrtTaken: json['hrtTaken'] as String,
      triggers: json['triggers'] as String,
    );

Map<String, dynamic> _$$LogTableRowImplToJson(_$LogTableRowImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'time': instance.time,
      'symptomsLogged': instance.symptomsLogged,
      'hrtTaken': instance.hrtTaken,
      'triggers': instance.triggers,
    };

_$PassportDataImpl _$$PassportDataImplFromJson(Map<String, dynamic> json) =>
    _$PassportDataImpl(
      displayName: json['displayName'] as String,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
      stage: json['stage'] as String,
      firstLogDate: DateTime.parse(json['firstLogDate'] as String),
      reportStart: DateTime.parse(json['reportStart'] as String),
      reportEnd: DateTime.parse(json['reportEnd'] as String),
      totalEntries: (json['totalEntries'] as num).toInt(),
      currentHrt: (json['currentHrt'] as List<dynamic>)
          .map((e) => CurrentHrtSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      symptomStats: (json['symptomStats'] as List<dynamic>)
          .map((e) => SymptomStatRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      hotFlashFrequency:
          ChartData.fromJson(json['hotFlashFrequency'] as Map<String, dynamic>),
      sleepQualityRollingAvg: ChartData.fromJson(
          json['sleepQualityRollingAvg'] as Map<String, dynamic>),
      moodStackedWeekly:
          ChartData.fromJson(json['moodStackedWeekly'] as Map<String, dynamic>),
      topPatterns: (json['topPatterns'] as List<dynamic>)
          .map((e) => InsightResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      hrtHistory: (json['hrtHistory'] as List<dynamic>)
          .map((e) => HrtPhase.fromJson(e as Map<String, dynamic>))
          .toList(),
      fullLog: (json['fullLog'] as List<dynamic>)
          .map((e) => LogTableRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$$PassportDataImplToJson(_$PassportDataImpl instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
      'stage': instance.stage,
      'firstLogDate': instance.firstLogDate.toIso8601String(),
      'reportStart': instance.reportStart.toIso8601String(),
      'reportEnd': instance.reportEnd.toIso8601String(),
      'totalEntries': instance.totalEntries,
      'currentHrt': instance.currentHrt,
      'symptomStats': instance.symptomStats,
      'hotFlashFrequency': instance.hotFlashFrequency,
      'sleepQualityRollingAvg': instance.sleepQualityRollingAvg,
      'moodStackedWeekly': instance.moodStackedWeekly,
      'topPatterns': instance.topPatterns,
      'hrtHistory': instance.hrtHistory,
      'fullLog': instance.fullLog,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };
