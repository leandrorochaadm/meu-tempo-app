part of 'recurring_task_bloc.dart';

sealed class RecurringTaskState extends Equatable {
  const RecurringTaskState();

  @override
  List<Object?> get props => const [];
}

class RecurringTaskLoading extends RecurringTaskState {
  const RecurringTaskLoading();
}

class RecurringTaskLoaded extends RecurringTaskState {
  const RecurringTaskLoaded(this.items, this.lists);

  /// Já na ordem do stream (título).
  final List<RecurringTaskEntity> items;

  /// Chips do formulário e nome da lista no cartão.
  final List<TaskListEntity> lists;

  @override
  List<Object?> get props => [items, lists];
}

class RecurringTaskError extends RecurringTaskState {
  const RecurringTaskError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Efeito de uma vez só (snackbar/diálogo). A página trata no `listenWhen`
/// e ignora no `buildWhen`; o Bloc reemite o último `Loaded` logo depois.
/// [seq] cresce a cada efeito: dois avisos iguais seguidos não são
/// descartados pelo `Equatable`.
sealed class RecurringTaskEffect extends RecurringTaskState {
  const RecurringTaskEffect(this.seq);

  final int seq;
}

class RecurringTaskAddedTodayDone extends RecurringTaskEffect {
  const RecurringTaskAddedTodayDone(super.seq);

  @override
  List<Object?> get props => [seq];
}

/// Snackbar com "Desfazer".
class RecurringTaskDeletedDone extends RecurringTaskEffect {
  const RecurringTaskDeletedDone(this.template, super.seq);

  final RecurringTaskEntity template;

  @override
  List<Object?> get props => [template, seq];
}

/// Diálogo "Criar mesmo assim?".
class RecurringTaskConfirmRequested extends RecurringTaskEffect {
  const RecurringTaskConfirmRequested(this.template, super.seq);

  final RecurringTaskEntity template;

  @override
  List<Object?> get props => [template, seq];
}

class RecurringTaskActionFailed extends RecurringTaskEffect {
  const RecurringTaskActionFailed(this.message, super.seq);

  final String message;

  @override
  List<Object?> get props => [message, seq];
}
