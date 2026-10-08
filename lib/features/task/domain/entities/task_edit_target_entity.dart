import 'package:equatable/equatable.dart';

import '../../../list/domain/entities/task_list_entity.dart';
import 'task_edit_context.dart';

/// Everything the task edit screen needs when opened only by id (tap on the
/// lock screen timer): the edit context (task, parent candidates, breadcrumb)
/// and the user's lists.
class TaskEditTargetEntity extends Equatable {
  TaskEditTargetEntity({
    required this.editContext,
    required List<TaskListEntity> lists,
  }) : lists = List.unmodifiable(lists);

  final TaskEditContext editContext;
  final List<TaskListEntity> lists;

  @override
  List<Object?> get props => [editContext, lists];
}
