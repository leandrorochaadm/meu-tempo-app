part of 'report_detail_bloc.dart';

sealed class ReportDetailEvent extends Equatable {
  const ReportDetailEvent();

  @override
  List<Object?> get props => const [];
}

/// Abre o detalhe de uma lista num período (reconstruído de `period` + `offset`).
class ReportDetailStarted extends ReportDetailEvent {
  const ReportDetailStarted({
    required this.listId,
    required this.period,
    required this.offset,
    this.listName,
  });

  final String listId;
  final ReportPeriodEnum period;
  final int offset;
  final String? listName;

  @override
  List<Object?> get props => [listId, period, offset, listName];
}

class ReportDetailSortChanged extends ReportDetailEvent {
  const ReportDetailSortChanged(this.sort);
  final TaskReportSortEnum sort;

  @override
  List<Object?> get props => [sort];
}

class _ReportDetailTasksUpdated extends ReportDetailEvent {
  const _ReportDetailTasksUpdated(this.result);
  final Either<Failure, List<TaskEntity>> result;

  @override
  List<Object?> get props => [result];
}

class _ReportDetailAppointmentsUpdated extends ReportDetailEvent {
  const _ReportDetailAppointmentsUpdated(this.result);
  final Either<Failure, List<AppointmentEntity>> result;

  @override
  List<Object?> get props => [result];
}

class _ReportDetailEntriesUpdated extends ReportDetailEvent {
  const _ReportDetailEntriesUpdated(this.result);
  final Either<Failure, List<TimeEntryEntity>> result;

  @override
  List<Object?> get props => [result];
}

class _ReportDetailListsUpdated extends ReportDetailEvent {
  const _ReportDetailListsUpdated(this.result);
  final Either<Failure, List<TaskListEntity>> result;

  @override
  List<Object?> get props => [result];
}
