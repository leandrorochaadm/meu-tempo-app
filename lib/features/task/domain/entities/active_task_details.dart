import 'package:equatable/equatable.dart';

import 'priority_breakdown.dart';

/// Metadados resolvidos da folha em contagem, prontos para a barra do
/// cronômetro exibir sem calcular nada: a lista à qual pertence, a pontuação de
/// prioridade e se o prazo está vencido.
///
/// Tudo aqui cruza dados externos (as listas do usuário, a data de hoje), por
/// isso é produto de UseCase — não getter de Entity (ver `architecture.md`).
class ActiveTaskDetails extends Equatable {
  const ActiveTaskDetails({
    required this.listName,
    required this.listColorIndex,
    required this.breakdown,
    required this.rank,
    required this.isOverdue,
  });

  /// Nome da lista da tarefa (vazio se a lista não foi encontrada).
  final String listName;

  /// Posição da lista na coleção do usuário — a UI a converte em cor
  /// determinística da paleta categórica.
  final int listColorIndex;

  /// Fatores do cálculo da prioridade, prontos para exibição.
  final PriorityBreakdown breakdown;

  /// `tempoEstimado × (5 − importância) × urgênciaDoPrazo` — derivada do
  /// [breakdown], nunca recalculada na UI.
  int get priority => breakdown.total;

  /// Posição da tarefa na fila de prioridade (1 = próxima). `null` quando ela
  /// não entra na fila — concluída ou já virou mãe.
  final int? rank;

  /// Prazo antes de hoje e tarefa não concluída.
  final bool isOverdue;

  @override
  List<Object?> get props =>
      [listName, listColorIndex, breakdown, rank, isOverdue];
}
