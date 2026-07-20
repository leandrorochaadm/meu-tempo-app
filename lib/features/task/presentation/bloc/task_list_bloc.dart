import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../list/domain/usecases/ensure_inbox_exists_use_case.dart';
import '../../domain/entities/active_timer_entity.dart';
import '../../domain/entities/importance_enum.dart';
import '../../domain/entities/prioritized_leaf.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_node.dart';
import '../../domain/task_failures.dart';
import '../../domain/usecases/add_subtask_use_case.dart';
import '../../domain/usecases/build_task_tree_use_case.dart';
import '../../domain/usecases/complete_task_use_case.dart';
import '../../domain/usecases/create_task_use_case.dart';
import '../../domain/usecases/delete_task_use_case.dart';
import '../../domain/usecases/edit_task_use_case.dart';
import '../../domain/usecases/get_prioritized_leaves_use_case.dart';
import '../../domain/usecases/move_task_use_case.dart';
import '../../domain/usecases/register_manual_time_use_case.dart';
import '../../domain/usecases/start_timer_use_case.dart';
import '../../domain/usecases/stop_timer_use_case.dart';
import '../../domain/usecases/watch_active_timer_use_case.dart';
import '../../domain/usecases/watch_tasks_use_case.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';

/// Orquestra listagem, hierarquia e cronômetro das tarefas. Só traduz `Failure`
/// → estado e monta a árvore via UseCase; nenhuma regra/agregação na UI.
@injectable
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc(
    this._watchTasks,
    this._createTask,
    this._ensureInboxExists,
    this._addSubtask,
    this._buildTree,
    this._getPrioritized,
    this._watchActiveTimer,
    this._startTimer,
    this._stopTimer,
    this._registerManualTime,
    this._completeTask,
    this._deleteTask,
    this._editTask,
    this._moveTask,
  ) : super(const TaskListLoading()) {
    on<TaskListStarted>(_onStarted);
    on<TaskListUpdated>(_onUpdated);
    on<ActiveTimerUpdated>(_onTimerUpdated);
    on<TaskCreated>(_onCreated);
    on<SubtaskRequested>(_onSubtaskRequested);
    on<TimerStartRequested>(_onTimerStart);
    on<TimerStopRequested>(_onTimerStop);
    on<ManualTimeRequested>(_onManualTime);
    on<CompleteToggled>(_onCompleteToggled);
    on<DeleteRequested>(_onDeleteRequested);
    on<EditRequested>(_onEditRequested);
    on<MoveRequested>(_onMoveRequested);
  }

  final WatchTasksUseCase _watchTasks;
  final CreateTaskUseCase _createTask;
  final EnsureInboxExistsUseCase _ensureInboxExists;
  final AddSubtaskUseCase _addSubtask;
  final BuildTaskTreeUseCase _buildTree;
  final GetPrioritizedLeavesUseCase _getPrioritized;
  final WatchActiveTimerUseCase _watchActiveTimer;
  final StartTimerUseCase _startTimer;
  final StopTimerUseCase _stopTimer;
  final RegisterManualTimeUseCase _registerManualTime;
  final CompleteTaskUseCase _completeTask;
  final DeleteTaskUseCase _deleteTask;
  final EditTaskUseCase _editTask;
  final MoveTaskUseCase _moveTask;

  StreamSubscription<Either<Failure, List<TaskEntity>>>? _tasksSub;
  StreamSubscription<Either<Failure, ActiveTimerEntity?>>? _timerSub;

  String? _inboxListId;
  List<TaskEntity> _latestTasks = const [];
  String? _activeTaskId;

  Future<void> _onStarted(
    TaskListStarted event,
    Emitter<TaskListState> emit,
  ) async {
    emit(const TaskListLoading());
    final inbox = await _ensureInboxExists(const NoParams());
    final failure = inbox.getLeft().toNullable();
    if (failure != null) {
      emit(TaskListError(_mapFailure(failure)));
      return;
    }
    _inboxListId = inbox.getRight().toNullable()!.id;

    await _tasksSub?.cancel();
    _tasksSub = _watchTasks(const NoParams())
        .listen((result) => add(TaskListUpdated(result)));

    await _timerSub?.cancel();
    _timerSub = _watchActiveTimer(const NoParams()).listen(
      (result) => add(ActiveTimerUpdated(
        result.getRight().toNullable()?.targetId,
      )),
    );
  }

  void _onUpdated(TaskListUpdated event, Emitter<TaskListState> emit) {
    event.result.match(
      (failure) => emit(TaskListError(_mapFailure(failure))),
      (tasks) {
        _latestTasks = tasks;
        _emitLoaded(emit);
      },
    );
  }

  void _onTimerUpdated(ActiveTimerUpdated event, Emitter<TaskListState> emit) {
    _activeTaskId = event.activeTaskId;
    _emitLoaded(emit);
  }

  void _emitLoaded(Emitter<TaskListState> emit) {
    if (_latestTasks.isEmpty) {
      emit(const TaskListEmpty());
      return;
    }
    emit(TaskListLoaded(
      _buildTree(_latestTasks),
      prioritized: _getPrioritized(_latestTasks, DateTime.now()),
      activeTaskId: _activeTaskId,
    ));
  }

  Future<void> _onCreated(
    TaskCreated event,
    Emitter<TaskListState> emit,
  ) async {
    final listId = _inboxListId;
    if (listId == null) return;
    final result = await _createTask(
      CreateTaskParams(
        title: event.title,
        listId: listId,
        today: DateTime.now(),
      ),
    );
    _handleWrite(result, emit);
  }

  Future<void> _onSubtaskRequested(
    SubtaskRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final result = await _addSubtask(
      AddSubtaskParams(
        parentId: event.parentId,
        parentLevel: event.parentLevel,
        listId: event.listId,
        title: event.title,
        today: DateTime.now(),
      ),
    );
    _handleWrite(result, emit);
  }

  Future<void> _onTimerStart(
    TimerStartRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final result = await _startTimer(
      StartTimerParams(
        targetId: event.taskId,
        targetIsLeaf: event.isLeaf,
        now: DateTime.now(),
      ),
    );
    _handleWrite(result, emit);
  }

  Future<void> _onTimerStop(
    TimerStopRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final result = await _stopTimer(StopTimerParams(now: DateTime.now()));
    _handleWrite(result, emit);
  }

  Future<void> _onManualTime(
    ManualTimeRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final result = await _registerManualTime(
      RegisterManualTimeParams(
        targetId: event.taskId,
        targetIsLeaf: event.isLeaf,
        minutes: event.minutes,
      ),
    );
    _handleWrite(result, emit);
  }

  Future<void> _onCompleteToggled(
    CompleteToggled event,
    Emitter<TaskListState> emit,
  ) async {
    final result = await _completeTask(
      CompleteTaskParams(taskId: event.taskId, done: event.done),
    );
    _handleWrite(result, emit);
  }

  Future<void> _onDeleteRequested(
    DeleteRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final result = await _deleteTask(DeleteTaskParams(taskId: event.taskId));
    _handleWrite(result, emit);
  }

  Future<void> _onEditRequested(
    EditRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final result = await _editTask(
      EditTaskParams(
        taskId: event.taskId,
        title: event.title,
        estimatedMinutes: event.estimatedMinutes,
        dueDate: event.dueDate,
        importance: event.importance,
      ),
    );
    _handleWrite(result, emit);
  }

  Future<void> _onMoveRequested(
    MoveRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final result = await _moveTask(
      MoveTaskParams(taskId: event.taskId, newParentId: event.newParentId),
    );
    _handleWrite(result, emit);
  }

  /// Erros de escrita viram estado de erro (a UI mostra snackbar); sucesso
  /// reflete pelos streams.
  void _handleWrite<T>(Either<Failure, T> result, Emitter<TaskListState> e) {
    result.match((failure) => e(TaskListError(_mapFailure(failure))), (_) {});
  }

  String _mapFailure(Failure failure) => switch (failure) {
        EmptyTitleFailure() => 'Digite um título para a tarefa.',
        MaxLevelExceededFailure() => 'Máximo de 3 níveis (mãe, filha, neta).',
        TimerOnNonLeafFailure() =>
          'Cronômetro só em tarefas sem filhas (folhas).',
        InvalidDurationFailure() => 'Informe uma duração válida.',
        InvalidMoveFailure() => 'Não dá para mover a tarefa para lá.',
        TaskNotFoundFailure() => 'Tarefa não encontrada.',
        NetworkFailure() => 'Sem conexão. Verifique a internet.',
        _ => 'Algo deu errado. Tente novamente.',
      };

  @override
  Future<void> close() {
    _tasksSub?.cancel();
    _timerSub?.cancel();
    return super.close();
  }
}
