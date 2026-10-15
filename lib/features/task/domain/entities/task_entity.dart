import 'package:equatable/equatable.dart';

import 'importance_enum.dart';

/// Tarefa. Só a **folha** (sem filhas) tem tempo estimado, data de entrega,
/// importância e cronômetro. `hasChildren` é mantido pela camada data e é a
/// base do getter intrínseco [isLeaf].
///
/// Imutável e pura — sem `copyWith`, sem serialização.
class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.listId,
    required this.createdAt,
    this.parentId,
    this.estimatedMinutes,
    this.dueDate,
    this.importance,
    this.isDone = false,
    this.hasChildren = false,
    this.spentMinutes = 0,
    this.recurringTaskId,
  });

  final String id;
  final String title;
  final String listId;
  final DateTime createdAt;

  /// `null` = tarefa mãe (raiz).
  final String? parentId;

  // Campos exclusivos da folha:
  final int? estimatedMinutes;
  final DateTime? dueDate;
  final ImportanceEnum? importance;

  final bool isDone;
  final bool hasChildren;

  /// Tempo real acumulado na folha (cronômetro + manual), em minutos.
  final int spentMinutes;

  /// Modelo recorrente que gerou esta tarefa; `null` = tarefa comum.
  final String? recurringTaskId;

  /// Regra intrínseca: folha = tarefa sem filhas.
  bool get isLeaf => !hasChildren;

  /// Regra intrínseca (R5/H15): instância ainda não concluída do modelo
  /// [recurringId]. Usada para avisar/evitar duplicata na geração.
  bool isPendingInstanceOf(String recurringId) =>
      recurringTaskId == recurringId && !isDone;

  @override
  List<Object?> get props => [
    id,
    title,
    listId,
    createdAt,
    parentId,
    estimatedMinutes,
    dueDate,
    importance,
    isDone,
    hasChildren,
    spentMinutes,
    recurringTaskId,
  ];
}
