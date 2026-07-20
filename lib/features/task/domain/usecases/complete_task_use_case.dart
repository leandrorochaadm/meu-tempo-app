import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CompleteTaskParams extends Equatable {
  const CompleteTaskParams({required this.taskId, required this.done});

  final String taskId;
  final bool done;

  @override
  List<Object?> get props => [taskId, done];
}

/// Marca uma folha como feita/não feita e propaga para cima: a mãe/avó é
/// concluída **automaticamente** quando todas as filhas estão feitas (e
/// reaberta se alguma deixar de estar).
@lazySingleton
class CompleteTaskUseCase implements UseCase<Unit, CompleteTaskParams> {
  const CompleteTaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(CompleteTaskParams params) async {
    final result = await _repository.getTasks();
    final failure = result.getLeft().toNullable();
    if (failure != null) return Left(failure);
    final tasks = result.getRight().toNullable()!;

    final byId = {for (final t in tasks) t.id: t};
    final childrenOf = <String, List<TaskEntity>>{};
    for (final t in tasks) {
      if (t.parentId != null) {
        childrenOf.putIfAbsent(t.parentId!, () => []).add(t);
      }
    }

    // Estado de conclusão desejado (override do que está persistido).
    final desired = <String, bool>{params.taskId: params.done};

    // Sobe recalculando cada ancestral: feito ⟺ todas as filhas feitas.
    var currentId = byId[params.taskId]?.parentId;
    while (currentId != null) {
      final children = childrenOf[currentId] ?? const [];
      final allDone = children.every((c) => desired[c.id] ?? c.isDone);
      desired[currentId] = allDone;
      currentId = byId[currentId]?.parentId;
    }

    // Persiste só o que mudou.
    for (final entry in desired.entries) {
      final task = byId[entry.key];
      if (task == null || task.isDone == entry.value) continue;
      final res = await _repository.setDone(entry.key, entry.value);
      final f = res.getLeft().toNullable();
      if (f != null) return Left(f);
    }

    return const Right(unit);
  }
}
