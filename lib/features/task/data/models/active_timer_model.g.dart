// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_timer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActiveTimerModel _$ActiveTimerModelFromJson(Map<String, dynamic> json) =>
    ActiveTimerModel(
      targetId: json['targetId'] as String,
      startedAt: const TimestampConverter().fromJson(
        json['startedAt'] as Timestamp?,
      ),
      targetType: $enumDecodeNullable(
        _$TimerTargetTypeEnumEnumMap,
        json['targetType'],
      ),
      listId: json['listId'] as String?,
    );

Map<String, dynamic> _$ActiveTimerModelToJson(ActiveTimerModel instance) =>
    <String, dynamic>{
      'targetId': instance.targetId,
      'startedAt': ?const TimestampConverter().toJson(instance.startedAt),
      'targetType': ?_$TimerTargetTypeEnumEnumMap[instance.targetType],
      'listId': ?instance.listId,
    };

const _$TimerTargetTypeEnumEnumMap = {
  TimerTargetTypeEnum.task: 'task',
  TimerTargetTypeEnum.appointment: 'appointment',
};
