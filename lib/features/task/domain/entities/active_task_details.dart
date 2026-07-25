import 'package:equatable/equatable.dart';

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
    required this.priority,
    required this.isOverdue,
  });

  /// Nome da lista da tarefa (vazio se a lista não foi encontrada).
  final String listName;

  /// Posição da lista na coleção do usuário — a UI a converte em cor
  /// determinística da paleta categórica.
  final int listColorIndex;

  /// `tempoEstimado × (5 − importância) × urgênciaDoPrazo`.
  final int priority;

  /// Prazo antes de hoje e tarefa não concluída.
  final bool isOverdue;

  @override
  List<Object?> get props => [listName, listColorIndex, priority, isOverdue];
}
