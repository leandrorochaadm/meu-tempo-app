import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../list/domain/usecases/ensure_inbox_exists_use_case.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_node.dart';
import '../../domain/task_failures.dart';
import '../../domain/usecases/add_subtask_use_case.dart';
import '../../domain/usecases/build_task_tree_use_case.dart';
import '../../domain/usecases/create_task_use_case.dart';
import '../../domain/usecases/watch_tasks_use_case.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';

/// Orquestra a listagem/criação/hierarquia de tarefas. Só traduz `Failure` →
/// estado e monta a árvore via UseCase; nenhuma regra/agregação na UI.
@injectable
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc(
    this._watchTasks,
    this._createTask,
    this._ensureInboxExists,
    this._addSubtask,
    this._buildTree,
  ) : super(const TaskListLoading()) {
    on<TaskListStarted>(_onStarted);
    on<TaskListUpdated>(_onUpdated);
    on<TaskCreated>(_onCreated);
    on<SubtaskRequested>(_onSubtaskRequested);
  }

  final WatchTasksUseCase _watchTasks;
  final CreateTaskUseCase _createTask;
  final EnsureInboxExistsUseCase _ensureInboxExists;
  final AddSubtaskUseCase _addSubtask;
  final BuildTaskTreeUseCase _buildTree;

  StreamSubscription<Either<Failure, List<TaskEntity>>>? _tasksSub;
  String? _inboxListId;

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
  }

  void _onUpdated(TaskListUpdated event, Emitter<TaskListState> emit) {
    event.result.match(
      (failure) => emit(TaskListError(_mapFailure(failure))),
      (tasks) {
        if (tasks.isEmpty) {
          emit(const TaskListEmpty());
          return;
        }
        emit(TaskListLoaded(_buildTree(tasks)));
      },
    );
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
    result.match(
      (failure) => emit(TaskListError(_mapFailure(failure))),
      (_) {},
    );
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
    result.match(
      (failure) => emit(TaskListError(_mapFailure(failure))),
      (_) {},
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
        EmptyTitleFailure() => 'Digite um título para a tarefa.',
        MaxLevelExceededFailure() =>
          'Máximo de 3 níveis (mãe, filha, neta).',
        NetworkFailure() => 'Sem conexão. Verifique a internet.',
        _ => 'Algo deu errado. Tente novamente.',
      };

  @override
  Future<void> close() {
    _tasksSub?.cancel();
    return super.close();
  }
}
