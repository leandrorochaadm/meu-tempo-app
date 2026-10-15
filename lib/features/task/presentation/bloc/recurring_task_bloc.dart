import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../../list/domain/usecases/watch_lists_use_case.dart';
import '../../domain/entities/importance_enum.dart';
import '../../domain/entities/recurring_task_entity.dart';
import '../../domain/entities/weekday_enum.dart';
import '../../domain/task_failures.dart';
import '../../domain/usecases/add_recurring_task_today_use_case.dart';
import '../../domain/usecases/create_recurring_task_use_case.dart';
import '../../domain/usecases/delete_recurring_task_use_case.dart';
import '../../domain/usecases/restore_recurring_task_use_case.dart';
import '../../domain/usecases/update_recurring_task_use_case.dart';
import '../../domain/usecases/watch_recurring_tasks_use_case.dart';

part 'recurring_task_event.dart';
part 'recurring_task_state.dart';

/// Orquestra a tela de tarefas recorrentes (H15). Só chama UseCases e traduz
/// `Failure` → estado; nenhuma regra de negócio.
@injectable
class RecurringTaskBloc extends Bloc<RecurringTaskEvent, RecurringTaskState> {
  RecurringTaskBloc(
    this._watchRecurring,
    this._watchLists,
    this._create,
    this._update,
    this._delete,
    this._restore,
    this._addToday,
  ) : super(const RecurringTaskLoading()) {
    on<RecurringTasksStarted>(_onStarted);
    on<_RecurringTasksUpdated>(_onItemsUpdated);
    on<_ListsUpdated>(_onListsUpdated);
    on<RecurringTaskCreated>(_onCreated);
    on<RecurringTaskEdited>(_onEdited);
    on<RecurringTaskDeleted>(_onDeleted);
    on<RecurringTaskRestored>(_onRestored);
    on<RecurringTaskAddedToday>(_onAddedToday);
  }

  final WatchRecurringTasksUseCase _watchRecurring;
  final WatchListsUseCase _watchLists;
  final CreateRecurringTaskUseCase _create;
  final UpdateRecurringTaskUseCase _update;
  final DeleteRecurringTaskUseCase _delete;
  final RestoreRecurringTaskUseCase _restore;
  final AddRecurringTaskTodayUseCase _addToday;

  StreamSubscription<Either<Failure, List<RecurringTaskEntity>>>? _itemsSub;
  StreamSubscription<Either<Failure, List<TaskListEntity>>>? _listsSub;

  /// `null` = o stream ainda não chegou (ou falhou).
  List<RecurringTaskEntity>? _items;
  List<TaskListEntity>? _lists;
  int _effectSeq = 0;

  Future<void> _onStarted(
    RecurringTasksStarted event,
    Emitter<RecurringTaskState> emit,
  ) async {
    emit(const RecurringTaskLoading());
    await _itemsSub?.cancel();
    await _listsSub?.cancel();
    _items = null;
    _lists = null;
    _itemsSub = _watchRecurring(
      const NoParams(),
    ).listen((r) => add(_RecurringTasksUpdated(r)));
    _listsSub = _watchLists(
      const NoParams(),
    ).listen((r) => add(_ListsUpdated(r)));
  }

  void _onItemsUpdated(
    _RecurringTasksUpdated event,
    Emitter<RecurringTaskState> emit,
  ) {
    event.result.match(
      (failure) {
        // O stream do repositório termina depois do `Left`: sem zerar o cache,
        // dados velhos cobririam o erro.
        _items = null;
        emit(RecurringTaskError(_mapFailure(failure)));
      },
      (items) {
        _items = items;
        _emitLoaded(emit);
      },
    );
  }

  void _onListsUpdated(_ListsUpdated event, Emitter<RecurringTaskState> emit) {
    event.result.match(
      (failure) {
        _lists = null;
        emit(RecurringTaskError(_mapFailure(failure)));
      },
      (lists) {
        _lists = lists;
        _emitLoaded(emit);
      },
    );
  }

