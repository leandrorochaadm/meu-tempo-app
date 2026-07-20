import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class RestoreTasksParams extends Equatable {
  const RestoreTasksParams({required this.tasks});

  /// Subárvore a restaurar (raiz primeiro), como devolvida por `DeleteTaskUseCase`.
  final List<TaskEntity> tasks;

  @override
  List<Object?> get props => [tasks];
}

/// Desfaz uma exclusão em cascata: recria cada documento com o **id original**
/// (via `update`, que faz `set` com id fixo) e reativa o `hasChildren` do pai
/// externo, caso a exclusão o tenha zerado.
@lazySingleton
class RestoreTasksUseCase implements UseCase<Unit, RestoreTasksParams> {
  const RestoreTasksUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RestoreTasksParams params) async {
    if (params.tasks.isEmpty) return const Right(unit);

    for (final node in params.tasks) {
      final res = await _repository.update(node);
      final f = res.getLeft().toNullable();
      if (f != null) return Left(f);
    }

    // A raiz da subárvore é o primeiro elemento; reativa o pai externo se houver.
    final parentId = params.tasks.first.parentId;
    if (parentId != null) {
      return _repository.setHasChildren(parentId, true);
    }
    return const Right(unit);
  }
}
