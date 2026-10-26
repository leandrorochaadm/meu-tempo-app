import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/utils/calendar_date_codec.dart';
import '../../../../core/utils/instant_codec.dart';
import '../../domain/entities/importance_enum.dart';
import '../../domain/entities/recurring_task_entity.dart';
import '../../domain/entities/weekday_enum.dart';

part 'recurring_task_model.g.dart';

@JsonSerializable(
  includeIfNull: true,
  fieldRename: FieldRename.snake,
  constructor: 'raw',
)
class RecurringTaskModel {
  /// Cria o model a partir dos enums do domínio, gravando o texto externo.
  RecurringTaskModel({
    required this.id,
    required this.title,
    required this.listId,
    required this.estimatedMinutes,
    required ImportanceEnum importance,
    List<WeekdayEnum> weekdays = const [],
    this.createdAt,
    this.lastGeneratedOn,
  }) : importance = importance.apiValue,
       weekdays = [for (final day in weekdays) day.apiValue];

  /// Leitura do servidor: importância e dias ficam crus até o [toEntity].
  const RecurringTaskModel.raw({
    required this.id,
    required this.title,
    required this.listId,
    this.estimatedMinutes = 0,
    this.importance,
    this.weekdays = const [],
    this.createdAt,
    this.lastGeneratedOn,
  });

  @JsonKey(includeToJson: false)
  final String id;
  final String title;
  @JsonKey(name: PbFields.list)
  final String listId;
  final int estimatedMinutes;

  /// Texto cru de `importance`.
  final String? importance;

  /// Texto cru dos dias (`monday`…); lista vazia = "sem dia fixo" (R2).
  @JsonKey(fromJson: _rawWeekdays)
  final List<String> weekdays;
  @InstantConverter()
  final DateTime? createdAt;

  /// Dia da última geração; só o `claimGeneration` grava.
  @CalendarDateConverter()
  final DateTime? lastGeneratedOn;

  factory RecurringTaskModel.fromRecord(RecordModel record) =>
      RecurringTaskModel.fromJson({...record.data, PbFields.id: record.id});

  factory RecurringTaskModel.fromJson(Map<String, dynamic> json) =>
      _$RecurringTaskModelFromJson(json);

  Map<String, dynamic> toJson() => _$RecurringTaskModelToJson(this);

  RecurringTaskEntity toEntity() {
    final parsedImportance = ImportanceEnum.fromApi(importance);
    if (parsedImportance == null) {
      throw FormatException('Invalid importance', importance);
    }
    final days = <WeekdayEnum>{};
    for (final raw in weekdays) {
      final day = WeekdayEnum.fromApi(raw);
      if (day == null) throw FormatException('Invalid weekday', raw);
      days.add(day);
    }
    return RecurringTaskEntity(
      id: id,
      title: title,
      listId: listId,
      estimatedMinutes: estimatedMinutes,
      importance: parsedImportance,
      weekdays: days,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      lastGeneratedOn: lastGeneratedOn,
    );
  }

  factory RecurringTaskModel.fromEntity(RecurringTaskEntity e) =>
      RecurringTaskModel(
        id: e.id,
        title: e.title,
        listId: e.listId,
        estimatedMinutes: e.estimatedMinutes,
        importance: e.importance,
        // Sempre na ordem seg→dom, sem depender da ordem do Set.
        weekdays: WeekdayEnum.values.where(e.weekdays.contains).toList(),
        createdAt: e.createdAt,
        lastGeneratedOn: e.lastGeneratedOn,
      );
}

/// `weekdays` é json no PocketBase: ausente/`null` lê como lista vazia; item
/// que não é texto vira `''` (recusado no `toEntity`).
List<String> _rawWeekdays(Object? raw) {
  if (raw == null) return const [];
  if (raw is List) {
    return [for (final item in raw) item is String ? item : ''];
  }
  throw FormatException('Invalid weekdays', raw);
}
