import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/utils/instant_codec.dart';
import '../../domain/entities/time_entry_entity.dart';
import '../../domain/entities/time_entry_origin_enum.dart';
import '../../domain/entities/timer_target_type_enum.dart';

part 'time_entry_model.g.dart';

@JsonSerializable(
  includeIfNull: true,
  fieldRename: FieldRename.snake,
  constructor: 'raw',
)
class TimeEntryModel {
  /// Cria o model a partir dos enums do domínio, gravando o texto externo.
  TimeEntryModel({
    required this.id,
    required this.targetId,
    required TimerTargetTypeEnum targetType,
    required this.listId,
    required this.minutes,
    required TimeEntryOriginEnum origin,
    required this.occurredAt,
  }) : targetType = targetType.apiValue,
       origin = origin.apiValue;

  /// Leitura do servidor: o texto dos enums fica cru até o [toEntity].
  const TimeEntryModel.raw({
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
  final String? targetType;
  final String listId;
  final int minutes;
  final String? origin;
  @InstantConverter()
  final DateTime? occurredAt;

  factory TimeEntryModel.fromRecord(RecordModel record) =>
      TimeEntryModel.fromJson({...record.data, PbFields.id: record.id});

  factory TimeEntryModel.fromJson(Map<String, dynamic> json) =>
      _$TimeEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$TimeEntryModelToJson(this);

  TimeEntryEntity toEntity() {
    final type = TimerTargetTypeEnum.fromApi(targetType);
    if (type == null) {
      throw FormatException('Invalid target_type', targetType);
    }
    final originValue = TimeEntryOriginEnum.fromApi(origin);
    if (originValue == null) {
      throw FormatException('Invalid origin', origin);
    }
    return TimeEntryEntity(
      id: id,
      targetId: targetId,
      targetType: type,
      listId: listId,
      minutes: minutes,
      origin: originValue,
      occurredAt: occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

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
