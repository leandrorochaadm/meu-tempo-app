// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_timer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActiveTimerModel _$ActiveTimerModelFromJson(Map<String, dynamic> json) =>
    ActiveTimerModel(
      targetId: json['target_id'] as String,
      startedAt: const InstantConverter().fromJson(
        json['started_at'] as String?,
      ),
      targetType: json['target_type'] as String?,
      listId: json['list_id'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$ActiveTimerModelToJson(ActiveTimerModel instance) =>
    <String, dynamic>{
      'target_id': instance.targetId,
      'started_at': const InstantConverter().toJson(instance.startedAt),
      'target_type': instance.targetType,
      'list_id': instance.listId,
      'status': instance.status,
    };
