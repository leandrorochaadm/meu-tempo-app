// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DayConfigModel _$DayConfigModelFromJson(Map<String, dynamic> json) =>
    DayConfigModel(
      availableMinutesPerDay:
          (json['available_minutes_per_day'] as num?)?.toInt() ?? 480,
      onboarded: json['onboarded'] as bool? ?? false,
    );

Map<String, dynamic> _$DayConfigModelToJson(DayConfigModel instance) =>
    <String, dynamic>{
      'available_minutes_per_day': instance.availableMinutesPerDay,
      'onboarded': instance.onboarded,
    };
