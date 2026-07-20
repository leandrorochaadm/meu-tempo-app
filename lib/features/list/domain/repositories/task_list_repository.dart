import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/task_list_entity.dart';

/// Contrato de I/O das listas (só operações primitivas — sem regra de negócio).
abstract class TaskListRepository {
  /// Fluxo das listas do usuário logado.
  Stream<Either<Failure, List<TaskListEntity>>> watchLists();

  /// Leitura pontual das listas do usuário logado.
  Future<Either<Failure, List<TaskListEntity>>> getLists();

  /// Cria uma lista e devolve com o `id` gerado.
  Future<Either<Failure, TaskListEntity>> create(TaskListEntity list);
}
