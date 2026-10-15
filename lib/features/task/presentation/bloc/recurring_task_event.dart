part of 'recurring_task_bloc.dart';

sealed class RecurringTaskEvent extends Equatable {
  const RecurringTaskEvent();

  @override
  List<Object?> get props => const [];
}

/// A tela de tarefas recorrentes foi aberta.
class RecurringTasksStarted extends RecurringTaskEvent {
  const RecurringTasksStarted();
}

/// Interno: o fluxo dos modelos mudou.
class _RecurringTasksUpdated extends RecurringTaskEvent {
  const _RecurringTasksUpdated(this.result);

  final Either<Failure, List<RecurringTaskEntity>> result;

  @override
  List<Object?> get props => [result];
}

/// Interno: o fluxo das listas mudou.
class _ListsUpdated extends RecurringTaskEvent {
  const _ListsUpdated(this.result);

  final Either<Failure, List<TaskListEntity>> result;

  @override
  List<Object?> get props => [result];
}

/// Formulário "Nova tarefa recorrente" salvo. O `now` é carimbado no Bloc.
class RecurringTaskCreated extends RecurringTaskEvent {
  const RecurringTaskCreated({
    required this.title,
    required this.listId,
    required this.estimatedMinutes,
    required this.importance,
    required this.weekdays,
  });

  final String title;
  final String listId;
  final int estimatedMinutes;
  final ImportanceEnum importance;
  final Set<WeekdayEnum> weekdays;

  @override
  List<Object?> get props => [
    title,
    listId,
    estimatedMinutes,
    importance,
    weekdays,
  ];
}

/// Formulário de edição salvo.
class RecurringTaskEdited extends RecurringTaskEvent {
  const RecurringTaskEdited(this.params);

  final UpdateRecurringTaskParams params;

  @override
  List<Object?> get props => [params];
}

/// Usuário excluiu um modelo.
class RecurringTaskDeleted extends RecurringTaskEvent {
  const RecurringTaskDeleted(this.template);

  final RecurringTaskEntity template;

  @override
  List<Object?> get props => [template];
}

/// Usuário tocou "Desfazer" depois de excluir.
class RecurringTaskRestored extends RecurringTaskEvent {
  const RecurringTaskRestored(this.template);

  final RecurringTaskEntity template;

  @override
  List<Object?> get props => [template];
}

/// Usuário tocou "Adicionar hoje".
class RecurringTaskAddedToday extends RecurringTaskEvent {
  const RecurringTaskAddedToday(this.template, {this.confirmed = false});

  final RecurringTaskEntity template;

  /// `true` depois que o usuário tocou "Criar" no diálogo (R4, H15).
  final bool confirmed;

  @override
  List<Object?> get props => [template, confirmed];
}
