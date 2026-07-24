import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../../list/domain/usecases/watch_lists_use_case.dart';
import '../../domain/entities/active_timer_entity.dart';
import '../../domain/entities/task_edit_context.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/timer_target_type_enum.dart';
import '../../domain/task_failures.dart';
import '../../domain/usecases/complete_task_use_case.dart';
import '../../domain/usecases/edit_task_use_case.dart';
import '../../domain/usecases/get_task_edit_context_use_case.dart';
import '../../domain/usecases/move_task_use_case.dart';
import '../../domain/usecases/stop_timer_use_case.dart';
import '../../domain/usecases/watch_active_timer_use_case.dart';
import '../../domain/usecases/watch_tasks_use_case.dart';
import '../pages/edit_task_page.dart' show EditTaskResult;

part 'active_timer_event.dart';
part 'active_timer_state.dart';

/// Estado **global** do cronômetro ativo, provido no topo da árvore para a barra
/// "now playing" aparecer em qualquer tela. Combina três fluxos — cronômetro
/// ativo, tarefas e listas — e só exibe a barra quando o alvo é uma **folha de
/// tarefa** (compromisso não entra). Nenhuma regra de negócio aqui: nome/trilha
/// e candidatos a mãe vêm resolvidos do domínio; parar/editar/concluir apenas
/// orquestram os UseCases.
@injectable
class ActiveTimerBloc extends Bloc<ActiveTimerEvent, ActiveTimerState> {
  ActiveTimerBloc(
    this._watchActiveTimer,
    this._watchTasks,
    this._watchLists,
    this._stopTimer,
    this._getEditContext,
    this._editTask,
    this._moveTask,
    this._completeTask,
  ) : super(const ActiveTimerHidden()) {
    on<ActiveTimerStarted>(_onStarted);
    on<ActiveTimerReset>(_onReset);
    on<ActiveTimerStopRequested>(_onStopRequested);
    on<ActiveTimerCompleteRequested>(_onCompleteRequested);
    on<ActiveTimerEditSubmitted>(_onEditSubmitted);
    on<_ActiveTimerChanged>(_onTimerChanged);
    on<_ActiveTimerTasksChanged>(_onTasksChanged);
    on<_ActiveTimerListsChanged>(_onListsChanged);
  }

  final WatchActiveTimerUseCase _watchActiveTimer;
  final WatchTasksUseCase _watchTasks;
  final WatchListsUseCase _watchLists;
  final StopTimerUseCase _stopTimer;
  final GetTaskEditContextUseCase _getEditContext;
  final EditTaskUseCase _editTask;
  final MoveTaskUseCase _moveTask;
  final CompleteTaskUseCase _completeTask;

  StreamSubscription<Either<Failure, ActiveTimerEntity?>>? _timerSub;
  StreamSubscription<Either<Failure, List<TaskEntity>>>? _tasksSub;
  StreamSubscription<Either<Failure, List<TaskListEntity>>>? _listsSub;

  ActiveTimerEntity? _active;
  List<TaskEntity> _tasks = const [];
  List<TaskListEntity> _lists = const [];

  Future<void> _onStarted(
    ActiveTimerStarted event,
    Emitter<ActiveTimerState> emit,
  ) async {
    // Reassina do zero — o `uid` só existe após o login, e o datasource o lê no
    // ato da assinatura. Erros de stream são ignorados (barra some).
    await _cancelSubs();
    _timerSub = _watchActiveTimer(const NoParams()).listen(
      (result) => add(_ActiveTimerChanged(result.getRight().toNullable())),
      onError: (_) => add(const _ActiveTimerChanged(null)),
    );
    _tasksSub =
        _watchTasks(const WatchTasksParams(includeDone: true)).listen(
      (result) =>
          add(_ActiveTimerTasksChanged(result.getRight().toNullable() ?? const [])),
      onError: (_) => add(const _ActiveTimerTasksChanged([])),
    );
    _listsSub = _watchLists(const NoParams()).listen(
      (result) =>
          add(_ActiveTimerListsChanged(result.getRight().toNullable() ?? const [])),
      onError: (_) => add(const _ActiveTimerListsChanged([])),
    );
  }

  Future<void> _onReset(
    ActiveTimerReset event,
    Emitter<ActiveTimerState> emit,
  ) async {
    await _cancelSubs();
    _active = null;
    _tasks = const [];
    _lists = const [];
    emit(const ActiveTimerHidden());
  }

