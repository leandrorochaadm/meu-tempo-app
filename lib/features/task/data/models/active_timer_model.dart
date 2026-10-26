import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/utils/instant_codec.dart';
import '../../domain/entities/active_timer_entity.dart';
import '../../domain/entities/timer_status_enum.dart';
import '../../domain/entities/timer_target_type_enum.dart';

part 'active_timer_model.g.dart';

@JsonSerializable(includeIfNull: true, fieldRename: FieldRename.snake)
class ActiveTimerModel {
  const ActiveTimerModel({
    required this.targetId,
    required this.startedAt,
    this.targetType,
    this.listId,
    this.status,
  });

  final String targetId;
  @InstantConverter()
  final DateTime? startedAt;

  /// Grafia crua do `TimerTargetTypeEnum` (`apiValue`). Vazio ou ausente
  /// (registro sem o campo) → assume `task`.
  final String? targetType;

  /// Vazio ou ausente (registro sem o campo) → o registro de tempo é montado
  /// com string vazia, que o relatório trata como "sem lista".
  final String? listId;

  /// Grafia crua do `TimerStatusEnum` (`apiValue`). Vazio ou ausente (registro
  /// sem o campo) → `TimerStatusEnum.fromApi` lê como rodando.
  final String? status;

  factory ActiveTimerModel.fromRecord(RecordModel record) =>
      ActiveTimerModel.fromJson(record.data);

  factory ActiveTimerModel.fromJson(Map<String, dynamic> json) =>
      _$ActiveTimerModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveTimerModelToJson(this);

  ActiveTimerEntity toEntity() => ActiveTimerEntity(
    targetId: targetId,
    targetType:
        TimerTargetTypeEnum.fromApi(targetType) ?? TimerTargetTypeEnum.task,
    listId: listId ?? '',
    startedAt: startedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    status: TimerStatusEnum.fromApi(status),
  );

  factory ActiveTimerModel.fromEntity(ActiveTimerEntity e) => ActiveTimerModel(
    targetId: e.targetId,
    targetType: e.targetType.apiValue,
    listId: e.listId,
    startedAt: e.startedAt,
    status: e.status.apiValue,
  );
}
