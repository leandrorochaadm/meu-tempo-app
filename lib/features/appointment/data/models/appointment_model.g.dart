// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentModel _$AppointmentModelFromJson(Map<String, dynamic> json) =>
    AppointmentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      listId: json['listId'] as String,
      date: const TimestampConverter().fromJson(json['date'] as Timestamp?),
      startMinute: (json['startMinute'] as num).toInt(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      spentMinutes: (json['spentMinutes'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AppointmentModelToJson(AppointmentModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'listId': instance.listId,
      'date': ?const TimestampConverter().toJson(instance.date),
      'startMinute': instance.startMinute,
      'durationMinutes': instance.durationMinutes,
      'spentMinutes': instance.spentMinutes,
    };
