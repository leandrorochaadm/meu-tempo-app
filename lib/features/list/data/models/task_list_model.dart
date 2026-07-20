import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/task_list_entity.dart';

part 'task_list_model.g.dart';

@JsonSerializable(includeIfNull: false)
class TaskListModel {
  const TaskListModel({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  @JsonKey(includeToJson: false) // id vem do doc.id
  final String id;
  final String name;
  final bool isDefault;

  factory TaskListModel.fromDoc(String id, Map<String, dynamic> data) =>
      TaskListModel.fromJson({...data, 'id': id});

  factory TaskListModel.fromJson(Map<String, dynamic> json) =>
      _$TaskListModelFromJson(json);

  Map<String, dynamic> toJson() => _$TaskListModelToJson(this);

  TaskListEntity toEntity() =>
      TaskListEntity(id: id, name: name, isDefault: isDefault);

  factory TaskListModel.fromEntity(TaskListEntity e) =>
      TaskListModel(id: e.id, name: e.name, isDefault: e.isDefault);
}
