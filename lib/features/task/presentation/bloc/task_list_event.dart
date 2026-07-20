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

/// Emitido internamente quando o cronômetro ativo muda.
class ActiveTimerUpdated extends TaskListEvent {
  const ActiveTimerUpdated(this.activeTaskId);
  final String? activeTaskId;

  @override
  List<Object?> get props => [activeTaskId];
}

/// Inicia o cronômetro numa folha (pausa o anterior automaticamente).
class TimerStartRequested extends TaskListEvent {
  const TimerStartRequested({required this.taskId, required this.isLeaf});
  final String taskId;
  final bool isLeaf;

  @override
  List<Object?> get props => [taskId, isLeaf];
}

/// Para o cronômetro ativo.
class TimerStopRequested extends TaskListEvent {
  const TimerStopRequested();
}

/// Registra tempo manual numa folha (ex.: +15 / +30 min).
class ManualTimeRequested extends TaskListEvent {
  const ManualTimeRequested({
    required this.taskId,
    required this.isLeaf,
    required this.minutes,
  });
  final String taskId;
  final bool isLeaf;
  final int minutes;

  @override
  List<Object?> get props => [taskId, isLeaf, minutes];
}

/// Marca/desmarca uma folha como concluída (propaga para a mãe/avó).
class CompleteToggled extends TaskListEvent {
  const CompleteToggled({required this.taskId, required this.done});
  final String taskId;
  final bool done;

  @override
  List<Object?> get props => [taskId, done];
}

/// Exclui uma tarefa em cascata (com as filhas/netas).
class DeleteRequested extends TaskListEvent {
  const DeleteRequested(this.taskId);
  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Edita os campos de uma tarefa.
class EditRequested extends TaskListEvent {
  const EditRequested({
    required this.taskId,
    required this.title,
    this.estimatedMinutes,
    this.dueDate,
    this.importance,
  });

  final String taskId;
  final String title;
  final int? estimatedMinutes;
  final DateTime? dueDate;
  final ImportanceEnum? importance;

  @override
  List<Object?> get props =>
      [taskId, title, estimatedMinutes, dueDate, importance];
}

/// Move uma tarefa na hierarquia (novo pai ou raiz).
class MoveRequested extends TaskListEvent {
  const MoveRequested({required this.taskId, this.newParentId});
  final String taskId;
  final String? newParentId;

  @override
  List<Object?> get props => [taskId, newParentId];
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
