import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../../list/domain/usecases/watch_lists_use_case.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/entities/time_entry_entity.dart';
import '../../../task/domain/usecases/watch_tasks_use_case.dart';
import '../../../task/domain/usecases/watch_time_entries_use_case.dart';
import '../../domain/entities/list_report_row.dart';
import '../../domain/entities/period_range.dart';
import '../../domain/entities/report_period_enum.dart';
import '../../domain/usecases/get_list_report_use_case.dart';

part 'report_event.dart';
part 'report_state.dart';

/// Relatório de tempo por lista (estimado × real) filtrável por período
/// (dia/semana/mês). Combina registros de tempo, tarefas e listas; a agregação
/// vive no UseCase.
@injectable
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc(
    this._watchTasks,
    this._watchLists,
    this._watchTimeEntries,
    this._getReport,
  ) : super(const ReportLoading()) {
    on<ReportStarted>(_onStarted);
    on<ReportTasksUpdated>(_onTasksUpdated);
    on<ReportListsUpdated>(_onListsUpdated);
    on<ReportEntriesUpdated>(_onEntriesUpdated);
    on<ReportPeriodChanged>(_onPeriodChanged);
    on<ReportPeriodStepped>(_onPeriodStepped);
  }

  final WatchTasksUseCase _watchTasks;
  final WatchListsUseCase _watchLists;
  final WatchTimeEntriesUseCase _watchTimeEntries;
  final GetListReportUseCase _getReport;

  StreamSubscription<Either<Failure, List<TaskEntity>>>? _tasksSub;
  StreamSubscription<Either<Failure, List<TaskListEntity>>>? _listsSub;
  StreamSubscription<Either<Failure, List<TimeEntryEntity>>>? _entriesSub;

  List<TaskEntity> _tasks = const [];
  List<TaskListEntity> _lists = const [];
  List<TimeEntryEntity> _entries = const [];
  ReportPeriodEnum _period = ReportPeriodEnum.day;
  int _offset = 0;
  PeriodRange _range = PeriodRange.of(ReportPeriodEnum.day, DateTime.now());

  Future<void> _onStarted(ReportStarted e, Emitter<ReportState> emit) async {
    emit(const ReportLoading());
    await _tasksSub?.cancel();
    _tasksSub =
        _watchTasks(const NoParams()).listen((r) => add(ReportTasksUpdated(r)));
    await _listsSub?.cancel();
    _listsSub =
        _watchLists(const NoParams()).listen((r) => add(ReportListsUpdated(r)));
    _subscribeEntries();
  }

  Future<void> _onPeriodChanged(
    ReportPeriodChanged e,
    Emitter<ReportState> emit,
  ) async {
    _period = e.period;
    _offset = 0; // trocar de período volta ao atual
    _subscribeEntries();
    _emitLoaded(emit);
  }

  Future<void> _onPeriodStepped(
    ReportPeriodStepped e,
    Emitter<ReportState> emit,
  ) async {
    // Sem limite para trás; trava no período atual para frente (offset <= 0).
    final next = _offset + e.direction;
    if (next > 0) return;
    _offset = next;
    _subscribeEntries();
    _emitLoaded(emit);
  }

  void _subscribeEntries() {
    _range = PeriodRange.at(_period, DateTime.now(), _offset);
    _entriesSub?.cancel();
    _entriesSub = _watchTimeEntries(
      WatchTimeEntriesParams(start: _range.start, end: _range.end),
    ).listen((r) => add(ReportEntriesUpdated(r)));
  }

  void _onTasksUpdated(ReportTasksUpdated e, Emitter<ReportState> emit) {
    e.result.match((f) => emit(const ReportError()), (tasks) {
      _tasks = tasks;
      _emitLoaded(emit);
    });
  }

  void _onListsUpdated(ReportListsUpdated e, Emitter<ReportState> emit) {
    e.result.match((f) => emit(const ReportError()), (lists) {
      _lists = lists;
      _emitLoaded(emit);
    });
  }

  void _onEntriesUpdated(ReportEntriesUpdated e, Emitter<ReportState> emit) {
    e.result.match((f) => emit(const ReportError()), (entries) {
      _entries = entries;
      _emitLoaded(emit);
    });
  }

  void _emitLoaded(Emitter<ReportState> emit) {
    emit(ReportLoaded(
      _getReport(_entries, _tasks, _lists),
      period: _period,
      range: _range,
      offset: _offset,
      canGoForward: _offset < 0,
    ));
  }

  @override
  Future<void> close() {
    _tasksSub?.cancel();
    _listsSub?.cancel();
    _entriesSub?.cancel();
    return super.close();
  }
}
