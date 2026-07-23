import 'package:equatable/equatable.dart';

import 'list_report_row.dart';

/// Relatório por lista de um período: as linhas mais os **totais agregados**.
///
/// Os totais são getters (agregação intrínseca ao objeto) — a `presentation`
/// recebe o valor pronto e apenas o exibe, nunca soma as linhas.
class ListReport extends Equatable {
  ListReport(List<ListReportRow> rows) : rows = List.unmodifiable(rows);

  final List<ListReportRow> rows;

  /// Soma do tempo estimado de todas as listas do período.
  int get totalEstimatedMinutes =>
      rows.fold(0, (sum, r) => sum + r.estimatedMinutes);

  /// Soma do tempo real de todas as listas do período.
  int get totalSpentMinutes => rows.fold(0, (sum, r) => sum + r.spentMinutes);

  /// Fração (0..1) que o tempo gasto de [row] representa no total do período.
  /// `0` quando o total é zero (sem base de comparação).
  double shareRatio(ListReportRow row) =>
      totalSpentMinutes == 0 ? 0 : row.spentMinutes / totalSpentMinutes;

  /// Percentual (0..100) que o tempo gasto de [row] representa no total gasto do
  /// período. `null` quando o total é zero (sem base de comparação).
  double? sharePercent(ListReportRow row) =>
      totalSpentMinutes == 0 ? null : shareRatio(row) * 100;

  bool get isEmpty => rows.isEmpty;

  @override
  List<Object?> get props => [rows];
}
