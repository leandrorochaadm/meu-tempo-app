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
  const ReportLoaded(
    this.rows, {
    required this.period,
    required this.range,
    required this.offset,
    required this.canGoForward,
  });
  final List<ListReportRow> rows;
  final ReportPeriodEnum period;
  final PeriodRange range;

  /// Passos em relação ao período atual (0 = atual, -1 = anterior).
  final int offset;

  /// Pode avançar (só quando não está no período atual).
  final bool canGoForward;

  @override
  List<Object?> get props => [rows, period, range, offset, canGoForward];
}

class ReportError extends ReportState {
  const ReportError();
}
