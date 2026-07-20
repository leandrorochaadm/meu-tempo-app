// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
  id: json['id'] as String,
  title: json['title'] as String,
  listId: json['listId'] as String,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp?,
  ),
  parentId: json['parentId'] as String?,
  estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
  dueDate: const TimestampConverter().fromJson(json['dueDate'] as Timestamp?),
  importance: $enumDecodeNullable(_$ImportanceEnumEnumMap, json['importance']),
  isDone: json['isDone'] as bool? ?? false,
  hasChildren: json['hasChildren'] as bool? ?? false,
);

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
  'title': instance.title,
  'listId': instance.listId,
  'createdAt': ?const TimestampConverter().toJson(instance.createdAt),
  'parentId': ?instance.parentId,
  'estimatedMinutes': ?instance.estimatedMinutes,
  'dueDate': ?const TimestampConverter().toJson(instance.dueDate),
  'importance': ?_$ImportanceEnumEnumMap[instance.importance],
  'isDone': instance.isDone,
  'hasChildren': instance.hasChildren,
};

const _$ImportanceEnumEnumMap = {
  ImportanceEnum.max: 'max',
  ImportanceEnum.high: 'high',
  ImportanceEnum.low: 'low',
  ImportanceEnum.min: 'min',
};
