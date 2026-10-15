// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringTaskModel _$RecurringTaskModelFromJson(Map<String, dynamic> json) =>
    RecurringTaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      listId: json['listId'] as String,
      estimatedMinutes: (json['estimatedMinutes'] as num).toInt(),
      importance: $enumDecode(_$ImportanceEnumEnumMap, json['importance']),
      weekdays:
          (json['weekdays'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$WeekdayEnumEnumMap, e))
              .toList() ??
          const [],
      createdAt: const TimestampConverter().fromJson(
        json['createdAt'] as Timestamp?,
      ),
      lastGeneratedOn: const TimestampConverter().fromJson(
        json['lastGeneratedOn'] as Timestamp?,
      ),
    );

Map<String, dynamic> _$RecurringTaskModelToJson(
  RecurringTaskModel instance,
) => <String, dynamic>{
  'title': instance.title,
  'listId': instance.listId,
  'estimatedMinutes': instance.estimatedMinutes,
  'importance': _$ImportanceEnumEnumMap[instance.importance]!,
  'weekdays': instance.weekdays.map((e) => _$WeekdayEnumEnumMap[e]!).toList(),
  'createdAt': ?const TimestampConverter().toJson(instance.createdAt),
  'lastGeneratedOn': ?const TimestampConverter().toJson(
    instance.lastGeneratedOn,
  ),
};

const _$ImportanceEnumEnumMap = {
  ImportanceEnum.max: 'max',
  ImportanceEnum.high: 'high',
  ImportanceEnum.low: 'low',
  ImportanceEnum.min: 'min',
};

const _$WeekdayEnumEnumMap = {
  WeekdayEnum.monday: 'monday',
  WeekdayEnum.tuesday: 'tuesday',
  WeekdayEnum.wednesday: 'wednesday',
  WeekdayEnum.thursday: 'thursday',
  WeekdayEnum.friday: 'friday',
  WeekdayEnum.saturday: 'saturday',
  WeekdayEnum.sunday: 'sunday',
};
