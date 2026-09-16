import 'package:injectable/injectable.dart';

import '../entities/task_entity.dart';

/// Decide **em qual lista** a próxima tarefa rápida nasce, para o usuário não
/// precisar escolher toda vez (H12 — "o app sugere a última lista usada").
///
/// Ordem de decisão (a primeira que valer ganha):
/// 1. escolha explícita do usuário na barra de criação;
/// 2. lista do filtro ativo na tela — está olhando "Trabalho", cria em "Trabalho";
/// 3. lista da **última tarefa criada** (a mais recente por `createdAt`);
/// 4. "Entrada".
///
/// Regra de negócio que cruza dados → UseCase; a barra recebe o destino pronto.
@lazySingleton
class GetDefaultCreationListUseCase {
  const GetDefaultCreationListUseCase();

  /// Transformação pura e síncrona (sem I/O).
  ///
  /// [availableListIds] vazio só acontece antes de o stream de listas chegar —
  /// aí não há como validar id nenhum e o destino é a "Entrada".
  String? call(
    List<TaskEntity> tasks, {
    required List<String> availableListIds,
    String? chosenListId,
    String? filterListId,
    String? inboxListId,
  }) {
    if (availableListIds.isEmpty) return inboxListId;

    bool exists(String? id) => id != null && availableListIds.contains(id);

    if (exists(chosenListId)) return chosenListId;
    if (exists(filterListId)) return filterListId;

    TaskEntity? latest;
    for (final task in tasks) {
      if (!exists(task.listId)) continue;
      if (latest == null || task.createdAt.isAfter(latest.createdAt)) {
        latest = task;
      }
    }
    if (latest != null) return latest.listId;

    return inboxListId;
  }
}
