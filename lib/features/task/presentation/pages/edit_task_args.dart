import '../../../list/domain/entities/task_list_entity.dart';
import '../../domain/entities/task_entity.dart';

/// Candidato a tarefa mãe, com breadcrumb dos ancestrais para desambiguar
/// títulos parecidos. Derivado do record `({node, path})` de `_moveCandidates`.
class ParentCandidate {
  const ParentCandidate({
    required this.id,
    required this.title,
    required this.path,
  });

  final String id;
  final String title;
  final String path;
}

/// Argumentos da rota de edição — tudo já resolvido na `presentation` de origem
/// (listas, candidatos a mãe e breadcrumb da mãe atual), para o formulário só
/// exibir/escolher sem calcular nada.
class EditTaskArgs {
  const EditTaskArgs({
    required this.task,
    required this.lists,
    required this.parentCandidates,
    required this.currentParentLabel,
  });

  final TaskEntity task;
  final List<TaskListEntity> lists;

  /// Candidatos a nova mãe (exclui a própria e seus descendentes).
  final List<ParentCandidate> parentCandidates;

  /// Breadcrumb da mãe atual (vazio se a tarefa já é raiz).
  final String currentParentLabel;
}
