part of 'report_detail_bloc.dart';

sealed class ReportDetailState extends Equatable {
  const ReportDetailState();

  @override
  List<Object?> get props => const [];
}

class ReportDetailLoading extends ReportDetailState {
  const ReportDetailLoading();
}

class ReportDetailLoaded extends ReportDetailState {
  const ReportDetailLoaded({
    required this.report,
    required this.listName,
    required this.range,
    required this.period,
    required this.sort,
  });

  final TaskReport report;
  final String listName;
  final PeriodRange range;
  final ReportPeriodEnum period;
  final TaskReportSortEnum sort;

  @override
  List<Object?> get props => [report, listName, range, period, sort];
}

class ReportDetailError extends ReportDetailState {
  const ReportDetailError();
}
