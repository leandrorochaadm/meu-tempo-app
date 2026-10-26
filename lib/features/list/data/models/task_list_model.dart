import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../domain/entities/task_list_entity.dart';

part 'task_list_model.g.dart';

@JsonSerializable(includeIfNull: true, fieldRename: FieldRename.snake)
class TaskListModel {
  const TaskListModel({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  @JsonKey(includeToJson: false) // id comes from the record id
  final String id;
  final String name;
  final bool isDefault;

  factory TaskListModel.fromRecord(RecordModel record) =>
      TaskListModel.fromJson({...record.data, PbFields.id: record.id});

  factory TaskListModel.fromJson(Map<String, dynamic> json) =>
      _$TaskListModelFromJson(json);

  Map<String, dynamic> toJson() => _$TaskListModelToJson(this);

  TaskListEntity toEntity() =>
      TaskListEntity(id: id, name: name, isDefault: isDefault);

  factory TaskListModel.fromEntity(TaskListEntity e) =>
      TaskListModel(id: e.id, name: e.name, isDefault: e.isDefault);
}
