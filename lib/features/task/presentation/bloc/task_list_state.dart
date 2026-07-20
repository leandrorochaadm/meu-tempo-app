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
  const TaskListLoaded(this.roots, {this.activeTaskId});

  /// Árvore de tarefas (raízes = mães), com agregação pronta nos [TaskNode].
  final List<TaskNode> roots;

  /// Id da folha com cronômetro rodando (`null` = nenhum).
  final String? activeTaskId;

  @override
  List<Object?> get props => [roots, activeTaskId];
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
