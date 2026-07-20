import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';

/// Contrato de I/O das tarefas (só operações primitivas).
abstract class TaskRepository {
  /// Fluxo das tarefas do usuário logado.
  Stream<Either<Failure, List<TaskEntity>>> watchTasks();

  /// Cria uma tarefa (o `id` é gerado pelo Firestore) e devolve com o `id`.
  Future<Either<Failure, TaskEntity>> create(TaskEntity task);
}
