import '../entities/task_entity.dart';

/// Monta o rótulo de hierarquia "mãe › avó" de uma folha, andando a cadeia de
/// `parentId`. Ex.: "Lançar app › Fazer telas" (vazio se a folha for raiz).
///
/// Extraído para ser reutilizado pela listagem por prioridade e pelo detalhe do
/// relatório — a regra de "como se lê a ancestralidade" vive no domínio, uma vez só.
class AncestryLabelBuilder {
  const AncestryLabelBuilder._();

  static String of(TaskEntity leaf, Map<String, TaskEntity> byId) {
    final chain = <String>[];
    var parentId = leaf.parentId;
    while (parentId != null) {
      final parent = byId[parentId];
      if (parent == null) break;
      chain.insert(0, parent.title);
      parentId = parent.parentId;
    }
    return chain.join(' › ');
  }
}
