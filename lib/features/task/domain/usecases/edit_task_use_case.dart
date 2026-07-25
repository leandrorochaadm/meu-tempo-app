import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/importance_enum.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';
import '../task_failures.dart';

class EditTaskParams extends Equatable {
  const EditTaskParams({
    required this.taskId,
    required this.title,
    this.estimatedMinutes,
    this.dueDate,
    this.importance,
    this.listId,
  });

  final String taskId;
  final String title;
  final int? estimatedMinutes;
  final DateTime? dueDate;
  final ImportanceEnum? importance;
  final String? listId;

  @override
  List<Object?> get props =>
      [taskId, title, estimatedMinutes, dueDate, importance, listId];
}

/// Edita os campos de uma tarefa (título e, na folha, tempo/prazo/importância/
/// lista). Recalcula prioridade indiretamente (a listagem reordena na abertura).
@lazySingleton
class EditTaskUseCase implements UseCase<Unit, EditTaskParams> {
  const EditTaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(EditTaskParams params) async {
    final title = params.title.trim();
    if (title.isEmpty) return const Left(EmptyTitleFailure());

    final result = await _repository.getTasks();
    final failure = result.getLeft().toNullable();
    if (failure != null) return Left(failure);
    final tasks = result.getRight().toNullable()!;

    final byId = {for (final t in tasks) t.id: t};
    final task = byId[params.taskId];
    if (task == null) return const Left(TaskNotFoundFailure());

    // Regra: **a lista pertence à árvore**. Só a tarefa mãe (raiz) escolhe a
    // lista; filha e neta herdam a da mãe, ignorando o que vier em `params`.
    // Normaliza também dado legado divergente: salvar a tarefa a realinha.
    final parent = task.parentId == null ? null : byId[task.parentId];
    final newListId = parent != null
        ? parent.listId
        : (params.listId ?? task.listId);

    final edited = TaskEntity(
      id: task.id,
      title: title,
      listId: newListId,
      createdAt: task.createdAt,
      parentId: task.parentId,
      estimatedMinutes: params.estimatedMinutes ?? task.estimatedMinutes,
      dueDate: params.dueDate ?? task.dueDate,
      importance: params.importance ?? task.importance,
      isDone: task.isDone,
      hasChildren: task.hasChildren,
      spentMinutes: task.spentMinutes,
    );

    // Regra: trocar a lista de uma mãe/avó propaga para todas as filhas/netas
    // (a lista é da árvore). Só varre quando é mãe (tem filhas) e a lista
    // mudou — evita reescrever a subárvore a cada edição de folha.
    final propagate = task.hasChildren && task.listId != newListId;
    if (!propagate) return _repository.update(edited);

    // A tarefa e a subárvore vão num **único commit**: uma falha no meio
    // deixaria parte da árvore numa lista e parte em outra.
    return _repository.updateAll([
      edited,
      for (final d in _descendantsOf(task.id, tasks))
        TaskEntity(
          id: d.id,
          title: d.title,
          listId: newListId,
          createdAt: d.createdAt,
          parentId: d.parentId,
          estimatedMinutes: d.estimatedMinutes,
          dueDate: d.dueDate,
          importance: d.importance,
          isDone: d.isDone,
          hasChildren: d.hasChildren,
          spentMinutes: d.spentMinutes,
        ),
    ]);
  }

  /// Todos os descendentes (filhas e netas) de [rootId], via `parentId`.
  List<TaskEntity> _descendantsOf(String rootId, List<TaskEntity> tasks) {
    final childrenOf = <String, List<TaskEntity>>{};
    for (final t in tasks) {
      if (t.parentId != null) {
        childrenOf.putIfAbsent(t.parentId!, () => []).add(t);
      }
    }
    final out = <TaskEntity>[];
    void visit(String id) {
      for (final c in childrenOf[id] ?? const <TaskEntity>[]) {
        out.add(c);
        visit(c.id);
      }
    }

    visit(rootId);
    return out;
  }
}
