part of 'report_bloc.dart';

sealed class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => const [];
}

class ReportStarted extends ReportEvent {
  const ReportStarted();
}

class ReportTasksUpdated extends ReportEvent {
  const ReportTasksUpdated(this.result);
  final Either<Failure, List<TaskEntity>> result;

  @override
  List<Object?> get props => [result];
}

class ReportListsUpdated extends ReportEvent {
  const ReportListsUpdated(this.result);
  final Either<Failure, List<TaskListEntity>> result;

  @override
  List<Object?> get props => [result];
}

class ReportEntriesUpdated extends ReportEvent {
  const ReportEntriesUpdated(this.result);
  final Either<Failure, List<TimeEntryEntity>> result;

  @override
  List<Object?> get props => [result];
}

class ReportPeriodChanged extends ReportEvent {
  const ReportPeriodChanged(this.period);
  final ReportPeriodEnum period;

  @override
  List<Object?> get props => [period];
}

/// Navega o período em [direction] passos (-1 = anterior, +1 = seguinte).
class ReportPeriodStepped extends ReportEvent {
  const ReportPeriodStepped(this.direction);
  final int direction;

  @override
  List<Object?> get props => [direction];
}
