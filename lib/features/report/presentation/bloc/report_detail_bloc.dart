import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../appointment/domain/entities/appointment_entity.dart';
import '../../../appointment/domain/usecases/watch_all_appointments_use_case.dart';
import '../../../list/domain/entities/task_list_entity.dart';
import '../../../list/domain/usecases/watch_lists_use_case.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/entities/time_entry_entity.dart';
import '../../../task/domain/usecases/watch_tasks_use_case.dart';
import '../../../task/domain/usecases/watch_time_entries_use_case.dart';
import '../../domain/entities/period_range.dart';
import '../../domain/entities/report_period_enum.dart';
import '../../domain/entities/report_tree_node.dart';
import '../../domain/entities/task_report_sort_enum.dart';
import '../../domain/usecases/get_task_report_use_case.dart';

part 'report_detail_event.dart';
part 'report_detail_state.dart';

/// Detalhe do relatório: tarefas e compromissos de uma lista dentro de um
/// período, com gasto × estimado + estouro, ordenável. A agregação vive no
/// `GetTaskReportUseCase`; o bloc só orquestra streams e re-agrega ao trocar a
/// ordenação (recomputar é barato — dados já em memória).
@injectable
class ReportDetailBloc extends Bloc<ReportDetailEvent, ReportDetailState> {
  ReportDetailBloc(
    this._watchTasks,
    this._watchAppointments,
    this._watchTimeEntries,
    this._watchLists,
    this._getTaskReport,
  ) : super(const ReportDetailLoading()) {
    on<ReportDetailStarted>(_onStarted);
    on<ReportDetailSortChanged>(_onSortChanged);
    on<_ReportDetailTasksUpdated>(_onTasksUpdated);
    on<_ReportDetailAppointmentsUpdated>(_onAppointmentsUpdated);
    on<_ReportDetailEntriesUpdated>(_onEntriesUpdated);
    on<_ReportDetailListsUpdated>(_onListsUpdated);
  }

  final WatchTasksUseCase _watchTasks;
  final WatchAllAppointmentsUseCase _watchAppointments;
  final WatchTimeEntriesUseCase _watchTimeEntries;
  final WatchListsUseCase _watchLists;
  final GetTaskReportUseCase _getTaskReport;

  StreamSubscription<Either<Failure, List<TaskEntity>>>? _tasksSub;
  StreamSubscription<Either<Failure, List<AppointmentEntity>>>? _apptsSub;
  StreamSubscription<Either<Failure, List<TimeEntryEntity>>>? _entriesSub;
  StreamSubscription<Either<Failure, List<TaskListEntity>>>? _listsSub;

  List<TaskEntity> _tasks = const [];
  List<AppointmentEntity> _appts = const [];
  List<TimeEntryEntity> _entries = const [];
  List<TaskListEntity> _lists = const [];

  String _listId = '';
  String? _listName;
  ReportPeriodEnum _period = ReportPeriodEnum.day;
  PeriodRange _range = PeriodRange.of(ReportPeriodEnum.day, DateTime.now());
  TaskReportSortEnum _sort = TaskReportSortEnum.spent;

  Future<void> _onStarted(
    ReportDetailStarted e,
    Emitter<ReportDetailState> emit,
  ) async {
    _listId = e.listId;
    _listName = e.listName;
    _period = e.period;
    _range = PeriodRange.at(e.period, DateTime.now(), e.offset);

    await _tasksSub?.cancel();
    _tasksSub = _watchTasks(const WatchTasksParams())
        .listen((r) => add(_ReportDetailTasksUpdated(r)));
    await _apptsSub?.cancel();
    _apptsSub = _watchAppointments(const NoParams())
        .listen((r) => add(_ReportDetailAppointmentsUpdated(r)));
    await _listsSub?.cancel();
    _listsSub = _watchLists(const NoParams())
        .listen((r) => add(_ReportDetailListsUpdated(r)));
    await _entriesSub?.cancel();
    _entriesSub = _watchTimeEntries(
      WatchTimeEntriesParams(start: _range.start, end: _range.end),
    ).listen((r) => add(_ReportDetailEntriesUpdated(r)));
  }

  void _onSortChanged(
    ReportDetailSortChanged e,
    Emitter<ReportDetailState> emit,
  ) {
    _sort = e.sort;
    _emitLoaded(emit);
  }

  void _onTasksUpdated(
    _ReportDetailTasksUpdated e,
    Emitter<ReportDetailState> emit,
  ) {
    e.result.match((_) => emit(const ReportDetailError()), (tasks) {
      _tasks = tasks;
      _emitLoaded(emit);
    });
  }

  void _onAppointmentsUpdated(
    _ReportDetailAppointmentsUpdated e,
    Emitter<ReportDetailState> emit,
  ) {
    e.result.match((_) => emit(const ReportDetailError()), (appts) {
      _appts = appts;
      _emitLoaded(emit);
    });
  }

  void _onEntriesUpdated(
    _ReportDetailEntriesUpdated e,
    Emitter<ReportDetailState> emit,
  ) {
    e.result.match((_) => emit(const ReportDetailError()), (entries) {
      _entries = entries;
      _emitLoaded(emit);
    });
  }

  void _onListsUpdated(
    _ReportDetailListsUpdated e,
    Emitter<ReportDetailState> emit,
  ) {
    e.result.match((_) => emit(const ReportDetailError()), (lists) {
      _lists = lists;
      _emitLoaded(emit);
    });
  }

  void _emitLoaded(Emitter<ReportDetailState> emit) {
    // Resolve o nome da lista pelo id (fallback quando `extra` sumiu no refresh).
    final matches = _lists.where((l) => l.id == _listId);
    final name = _listName ?? (matches.isEmpty ? null : matches.first.name);
    emit(ReportDetailLoaded(
      report: _getTaskReport(_entries, _tasks, _appts, _listId, _sort),
      listName: name ?? 'Lista',
      range: _range,
      period: _period,
      sort: _sort,
    ));
  }

  @override
  Future<void> close() {
    _tasksSub?.cancel();
    _apptsSub?.cancel();
    _entriesSub?.cancel();
    _listsSub?.cancel();
    return super.close();
  }
}
