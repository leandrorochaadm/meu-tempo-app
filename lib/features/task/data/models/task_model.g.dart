// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel.raw(
  id: json['id'] as String,
  title: json['title'] as String,
  listId: json['list'] as String,
  createdAt: const InstantConverter().fromJson(json['created_at'] as String?),
  parentId: _blankAsNull(json['parent'] as String?),
  estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt(),
  dueDate: const CalendarDateConverter().fromJson(json['due_date'] as String?),
  importance: json['importance'] as String?,
  isDone: json['is_done'] as bool? ?? false,
  hasChildren: json['has_children'] as bool? ?? false,
  spentMinutes: (json['spent_minutes'] as num?)?.toInt() ?? 0,
  recurringTaskId: _blankAsNull(json['recurring_task_id'] as String?),
);

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
  'title': instance.title,
  'list': instance.listId,
  'created_at': const InstantConverter().toJson(instance.createdAt),
  'parent': instance.parentId,
  'estimated_minutes': instance.estimatedMinutes,
  'due_date': const CalendarDateConverter().toJson(instance.dueDate),
  'importance': instance.importance,
  'is_done': instance.isDone,
  'has_children': instance.hasChildren,
  'spent_minutes': instance.spentMinutes,
  'recurring_task_id': instance.recurringTaskId,
};
