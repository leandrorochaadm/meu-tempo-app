// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DayConfigModel _$DayConfigModelFromJson(Map<String, dynamic> json) =>
    DayConfigModel(
      availableMinutesPerDay:
          (json['availableMinutesPerDay'] as num?)?.toInt() ?? 480,
    );

Map<String, dynamic> _$DayConfigModelToJson(DayConfigModel instance) =>
    <String, dynamic>{
      'availableMinutesPerDay': instance.availableMinutesPerDay,
    };
