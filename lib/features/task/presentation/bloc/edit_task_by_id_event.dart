part of 'edit_task_by_id_bloc.dart';

sealed class EditTaskByIdEvent extends Equatable {
  const EditTaskByIdEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen opened to edit task [taskId] (only the id is known).
class EditTaskByIdStarted extends EditTaskByIdEvent {
  const EditTaskByIdStarted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}
