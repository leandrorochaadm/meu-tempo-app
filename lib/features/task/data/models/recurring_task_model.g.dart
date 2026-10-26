// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringTaskModel _$RecurringTaskModelFromJson(Map<String, dynamic> json) =>
    RecurringTaskModel.raw(
      id: json['id'] as String,
      title: json['title'] as String,
      listId: json['list'] as String,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 0,
      importance: json['importance'] as String?,
      weekdays: json['weekdays'] == null
          ? const []
          : _rawWeekdays(json['weekdays']),
      createdAt: const InstantConverter().fromJson(
        json['created_at'] as String?,
      ),
      lastGeneratedOn: const CalendarDateConverter().fromJson(
        json['last_generated_on'] as String?,
      ),
    );

Map<String, dynamic> _$RecurringTaskModelToJson(RecurringTaskModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'list': instance.listId,
      'estimated_minutes': instance.estimatedMinutes,
      'importance': instance.importance,
      'weekdays': instance.weekdays,
      'created_at': const InstantConverter().toJson(instance.createdAt),
      'last_generated_on': const CalendarDateConverter().toJson(
        instance.lastGeneratedOn,
      ),
    };
