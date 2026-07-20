import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';
import '../task_failures.dart';

class MoveTaskParams extends Equatable {
  const MoveTaskParams({required this.taskId, this.newParentId});

  final String taskId;

  /// `null` = promover a tarefa a mãe (raiz).
  final String? newParentId;

  @override
  List<Object?> get props => [taskId, newParentId];
}

/// Move uma tarefa na hierarquia (troca de mãe / promove a raiz). Barra ciclos
/// e respeita o limite de 3 níveis. O tempo passa a acumular na nova mãe/avó
/// (derivado — nada a recalcular além do `hasChildren` dos pais).
@lazySingleton
class MoveTaskUseCase implements UseCase<Unit, MoveTaskParams> {
  const MoveTaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(MoveTaskParams params) async {
    if (params.newParentId == params.taskId) {
      return const Left(InvalidMoveFailure());
    }

    final result = await _repository.getTasks();
    final failure = result.getLeft().toNullable();
    if (failure != null) return Left(failure);
    final tasks = result.getRight().toNullable()!;

    final byId = {for (final t in tasks) t.id: t};
    final task = byId[params.taskId];
    if (task == null) return const Left(TaskNotFoundFailure());

    final childrenOf = <String, List<TaskEntity>>{};
    for (final t in tasks) {
      if (t.parentId != null) {
        childrenOf.putIfAbsent(t.parentId!, () => []).add(t);
      }
    }

    // Ciclo: novo pai não pode ser o próprio nó nem um descendente.
    if (params.newParentId != null) {
      if (_isDescendant(params.newParentId!, params.taskId, childrenOf)) {
        return const Left(InvalidMoveFailure());
      }
      if (byId[params.newParentId] == null) {
        return const Left(TaskNotFoundFailure());
      }
    }

    // Limite de 3 níveis: profundidade do novo pai + altura da subárvore movida.
    final newParentDepth =
        params.newParentId == null ? -1 : _depth(params.newParentId!, byId);
    final subtreeHeight = _height(params.taskId, childrenOf);
    if ((newParentDepth + 1) + subtreeHeight > 2) {
      return const Left(MaxLevelExceededFailure());
    }

    final oldParentId = task.parentId;

    final moved = TaskEntity(
      id: task.id,
      title: task.title,
      listId: task.listId,
      createdAt: task.createdAt,
      parentId: params.newParentId,
      estimatedMinutes: task.estimatedMinutes,
      dueDate: task.dueDate,
      importance: task.importance,
      isDone: task.isDone,
      hasChildren: task.hasChildren,
      spentMinutes: task.spentMinutes,
    );

    final upd = await _repository.update(moved);
    final f = upd.getLeft().toNullable();
    if (f != null) return Left(f);

    if (params.newParentId != null) {
      await _repository.setHasChildren(params.newParentId!, true);
    }
    if (oldParentId != null && oldParentId != params.newParentId) {
      final stillHas = (childrenOf[oldParentId] ?? const [])
          .where((c) => c.id != params.taskId)
          .isNotEmpty;
      if (!stillHas) await _repository.setHasChildren(oldParentId, false);
    }

    return const Right(unit);
  }

  bool _isDescendant(
    String candidate,
    String ancestor,
    Map<String, List<TaskEntity>> childrenOf,
  ) {
    for (final c in childrenOf[ancestor] ?? const <TaskEntity>[]) {
      if (c.id == candidate) return true;
      if (_isDescendant(candidate, c.id, childrenOf)) return true;
    }
    return false;
  }

  int _depth(String id, Map<String, TaskEntity> byId) {
    var depth = 0;
    var parentId = byId[id]?.parentId;
    while (parentId != null) {
      depth++;
      parentId = byId[parentId]?.parentId;
    }
    return depth;
  }

  int _height(String id, Map<String, List<TaskEntity>> childrenOf) {
    final children = childrenOf[id] ?? const <TaskEntity>[];
    if (children.isEmpty) return 0;
    var max = 0;
    for (final c in children) {
      final h = _height(c.id, childrenOf);
      if (h > max) max = h;
    }
    return max + 1;
  }
}
