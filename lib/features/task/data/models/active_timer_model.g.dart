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
    );

Map<String, dynamic> _$ActiveTimerModelToJson(ActiveTimerModel instance) =>
    <String, dynamic>{
      'targetId': instance.targetId,
      'startedAt': ?const TimestampConverter().toJson(instance.startedAt),
    };
