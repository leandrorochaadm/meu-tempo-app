import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../../list/domain/usecases/ensure_inbox_exists_use_case.dart';
import '../../../list/domain/usecases/watch_lists_use_case.dart';
import '../../domain/entities/active_timer_entity.dart';
import '../../domain/entities/importance_enum.dart';
import '../../domain/entities/prioritized_leaf.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_node.dart';
import '../../domain/entities/timer_target_type_enum.dart';
import '../../domain/task_failures.dart';
import '../../domain/usecases/add_subtask_use_case.dart';
import '../../domain/usecases/build_task_tree_use_case.dart';
import '../../domain/usecases/complete_task_use_case.dart';
import '../../domain/usecases/create_task_use_case.dart';
import '../../domain/usecases/delete_task_use_case.dart';
import '../../domain/usecases/edit_task_use_case.dart';
import '../../domain/usecases/filter_tasks_by_list_use_case.dart';
import '../../domain/usecases/get_prioritized_leaves_use_case.dart';
import '../../domain/usecases/get_task_list_filter_use_case.dart';
import '../../domain/usecases/move_task_use_case.dart';
import '../../domain/usecases/register_manual_time_use_case.dart';
import '../../domain/usecases/restore_tasks_use_case.dart';
import '../../domain/usecases/save_task_list_filter_use_case.dart';
import '../../domain/usecases/seed_first_access_use_case.dart';
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
    this._watchLists,
    this._seedFirstAccess,
    this._restoreTasks,
    this._filterTasksByList,
    this._getTaskListFilter,
    this._saveTaskListFilter,
  ) : super(const TaskListLoading()) {
    on<TaskListStarted>(_onStarted);
    on<TaskListUpdated>(_onUpdated);
    on<TaskListListsUpdated>(_onListsUpdated);
    on<ListFilterChanged>(_onListFilterChanged);
    on<HideDoneToggled>(_onHideDoneToggled);
    on<ActiveTimerUpdated>(_onTimerUpdated);
    on<TaskCreated>(_onCreated);
    on<SubtaskRequested>(_onSubtaskRequested);
    on<TimerStartRequested>(_onTimerStart);
    on<TimerStopRequested>(_onTimerStop);
    on<ManualTimeRequested>(_onManualTime);
    on<CompleteToggled>(_onCompleteToggled);
    on<DeleteRequested>(_onDeleteRequested);
    on<TaskDeletionUndone>(_onDeletionUndone);
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
  final WatchListsUseCase _watchLists;
  final SeedFirstAccessUseCase _seedFirstAccess;
  final RestoreTasksUseCase _restoreTasks;
  final FilterTasksByListUseCase _filterTasksByList;
  final GetTaskListFilterUseCase _getTaskListFilter;
  final SaveTaskListFilterUseCase _saveTaskListFilter;

  StreamSubscription<Either<Failure, List<TaskEntity>>>? _tasksSub;
  StreamSubscription<Either<Failure, ActiveTimerEntity?>>? _timerSub;
  StreamSubscription<Either<Failure, List<TaskListEntity>>>? _listsSub;

  String? _inboxListId;
  List<TaskEntity> _latestTasks = const [];
  List<TaskListEntity> _lists = const [];
  String? _activeTaskId;
  DateTime? _activeStartedAt;

  /// Filtro de lista ativo na tela (`null` = "Todas as listas"). Estado de UI.
  String? _selectedListId;

  /// Se as concluídas estão ocultas (padrão `true`). Estado de UI só da sessão —
  /// não é persistido. Controla `includeDone` da query (filtro no backend).
  bool _hideDone = true;

  /// Última subárvore excluída, guardada para o "Desfazer" (H13).
  List<TaskEntity> _lastDeleted = const [];

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

    // Filtro de lista salvo (última usada). Se falhar, fica em "Todas".
    final savedFilter = await _getTaskListFilter(const NoParams());
    _selectedListId = savedFilter.getRight().toNullable();

    // Primeiro acesso: semeia uma tarefa-exemplo (idempotente).
    await _seedFirstAccess(SeedFirstAccessParams(
      today: DateTime.now(),
      inboxListId: _inboxListId!,
    ));

    await _subscribeTasks();

    await _timerSub?.cancel();
    _timerSub = _watchActiveTimer(const NoParams()).listen((result) {
      final active = result.getRight().toNullable();
      add(ActiveTimerUpdated(active?.targetId, active?.startedAt));
    });

    await _listsSub?.cancel();
    _listsSub = _watchLists(const NoParams())
        .listen((result) => add(TaskListListsUpdated(result)));
  }

  void _onListsUpdated(TaskListListsUpdated e, Emitter<TaskListState> emit) {
    final lists = e.result.getRight().toNullable();
    if (lists != null) {
      _lists = lists;
      // Se a lista filtrada foi excluída, volta para "Todas" (lookup, não regra).
      final stillExists =
          _selectedListId == null || lists.any((l) => l.id == _selectedListId);
      if (!stillExists) {
        _selectedListId = null;
        _saveTaskListFilter(const SaveTaskListFilterParams(null));
      }
      _emitLoaded(emit);
    }
  }

  /// (Re)assina o fluxo de tarefas respeitando o filtro de concluídas. Ao ocultar
  /// (`_hideDone`), a query já vem sem as concluídas — menos leitura no backend.
  Future<void> _subscribeTasks() async {
    await _tasksSub?.cancel();
    _tasksSub = _watchTasks(WatchTasksParams(includeDone: !_hideDone))
        .listen((result) => add(TaskListUpdated(result)));
  }

  Future<void> _onHideDoneToggled(
    HideDoneToggled event,
    Emitter<TaskListState> emit,
  ) async {
    if (_hideDone == event.hide) return;
    _hideDone = event.hide;
    // Troca a fonte de dados; o novo snapshot dispara TaskListUpdated → estado.
    await _subscribeTasks();
  }

  Future<void> _onListFilterChanged(
    ListFilterChanged event,
    Emitter<TaskListState> emit,
  ) async {
    _selectedListId = event.listId;
    await _saveTaskListFilter(SaveTaskListFilterParams(event.listId));
    _emitLoaded(emit);
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
    _activeStartedAt = event.startedAt;
    _emitLoaded(emit);
  }

  void _emitLoaded(Emitter<TaskListState> emit) {
    // Empty global (1º acesso) só quando não há tarefa E nenhum filtro ativo —
    // com filtro (lista ou concluídas ocultas) emitimos Loaded para manter os
    // chips na tela e mostrar um empty-state contextual.
    final noFilters = _selectedListId == null && !_hideDone;
    if (_latestTasks.isEmpty && noFilters) {
      emit(const TaskListEmpty());
      return;
    }
    // Filtro por lista resolvido no UseCase — a UI recebe pronto. As concluídas
    // já vêm filtradas do backend (`includeDone`), não há filtro aqui.
    final filtered = _filterTasksByList(_latestTasks, _selectedListId);
    emit(TaskListLoaded(
      _buildTree(filtered),
      prioritized: _getPrioritized(filtered, DateTime.now()),
      activeTaskId: _activeTaskId,
      activeTimerStartedAt: _activeStartedAt,
      lists: _lists,
      selectedListId: _selectedListId,
      hideDone: _hideDone,
    ));
  }

  Future<void> _onCreated(
    TaskCreated event,
    Emitter<TaskListState> emit,
  ) async {
    final listId = event.listId ?? _inboxListId;
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
        targetType: TimerTargetTypeEnum.task,
        targetIsLeaf: event.isLeaf,
        listId: _listIdOf(event.taskId),
        now: DateTime.now(),
      ),
    );
    _handleWrite(result, emit);
  }

  /// Descobre a lista de uma folha já carregada (lookup, não regra de negócio).
  String _listIdOf(String taskId) {
    for (final t in _latestTasks) {
      if (t.id == taskId) return t.listId;
    }
    return _inboxListId ?? '';
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
        listId: _listIdOf(event.taskId),
        minutes: event.minutes,
        now: DateTime.now(),
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
    result.match(
      (failure) => emit(TaskListError(_mapFailure(failure))),
      (removed) => _lastDeleted = removed,
    );
  }

  Future<void> _onDeletionUndone(
    TaskDeletionUndone event,
    Emitter<TaskListState> emit,
  ) async {
    final removed = _lastDeleted;
    if (removed.isEmpty) return;
    _lastDeleted = const [];
    final result = await _restoreTasks(RestoreTasksParams(tasks: removed));
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
        listId: event.listId,
      ),
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(TaskListError(_mapFailure(failure)));
      return;
    }
    // Orquestra as demais intenções (regra de cada uma mora no seu UseCase).
    // Fila sequencial do bloc: cada handler relê os dados no início.
    if (event.parentChanged) {
      add(MoveRequested(taskId: event.taskId, newParentId: event.newParentId));
    }
    if (event.doneChanged) {
      add(CompleteToggled(taskId: event.taskId, done: event.isDone));
    }
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
    _listsSub?.cancel();
    return super.close();
  }
}
