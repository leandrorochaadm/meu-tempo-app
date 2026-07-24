part of 'active_timer_bloc.dart';

sealed class ActiveTimerEvent extends Equatable {
  const ActiveTimerEvent();

  @override
  List<Object?> get props => const [];
}

/// Passa a escutar cronômetro ativo, tarefas e listas (disparado ao autenticar).
class ActiveTimerStarted extends ActiveTimerEvent {
  const ActiveTimerStarted();
}

/// Cancela as assinaturas e esconde a barra (disparado ao sair/deslogar).
class ActiveTimerReset extends ActiveTimerEvent {
  const ActiveTimerReset();
}

/// Para o cronômetro ativo (botão "Parar" da barra).
class ActiveTimerStopRequested extends ActiveTimerEvent {
  const ActiveTimerStopRequested();
}

/// Conclui a folha em contagem (botão "Concluir" da barra, após confirmação).
/// Ao concluir, o cronômetro é parado antes — o tempo da sessão é gravado.
class ActiveTimerCompleteRequested extends ActiveTimerEvent {
  const ActiveTimerCompleteRequested(this.taskId);
  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Persiste a edição feita pela barra (retorno do formulário de edição).
class ActiveTimerEditSubmitted extends ActiveTimerEvent {
  const ActiveTimerEditSubmitted(this.taskId, this.result);
  final String taskId;
  final EditTaskResult result;

  @override
  List<Object?> get props => [taskId, result];
}

/// Interno: o cronômetro ativo mudou (stream do Firestore).
class _ActiveTimerChanged extends ActiveTimerEvent {
  const _ActiveTimerChanged(this.timer);
  final ActiveTimerEntity? timer;

  @override
  List<Object?> get props => [timer];
}

/// Interno: a lista de tarefas mudou (para resolver nome/trilha do alvo).
class _ActiveTimerTasksChanged extends ActiveTimerEvent {
  const _ActiveTimerTasksChanged(this.tasks);
  final List<TaskEntity> tasks;

  @override
  List<Object?> get props => [tasks];
}

/// Interno: as listas do usuário mudaram (para montar os args de edição).
class _ActiveTimerListsChanged extends ActiveTimerEvent {
  const _ActiveTimerListsChanged(this.lists);
  final List<TaskListEntity> lists;

  @override
  List<Object?> get props => [lists];
}
