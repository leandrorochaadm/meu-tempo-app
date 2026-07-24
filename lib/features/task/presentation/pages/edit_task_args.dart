import '../../../list/domain/entities/task_list_entity.dart';
import '../../domain/entities/parent_candidate_entity.dart';
import '../../domain/entities/task_edit_context.dart';
import '../../domain/entities/task_entity.dart';

/// Candidato a tarefa mãe, com breadcrumb dos ancestrais para desambiguar
/// títulos parecidos. Derivado do [ParentCandidateEntity] do domínio.
class ParentCandidate {
  const ParentCandidate({
    required this.id,
    required this.title,
    required this.path,
  });

  final String id;
  final String title;
  final String path;

  /// Monta o breadcrumb legível a partir do dado estruturado do domínio.
  /// Ex.: "Lançar app › Fazer telas · tarefa filha" (só o nível se for raiz).
  factory ParentCandidate.fromEntity(ParentCandidateEntity e) {
    final level = _levelLabel(e.level);
    final path = e.ancestorTitles.isEmpty
        ? level
        : '${e.ancestorTitles.join(' › ')} · $level';
    return ParentCandidate(id: e.id, title: e.title, path: path);
  }

  static String _levelLabel(int level) => switch (level) {
        0 => 'tarefa mãe',
        1 => 'tarefa filha',
        _ => 'tarefa neta',
      };
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

  /// Monta os argumentos a partir do contexto de domínio + listas do usuário.
  factory EditTaskArgs.fromContext(
    TaskEditContext context,
    List<TaskListEntity> lists,
  ) {
    return EditTaskArgs(
      task: context.task,
      lists: lists,
      parentCandidates:
          context.parentCandidates.map(ParentCandidate.fromEntity).toList(),
      currentParentLabel: context.currentParentLabel,
    );
  }
}
