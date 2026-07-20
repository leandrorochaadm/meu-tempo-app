import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/task_list_entity.dart';
import '../../domain/list_failures.dart';
import '../../domain/usecases/create_list_use_case.dart';
import '../../domain/usecases/delete_list_use_case.dart';
import '../../domain/usecases/rename_list_use_case.dart';
import '../../domain/usecases/watch_lists_use_case.dart';

part 'list_manager_event.dart';
part 'list_manager_state.dart';

/// Orquestra o CRUD de listas. Só traduz `Failure` → estado.
@injectable
class ListManagerBloc extends Bloc<ListManagerEvent, ListManagerState> {
  ListManagerBloc(
    this._watchLists,
    this._createList,
    this._renameList,
    this._deleteList,
  ) : super(const ListManagerLoading()) {
    on<ListManagerStarted>(_onStarted);
    on<ListManagerUpdated>(_onUpdated);
    on<ListCreated>(_onCreated);
    on<ListRenamed>(_onRenamed);
    on<ListDeleted>(_onDeleted);
  }

  final WatchListsUseCase _watchLists;
  final CreateListUseCase _createList;
  final RenameListUseCase _renameList;
  final DeleteListUseCase _deleteList;

  StreamSubscription<Either<Failure, List<TaskListEntity>>>? _sub;

  Future<void> _onStarted(
    ListManagerStarted event,
    Emitter<ListManagerState> emit,
  ) async {
    emit(const ListManagerLoading());
    await _sub?.cancel();
    _sub = _watchLists(const NoParams())
        .listen((result) => add(ListManagerUpdated(result)));
  }

  void _onUpdated(ListManagerUpdated event, Emitter<ListManagerState> emit) {
    event.result.match(
      (failure) => emit(ListManagerError(_mapFailure(failure))),
      (lists) => emit(ListManagerLoaded(lists)),
    );
  }

  Future<void> _onCreated(
    ListCreated event,
    Emitter<ListManagerState> emit,
  ) async {
    _handle(await _createList(CreateListParams(name: event.name)), emit);
  }

  Future<void> _onRenamed(
    ListRenamed event,
    Emitter<ListManagerState> emit,
  ) async {
    _handle(
      await _renameList(
        RenameListParams(listId: event.listId, name: event.name),
      ),
      emit,
    );
  }

  Future<void> _onDeleted(
    ListDeleted event,
    Emitter<ListManagerState> emit,
  ) async {
    _handle(
      await _deleteList(
        DeleteListParams(
          listId: event.listId,
          moveToListId: event.moveToListId,
        ),
      ),
      emit,
    );
  }

  void _handle<T>(Either<Failure, T> result, Emitter<ListManagerState> emit) {
    result.match((f) => emit(ListManagerError(_mapFailure(f))), (_) {});
  }

  String _mapFailure(Failure failure) => switch (failure) {
        EmptyListNameFailure() => 'Digite um nome para a lista.',
        CannotDeleteInboxFailure() =>
          'A lista "Entrada" não pode ser excluída.',
        ListNotFoundFailure() => 'Lista não encontrada.',
        NetworkFailure() => 'Sem conexão. Verifique a internet.',
        _ => 'Algo deu errado. Tente novamente.',
      };

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
