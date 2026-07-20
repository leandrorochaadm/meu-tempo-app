import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../list/domain/usecases/ensure_inbox_exists_use_case.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/task_failures.dart';
import '../../domain/usecases/create_task_use_case.dart';
import '../../domain/usecases/watch_tasks_use_case.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';

/// Orquestra a listagem/criação de tarefas. Só traduz `Failure` → estado;
/// nenhuma regra de negócio (os defaults/validações vivem nos UseCases).
@injectable
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc(
    this._watchTasks,
    this._createTask,
    this._ensureInboxExists,
  ) : super(const TaskListLoading()) {
    on<TaskListStarted>(_onStarted);
    on<TaskListUpdated>(_onUpdated);
    on<TaskCreated>(_onCreated);
  }

  final WatchTasksUseCase _watchTasks;
  final CreateTaskUseCase _createTask;
  final EnsureInboxExistsUseCase _ensureInboxExists;

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
      (tasks) => emit(tasks.isEmpty
          ? const TaskListEmpty()
          : TaskListLoaded(tasks)),
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
    // Sucesso reflete pelo stream (TaskListUpdated); aqui só tratamos erro.
    result.match(
      (failure) => emit(TaskListError(_mapFailure(failure))),
      (_) {},
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
        EmptyTitleFailure() => 'Digite um título para a tarefa.',
        NetworkFailure() => 'Sem conexão. Verifique a internet.',
        _ => 'Algo deu errado. Tente novamente.',
      };

  @override
  Future<void> close() {
    _tasksSub?.cancel();
    return super.close();
  }
}
