// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeEntryModel _$TimeEntryModelFromJson(Map<String, dynamic> json) =>
    TimeEntryModel.raw(
      id: json['id'] as String,
      targetId: json['target_id'] as String,
      targetType: json['target_type'] as String?,
      listId: json['list_id'] as String,
      minutes: (json['minutes'] as num).toInt(),
      origin: json['origin'] as String?,
      occurredAt: const InstantConverter().fromJson(
        json['occurred_at'] as String?,
      ),
    );

Map<String, dynamic> _$TimeEntryModelToJson(TimeEntryModel instance) =>
    <String, dynamic>{
      'target_id': instance.targetId,
      'target_type': instance.targetType,
      'list_id': instance.listId,
      'minutes': instance.minutes,
      'origin': instance.origin,
      'occurred_at': const InstantConverter().toJson(instance.occurredAt),
    };