  void _onTimerChanged(_ActiveTimerChanged e, Emitter<ActiveTimerState> emit) {
    _active = e.timer;
    _recompute(emit);
  }

  void _onTasksChanged(_ActiveTimerTasksChanged e, Emitter<ActiveTimerState> emit) {
    _tasks = e.tasks;
    _recompute(emit);
  }

  void _onListsChanged(_ActiveTimerListsChanged e, Emitter<ActiveTimerState> emit) {
    _lists = e.lists;
    _recompute(emit);
  }

  /// Deriva o estado da barra a partir dos três fluxos. A barra só aparece para
  /// uma folha de tarefa cujo cronômetro está rodando e que foi resolvida na
  /// lista atual de tarefas.
  void _recompute(Emitter<ActiveTimerState> emit) {
    final active = _active;
    if (active == null || active.targetType != TimerTargetTypeEnum.task) {
      emit(const ActiveTimerHidden());
      return;
    }
    final editContext = _getEditContext(active.targetId, _tasks);
    if (editContext == null) {
      emit(const ActiveTimerHidden());
      return;
    }
    emit(ActiveTimerRunning(
      title: editContext.task.title,
      ancestryLabel: editContext.currentParentLabel,
      startedAt: active.startedAt,
      editContext: editContext,
      lists: _lists,
    ));
  }

  Future<void> _onStopRequested(
    ActiveTimerStopRequested event,
    Emitter<ActiveTimerState> emit,
  ) async {
    // Sucesso: o stream do cronômetro ativo reflete a parada e some com a barra.
    final result = await _stopTimer(StopTimerParams(now: DateTime.now()));
    _emitOnFailure(result, emit);
  }

  Future<void> _onCompleteRequested(
    ActiveTimerCompleteRequested event,
    Emitter<ActiveTimerState> emit,
  ) async {
    // Concluir enquanto conta: para o cronômetro antes (grava o tempo da sessão)
    // e então marca a folha como concluída. A regra de cada passo vive no UseCase.
    final stopped = await _stopTimer(StopTimerParams(now: DateTime.now()));
    if (_emitOnFailure(stopped, emit)) return;
    final done = await _completeTask(
      CompleteTaskParams(taskId: event.taskId, done: true),
    );
    _emitOnFailure(done, emit);
  }

  Future<void> _onEditSubmitted(
    ActiveTimerEditSubmitted event,
    Emitter<ActiveTimerState> emit,
  ) async {
    final result = event.result;
    final edited = await _editTask(EditTaskParams(
      taskId: event.taskId,
      title: result.title,
      estimatedMinutes: result.estimatedMinutes,
      dueDate: result.dueDate,
      importance: result.importance,
      listId: result.listId,
    ));
    if (_emitOnFailure(edited, emit)) return;

    // Re-parent e conclusão só quando mudaram (regra de cada um no seu UseCase).
    if (result.parentChanged) {
      final moved = await _moveTask(
        MoveTaskParams(taskId: event.taskId, newParentId: result.newParentId),
      );
      if (_emitOnFailure(moved, emit)) return;
    }
    if (result.doneChanged) {
      final completed = await _completeTask(
        CompleteTaskParams(taskId: event.taskId, done: result.isDone),
      );
      _emitOnFailure(completed, emit);
    }
  }

  /// Emite o efeito de falha quando o resultado é `Left`. Retorna `true` se
  /// falhou (para o chamador interromper a sequência).
  bool _emitOnFailure<T>(Either<Failure, T> result, Emitter<ActiveTimerState> emit) {
    final failure = result.getLeft().toNullable();
    if (failure == null) return false;
    emit(ActiveTimerActionFailed(_mapFailure(failure)));
    return true;
  }

  String _mapFailure(Failure failure) => switch (failure) {
        InvalidMoveFailure() => 'Não dá para mover a tarefa para lá.',
        TaskNotFoundFailure() => 'Tarefa não encontrada.',
        NetworkFailure() => 'Sem conexão. Verifique a internet.',
        _ => 'Não foi possível concluir a ação. Tente novamente.',
      };

  Future<void> _cancelSubs() async {
    await _timerSub?.cancel();
    await _tasksSub?.cancel();
    await _listsSub?.cancel();
    _timerSub = null;
    _tasksSub = null;
    _listsSub = null;
  }

  @override
  Future<void> close() {
    _cancelSubs();
    return super.close();
  }
}
