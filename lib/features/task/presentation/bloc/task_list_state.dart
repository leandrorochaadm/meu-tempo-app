part of 'task_list_bloc.dart';

sealed class TaskListState extends Equatable {
  const TaskListState();

  @override
  List<Object?> get props => const [];
}

class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

class TaskListLoaded extends TaskListState {
  const TaskListLoaded(this.roots);

  /// Árvore de tarefas (raízes = mães), com agregação pronta nos [TaskNode].
  final List<TaskNode> roots;

  @override
  List<Object?> get props => [roots];
}

class TaskListEmpty extends TaskListState {
  const TaskListEmpty();
}

class TaskListError extends TaskListState {
  const TaskListError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
