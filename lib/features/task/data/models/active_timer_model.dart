import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/active_timer_entity.dart';
import '../../domain/entities/timer_target_type_enum.dart';

part 'active_timer_model.g.dart';

@JsonSerializable(includeIfNull: false)
class ActiveTimerModel {
  const ActiveTimerModel({
    required this.targetId,
    required this.startedAt,
    this.targetType,
    this.listId,
  });

  final String targetId;
  @TimestampConverter()
  final DateTime? startedAt;

  /// `null` em docs antigos (antes do cronômetro de compromisso) → assume `task`.
  final TimerTargetTypeEnum? targetType;

  /// `null` em docs antigos → o registro de tempo é montado com string vazia,
  /// que o relatório trata como "sem lista".
  final String? listId;

  factory ActiveTimerModel.fromJson(Map<String, dynamic> json) =>
      _$ActiveTimerModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveTimerModelToJson(this);

  ActiveTimerEntity toEntity() => ActiveTimerEntity(
        targetId: targetId,
        targetType: targetType ?? TimerTargetTypeEnum.task,
        listId: listId ?? '',
        startedAt: startedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      );

  factory ActiveTimerModel.fromEntity(ActiveTimerEntity e) => ActiveTimerModel(
        targetId: e.targetId,
        targetType: e.targetType,
        listId: e.listId,
        startedAt: e.startedAt,
      );
}
