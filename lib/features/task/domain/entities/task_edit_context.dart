import 'package:equatable/equatable.dart';

import 'parent_candidate_entity.dart';
import 'task_entity.dart';

/// Contexto pronto para editar/mover uma tarefa — resolvido no domínio para a
/// `presentation` não calcular nada: a própria tarefa, os candidatos válidos a
/// nova mãe e o breadcrumb da mãe atual. Cruza dados (a árvore inteira) → é
/// produto de um UseCase, não getter de Entity.
class TaskEditContext extends Equatable {
  TaskEditContext({
    required this.task,
    required List<ParentCandidateEntity> parentCandidates,
    required this.currentParentLabel,
  }) : parentCandidates = List.unmodifiable(parentCandidates);

  final TaskEntity task;

  /// Destinos válidos ("pode virar filha de…"): exclui a própria, seus
  /// descendentes e as netas.
  final List<ParentCandidateEntity> parentCandidates;

  /// Breadcrumb "mãe › avó" da posição atual (vazio se a tarefa já é raiz).
  final String currentParentLabel;

  @override
  List<Object?> get props => [task, parentCandidates, currentParentLabel];
}
