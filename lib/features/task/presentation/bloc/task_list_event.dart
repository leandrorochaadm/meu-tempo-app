part of 'task_list_bloc.dart';

sealed class TaskListEvent extends Equatable {
  const TaskListEvent();

  @override
  List<Object?> get props => const [];
}

/// Inicializa a tela: garante a "Entrada" e passa a escutar as tarefas.
class TaskListStarted extends TaskListEvent {
  const TaskListStarted();
}

/// Emitido internamente quando o stream de tarefas atualiza.
class TaskListUpdated extends TaskListEvent {
  const TaskListUpdated(this.result);
  final Either<Failure, List<TaskEntity>> result;

  @override
  List<Object?> get props => [result];
}

/// Criação rápida: só o título (tarefa mãe na "Entrada").
class TaskCreated extends TaskListEvent {
  const TaskCreated(this.title);
  final String title;

  @override
  List<Object?> get props => [title];
}

/// Adiciona uma subtarefa (filha/neta) a um nó existente.
class SubtaskRequested extends TaskListEvent {
  const SubtaskRequested({
    required this.parentId,
    required this.parentLevel,
    required this.listId,
    required this.title,
  });

  final String parentId;
  final int parentLevel;
  final String listId;
  final String title;

  @override
  List<Object?> get props => [parentId, parentLevel, listId, title];
}
