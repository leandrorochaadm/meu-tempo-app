part of 'report_bloc.dart';

sealed class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => const [];
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportLoaded extends ReportState {
  const ReportLoaded(this.rows, {required this.period});
  final List<ListReportRow> rows;
  final ReportPeriodEnum period;

  @override
  List<Object?> get props => [rows, period];
}

class ReportError extends ReportState {
  const ReportError();
}
