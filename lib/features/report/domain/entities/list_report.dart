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

  bool get isEmpty => rows.isEmpty;

  @override
  List<Object?> get props => [rows];
}
