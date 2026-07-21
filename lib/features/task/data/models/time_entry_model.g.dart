// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeEntryModel _$TimeEntryModelFromJson(Map<String, dynamic> json) =>
    TimeEntryModel(
      id: json['id'] as String,
      targetId: json['targetId'] as String,
      targetType: $enumDecode(_$TimerTargetTypeEnumEnumMap, json['targetType']),
      listId: json['listId'] as String,
      minutes: (json['minutes'] as num).toInt(),
      origin: $enumDecode(_$TimeEntryOriginEnumEnumMap, json['origin']),
      occurredAt: const TimestampConverter().fromJson(
        json['occurredAt'] as Timestamp?,
      ),
    );

Map<String, dynamic> _$TimeEntryModelToJson(TimeEntryModel instance) =>
    <String, dynamic>{
      'targetId': instance.targetId,
      'targetType': _$TimerTargetTypeEnumEnumMap[instance.targetType]!,
      'listId': instance.listId,
      'minutes': instance.minutes,
      'origin': _$TimeEntryOriginEnumEnumMap[instance.origin]!,
      'occurredAt': ?const TimestampConverter().toJson(instance.occurredAt),
    };

const _$TimerTargetTypeEnumEnumMap = {
  TimerTargetTypeEnum.task: 'task',
  TimerTargetTypeEnum.appointment: 'appointment',
};

const _$TimeEntryOriginEnumEnumMap = {
  TimeEntryOriginEnum.timer: 'timer',
  TimeEntryOriginEnum.manual: 'manual',
};
