import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/utils/calendar_date_codec.dart';
import '../../../../core/utils/instant_codec.dart';
import '../../domain/entities/importance_enum.dart';
import '../../domain/entities/task_entity.dart';

part 'task_model.g.dart';

@JsonSerializable(
  includeIfNull: true,
  fieldRename: FieldRename.snake,
  constructor: 'raw',
)
class TaskModel {
  /// Cria o model a partir do enum do domínio, gravando o texto externo.
  TaskModel({
    required this.id,
    required this.title,
    required this.listId,
    required this.createdAt,
    this.parentId,
    this.estimatedMinutes,
    this.dueDate,
    ImportanceEnum? importance,
    this.isDone = false,
    this.hasChildren = false,
    this.spentMinutes = 0,
    this.recurringTaskId,
  }) : importance = importance?.apiValue;

  /// Leitura do servidor: o texto da importância fica cru até o [toEntity].
  const TaskModel.raw({
    required this.id,
    required this.title,
    required this.listId,
    required this.createdAt,
    this.parentId,
    this.estimatedMinutes,
    this.dueDate,
    this.importance,
    this.isDone = false,
    this.hasChildren = false,
    this.spentMinutes = 0,
    this.recurringTaskId,
  });

  @JsonKey(includeToJson: false)
  final String id;
  final String title;
  @JsonKey(name: PbFields.list)
  final String listId;
  @InstantConverter()
  final DateTime? createdAt;
  @JsonKey(name: PbFields.parent, fromJson: _blankAsNull)
  final String? parentId;
  final int? estimatedMinutes;
  @CalendarDateConverter()
  final DateTime? dueDate;
  final String? importance;
  final bool isDone;
  final bool hasChildren;
  final int spentMinutes;
  @JsonKey(fromJson: _blankAsNull)
  final String? recurringTaskId;

  factory TaskModel.fromRecord(RecordModel record) =>
      TaskModel.fromJson({...record.data, PbFields.id: record.id});

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  TaskEntity toEntity() {
    final raw = importance;
    ImportanceEnum? parsed;
    if (raw != null && raw.isNotEmpty) {
      parsed = ImportanceEnum.fromApi(raw);
      if (parsed == null) throw FormatException('Invalid importance', raw);
    }
    return TaskEntity(
      id: id,
      title: title,
      listId: listId,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      parentId: parentId,
      estimatedMinutes: estimatedMinutes,
      dueDate: dueDate,
      importance: parsed,
      isDone: isDone,
      hasChildren: hasChildren,
      spentMinutes: spentMinutes,
      recurringTaskId: recurringTaskId,
    );
  }

  factory TaskModel.fromEntity(TaskEntity e) => TaskModel(
    id: e.id,
    title: e.title,
    listId: e.listId,
    createdAt: e.createdAt,
    parentId: e.parentId,
    estimatedMinutes: e.estimatedMinutes,
    dueDate: e.dueDate,
    importance: e.importance,
    isDone: e.isDone,
    hasChildren: e.hasChildren,
    spentMinutes: e.spentMinutes,
    recurringTaskId: e.recurringTaskId,
  );
}

/// Relação vazia volta `''` no PocketBase: lê como `null`.
String? _blankAsNull(String? raw) => (raw == null || raw.isEmpty) ? null : raw;
