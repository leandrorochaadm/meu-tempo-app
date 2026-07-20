import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/active_timer_entity.dart';

part 'active_timer_model.g.dart';

@JsonSerializable(includeIfNull: false)
class ActiveTimerModel {
  const ActiveTimerModel({required this.targetId, required this.startedAt});

  final String targetId;
  @TimestampConverter()
  final DateTime? startedAt;

  factory ActiveTimerModel.fromJson(Map<String, dynamic> json) =>
      _$ActiveTimerModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveTimerModelToJson(this);

  ActiveTimerEntity toEntity() => ActiveTimerEntity(
        targetId: targetId,
        startedAt: startedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );

  factory ActiveTimerModel.fromEntity(ActiveTimerEntity e) =>
      ActiveTimerModel(targetId: e.targetId, startedAt: e.startedAt);
}
