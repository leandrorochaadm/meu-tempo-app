import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/importance_enum.dart';
import '../../domain/entities/task_entity.dart';

part 'task_model.g.dart';

@JsonSerializable(includeIfNull: false)
class TaskModel {
  const TaskModel({
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
  });

  @JsonKey(includeToJson: false) // id vem do doc.id
  final String id;
  final String title;
  final String listId;
  @TimestampConverter()
  final DateTime? createdAt;
  final String? parentId;
  final int? estimatedMinutes;
  @TimestampConverter()
  final DateTime? dueDate;
  final ImportanceEnum? importance;
  final bool isDone;
  final bool hasChildren;

  factory TaskModel.fromDoc(String id, Map<String, dynamic> data) =>
      TaskModel.fromJson({...data, 'id': id});

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  TaskEntity toEntity() => TaskEntity(
        id: id,
        title: title,
        listId: listId,
        createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        parentId: parentId,
        estimatedMinutes: estimatedMinutes,
        dueDate: dueDate,
        importance: importance,
        isDone: isDone,
        hasChildren: hasChildren,
      );

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
      );
}
