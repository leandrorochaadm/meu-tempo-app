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
import '../../../task/domain/usecases/watch_tasks_use_case.dart';
import '../../domain/entities/list_report_row.dart';
import '../../domain/usecases/get_list_report_use_case.dart';

part 'report_event.dart';
part 'report_state.dart';

/// Relatório de tempo por lista (estimado × real). Combina tarefas e listas;
/// a agregação vive no UseCase.
@injectable
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc(this._watchTasks, this._watchLists, this._getReport)
      : super(const ReportLoading()) {
    on<ReportStarted>(_onStarted);
    on<ReportTasksUpdated>(_onTasksUpdated);
    on<ReportListsUpdated>(_onListsUpdated);
  }

  final WatchTasksUseCase _watchTasks;
  final WatchListsUseCase _watchLists;
  final GetListReportUseCase _getReport;

  StreamSubscription<Either<Failure, List<TaskEntity>>>? _tasksSub;
  StreamSubscription<Either<Failure, List<TaskListEntity>>>? _listsSub;

  List<TaskEntity> _tasks = const [];
  List<TaskListEntity> _lists = const [];

  Future<void> _onStarted(ReportStarted e, Emitter<ReportState> emit) async {
    emit(const ReportLoading());
    await _tasksSub?.cancel();
    _tasksSub =
        _watchTasks(const NoParams()).listen((r) => add(ReportTasksUpdated(r)));
    await _listsSub?.cancel();
    _listsSub =
        _watchLists(const NoParams()).listen((r) => add(ReportListsUpdated(r)));
  }

  void _onTasksUpdated(ReportTasksUpdated e, Emitter<ReportState> emit) {
    e.result.match((f) => emit(const ReportError()), (tasks) {
      _tasks = tasks;
      emit(ReportLoaded(_getReport(_tasks, _lists)));
    });
  }

  void _onListsUpdated(ReportListsUpdated e, Emitter<ReportState> emit) {
    e.result.match((f) => emit(const ReportError()), (lists) {
      _lists = lists;
      emit(ReportLoaded(_getReport(_tasks, _lists)));
    });
  }

  @override
  Future<void> close() {
    _tasksSub?.cancel();
    _listsSub?.cancel();
    return super.close();
  }
}
