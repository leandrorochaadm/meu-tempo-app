import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';

/// Contrato de I/O das tarefas (só operações primitivas).
abstract class TaskRepository {
  /// Fluxo das tarefas do usuário logado. `includeDone == false` traz apenas as
  /// pendentes (filtro aplicado no backend), reduzindo leitura no caso comum.
  Stream<Either<Failure, List<TaskEntity>>> watchTasks({
    required bool includeDone,
  });

  /// Cria uma tarefa (o `id` é gerado pelo Firestore) e devolve com o `id`.
  Future<Either<Failure, TaskEntity>> create(TaskEntity task);

  /// Atualiza o flag `hasChildren` de uma tarefa (mantido pela camada data
  /// ao criar/remover filhas — base do getter `isLeaf`).
  Future<Either<Failure, Unit>> setHasChildren(String taskId, bool value);

  /// Acrescenta (delta) minutos de tempo real a uma folha.
  Future<Either<Failure, Unit>> addSpentMinutes(String taskId, int delta);

  /// Leitura pontual de todas as tarefas do usuário.
  Future<Either<Failure, List<TaskEntity>>> getTasks();

  /// Marca/desmarca uma tarefa como concluída.
  Future<Either<Failure, Unit>> setDone(String taskId, bool value);

  /// Substitui o documento da tarefa (edição/mover).
  Future<Either<Failure, Unit>> update(TaskEntity task);

  /// Remove uma tarefa (o chamador cuida da cascata).
  Future<Either<Failure, Unit>> delete(String taskId);
}
