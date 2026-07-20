import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';

/// Contrato de I/O das tarefas (só operações primitivas).
abstract class TaskRepository {
  /// Fluxo das tarefas do usuário logado.
  Stream<Either<Failure, List<TaskEntity>>> watchTasks();

  /// Cria uma tarefa (o `id` é gerado pelo Firestore) e devolve com o `id`.
  Future<Either<Failure, TaskEntity>> create(TaskEntity task);

  /// Atualiza o flag `hasChildren` de uma tarefa (mantido pela camada data
  /// ao criar/remover filhas — base do getter `isLeaf`).
  Future<Either<Failure, Unit>> setHasChildren(String taskId, bool value);
}
