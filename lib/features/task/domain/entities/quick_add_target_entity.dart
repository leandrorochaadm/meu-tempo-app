import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_defaults.dart';

/// Alvo da criação rápida: a última tarefa criada na barra, oferecida como mãe
/// do próximo lançamento (mãe → filha → neta sem caçar o item na árvore, H12).
///
/// Imutável e pura — a regra "ainda aceita filha" é intrínseca ao alvo.
class QuickAddTargetEntity extends Equatable {
  const QuickAddTargetEntity({
    required this.taskId,
    required this.title,
    required this.listId,
    required this.level,
  });

  final String taskId;
  final String title;
  final String listId;

  /// Nível da tarefa na hierarquia: mãe(0), filha(1), neta(2).
  final int level;

  /// Regra intrínseca: neta é o último nível — não aceita filha.
  bool get acceptsChild => level < AppDefaults.maxTaskLevel;

  @override
  List<Object?> get props => [taskId, title, listId, level];
}
