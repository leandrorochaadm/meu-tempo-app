// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentModel _$AppointmentModelFromJson(Map<String, dynamic> json) =>
    AppointmentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      listId: json['list_id'] as String,
      date: const CalendarDateConverter().fromJson(json['date'] as String?),
      startMinute: (json['start_minute'] as num).toInt(),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      spentMinutes: (json['spent_minutes'] as num?)?.toInt() ?? 0,
      isDone: json['is_done'] as bool? ?? false,
    );

Map<String, dynamic> _$AppointmentModelToJson(AppointmentModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'list_id': instance.listId,
      'date': const CalendarDateConverter().toJson(instance.date),
      'start_minute': instance.startMinute,
      'duration_minutes': instance.durationMinutes,
      'spent_minutes': instance.spentMinutes,
      'is_done': instance.isDone,
    };
