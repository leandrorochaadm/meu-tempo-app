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
  const ReportLoaded(this.rows);
  final List<ListReportRow> rows;

  @override
  List<Object?> get props => [rows];
}

class ReportError extends ReportState {
  const ReportError();
}
