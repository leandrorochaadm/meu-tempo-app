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

    // Recriar a subárvore e reativar o pai externo é uma escrita **atômica**:
    // um desfazer parcial deixaria a hierarquia pela metade. A raiz da subárvore
    // é o primeiro elemento (`DeleteTaskUseCase` devolve raiz primeiro).
    return _repository.restoreSubtree(
      params.tasks,
      parentId: params.tasks.first.parentId,
    );
  }
}
