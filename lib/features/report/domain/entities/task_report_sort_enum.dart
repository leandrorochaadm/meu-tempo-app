/// Ordenação do detalhe do relatório (nós de topo de uma lista no período).
enum TaskReportSortEnum {
  /// Maior tempo gasto no topo.
  spent,

  /// Quem mais passou da estimativa no topo (sem estouro vai ao fim).
  overrun,
}