  Future<void> _onCreated(
    RecurringTaskCreated event,
    Emitter<RecurringTaskState> emit,
  ) async {
    final result = await _create(
      CreateRecurringTaskParams(
        title: event.title,
        listId: event.listId,
        estimatedMinutes: event.estimatedMinutes,
        importance: event.importance,
        weekdays: event.weekdays,
        now: DateTime.now(),
      ),
    );
    result.match((failure) => _emitFailed(emit, failure), (_) {});
  }

  Future<void> _onEdited(
    RecurringTaskEdited event,
    Emitter<RecurringTaskState> emit,
  ) async {
    final result = await _update(event.params);
    result.match((failure) => _emitFailed(emit, failure), (_) {});
  }

  Future<void> _onDeleted(
    RecurringTaskDeleted event,
    Emitter<RecurringTaskState> emit,
  ) async {
    final before = _items;
    List<RecurringTaskEntity>? hidden;
    if (before != null) {
      // O item sai da árvore na hora (exigência do `Dismissible`).
      hidden = before.where((t) => t.id != event.template.id).toList();
      _items = hidden;
      _emitLoaded(emit);
    }
    final result = await _delete(
      DeleteRecurringTaskParams(id: event.template.id),
    );
    result.match(
      (failure) {
        // Sem snapshot novo no meio, devolve o item; senão o snapshot é a verdade.
        if (before != null && identical(_items, hidden)) _items = before;
        _emitFailed(emit, failure);
      },
      (_) => _emitEffect(
        emit,
        RecurringTaskDeletedDone(event.template, ++_effectSeq),
      ),
    );
  }

  Future<void> _onRestored(
    RecurringTaskRestored event,
    Emitter<RecurringTaskState> emit,
  ) async {
    final result = await _restore(
      RestoreRecurringTaskParams(template: event.template),
    );
    result.match((failure) => _emitFailed(emit, failure), (_) {});
  }

  Future<void> _onAddedToday(
    RecurringTaskAddedToday event,
    Emitter<RecurringTaskState> emit,
  ) async {
    final result = await _addToday(
      AddRecurringTaskTodayParams(
        template: event.template,
        today: DateTime.now(),
        confirmed: event.confirmed,
      ),
    );
    result.match(
      (failure) => _emitEffect(emit, switch (failure) {
        PendingRecurringInstanceFailure() => RecurringTaskConfirmRequested(
          event.template,
          ++_effectSeq,
        ),
        _ => RecurringTaskActionFailed(_mapFailure(failure), ++_effectSeq),
      }),
      (_) => _emitEffect(emit, RecurringTaskAddedTodayDone(++_effectSeq)),
    );
  }

  void _emitLoaded(Emitter<RecurringTaskState> emit) {
    final items = _items;
    final lists = _lists;
    if (items == null || lists == null) return;
    emit(RecurringTaskLoaded(items, lists));
  }

  void _emitEffect(
    Emitter<RecurringTaskState> emit,
    RecurringTaskEffect effect,
  ) {
    emit(effect);
    _emitLoaded(emit);
  }

  void _emitFailed(Emitter<RecurringTaskState> emit, Failure failure) {
    _emitEffect(
      emit,
      RecurringTaskActionFailed(_mapFailure(failure), ++_effectSeq),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    EmptyTitleFailure() => 'Digite um título para a tarefa.',
    InvalidDurationFailure() => 'Escolha o tempo estimado.',
    PendingRecurringInstanceFailure() =>
      'Essa tarefa já está na sua lista e ainda não foi feita.',
    NotFoundFailure() => 'Essa tarefa recorrente não existe mais.',
    NetworkFailure() => 'Sem conexão. Verifique a internet.',
    PermissionDeniedFailure() ||
    UnauthenticatedFailure() => 'Sua sessão expirou. Entre de novo.',
    ServerFailure() => 'Algo deu errado. Tente novamente.',
    // `Failure` não é sealed: o analyzer exige um braço final.
    Failure() => 'Algo deu errado. Tente novamente.',
  };

  @override
  Future<void> close() {
    _itemsSub?.cancel();
    _listsSub?.cancel();
    return super.close();
  }
}
