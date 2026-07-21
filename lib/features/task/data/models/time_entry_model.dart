import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/time_entry_entity.dart';
import '../../domain/entities/time_entry_origin_enum.dart';
import '../../domain/entities/timer_target_type_enum.dart';

part 'time_entry_model.g.dart';

@JsonSerializable(includeIfNull: false)
class TimeEntryModel {
  const TimeEntryModel({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.listId,
    required this.minutes,
    required this.origin,
    required this.occurredAt,
  });

  @JsonKey(includeToJson: false)
  final String id;
  final String targetId;
  final TimerTargetTypeEnum targetType;
  final String listId;
  final int minutes;
  final TimeEntryOriginEnum origin;
  @TimestampConverter()
  final DateTime? occurredAt;

  factory TimeEntryModel.fromDoc(String id, Map<String, dynamic> data) =>
      TimeEntryModel.fromJson({...data, 'id': id});

  factory TimeEntryModel.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$TimeEntryModelToJson(this);

  TimeEntryEntity toEntity() => TimeEntryEntity(
        id: id,
        targetId: targetId,
        targetType: targetType,
        listId: listId,
        minutes: minutes,
        origin: origin,
        occurredAt: occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );

  factory TimeEntryModel.fromEntity(TimeEntryEntity e) => TimeEntryModel(
        id: e.id,
        targetId: e.targetId,
        targetType: e.targetType,
        listId: e.listId,
        minutes: e.minutes,
        origin: e.origin,
        occurredAt: e.occurredAt,
      );
}
