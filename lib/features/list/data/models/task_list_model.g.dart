// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskListModel _$TaskListModelFromJson(Map<String, dynamic> json) =>
    TaskListModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _$TaskListModelToJson(TaskListModel instance) =>
    <String, dynamic>{'name': instance.name, 'isDefault': instance.isDefault};
