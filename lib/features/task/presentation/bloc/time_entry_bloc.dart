import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/time_entry_entity.dart';
import '../../domain/task_failures.dart';
import '../../domain/usecases/delete_time_entry_use_case.dart';
import '../../domain/usecases/register_manual_time_use_case.dart';
import '../../domain/usecases/update_time_entry_use_case.dart';
import '../../domain/usecases/watch_time_entries_by_target_use_case.dart';

part 'time_entry_event.dart';
part 'time_entry_state.dart';

/// CRUD dos registros de tempo (`timeEntries`) de uma folha. Só orquestra os
/// UseCases e traduz `Failure` → estado; o ajuste do acumulado por delta e as
/// validações moram nos UseCases (regra de negócio no domain).
@injectable
class TimeEntryBloc extends Bloc<TimeEntryEvent, TimeEntryState> {
  TimeEntryBloc(
    this._watchByTarget,
    this._registerManualTime,
    this._updateTimeEntry,
    this._deleteTimeEntry,
  ) : super(const TimeEntryLoading()) {
    on<TimeEntryStarted>(_onStarted);
    on<_TimeEntriesUpdated>(_onUpdated);
    on<TimeEntryAdded>(_onAdded);
    on<TimeEntryEdited>(_onEdited);
    on<TimeEntryDeleted>(_onDeleted);
    on<TimeEntryUndoRequested>(_onUndo);
  }

  final WatchTimeEntriesByTargetUseCase _watchByTarget;
  final RegisterManualTimeUseCase _registerManualTime;
  final UpdateTimeEntryUseCase _updateTimeEntry;
  final DeleteTimeEntryUseCase _deleteTimeEntry;

  StreamSubscription<Either<Failure, List<TimeEntryEntity>>>? _sub;

  String _targetId = '';
  String _listId = '';

  /// Último registro excluído, guardado para o "Desfazer".
  TimeEntryEntity? _lastDeleted;

  Future<void> _onStarted(
    TimeEntryStarted event,
    Emitter<TimeEntryState> emit,
  ) async {
    _targetId = event.targetId;
    _listId = event.listId;
    await _sub?.cancel();
    _sub = _watchByTarget(
      WatchTimeEntriesByTargetParams(targetId: _targetId),
    ).listen((result) => add(_TimeEntriesUpdated(result)));
  }

  void _onUpdated(_TimeEntriesUpdated event, Emitter<TimeEntryState> emit) {
    event.result.match(
      (failure) => emit(TimeEntryError(_mapFailure(failure))),
      (entries) => emit(
        entries.isEmpty ? const TimeEntryEmpty() : TimeEntryLoaded(entries),
      ),
    );
  }

  Future<void> _onAdded(
    TimeEntryAdded event,
    Emitter<TimeEntryState> emit,
  ) async {
    final result = await _registerManualTime(RegisterManualTimeParams(
      targetId: _targetId,
      targetIsLeaf: true,
      listId: _listId,
      minutes: event.minutes,
      now: event.occurredAt,
    ));
    _handleWrite(result, emit);
  }

  Future<void> _onEdited(
    TimeEntryEdited event,
    Emitter<TimeEntryState> emit,
  ) async {
    final result = await _updateTimeEntry(UpdateTimeEntryParams(
      original: event.original,
      newMinutes: event.minutes,
      newOccurredAt: event.occurredAt,
    ));
    _handleWrite(result, emit);
  }

  Future<void> _onDeleted(
    TimeEntryDeleted event,
    Emitter<TimeEntryState> emit,
  ) async {
    final result =
        await _deleteTimeEntry(DeleteTimeEntryParams(entry: event.entry));
    result.match(
      (failure) => emit(TimeEntryError(_mapFailure(failure))),
      (_) => _lastDeleted = event.entry,
    );
  }

  Future<void> _onUndo(
    TimeEntryUndoRequested event,
    Emitter<TimeEntryState> emit,
  ) async {
    final removed = _lastDeleted;
    if (removed == null) return;
    _lastDeleted = null;
    // Recria o registro re-somando ao acumulado (não é restore só-visual).
    final result = await _registerManualTime(RegisterManualTimeParams(
      targetId: removed.targetId,
      targetIsLeaf: true,
      listId: removed.listId,
      minutes: removed.minutes,
      now: removed.occurredAt,
    ));
    _handleWrite(result, emit);
  }

  /// Erros de escrita viram estado de erro; o sucesso reflete pelo stream.
  void _handleWrite<T>(Either<Failure, T> result, Emitter<TimeEntryState> e) {
    result.match((failure) => e(TimeEntryError(_mapFailure(failure))), (_) {});
  }

  String _mapFailure(Failure failure) => switch (failure) {
        InvalidDurationFailure() => 'Informe uma duração válida.',
        TimerOnNonLeafFailure() =>
          'Registro só em tarefas sem filhas (folhas).',
        TaskNotFoundFailure() => 'Tarefa não encontrada.',
        NetworkFailure() => 'Sem conexão. Verifique a internet.',
        _ => 'Algo deu errado. Tente novamente.',
      };

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
