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

  /// Cria uma subtarefa marcando o pai como não-folha **atomicamente**: ou as
  /// duas escritas acontecem, ou nenhuma. Evita o pai ficar com `hasChildren`
  /// desatualizado se a segunda escrita falhar.
  Future<Either<Failure, TaskEntity>> createChild(
    TaskEntity child, {
    required String parentId,
  });

  /// Move a **subárvore** (a tarefa e seus descendentes) e ajusta o
  /// `hasChildren` dos pais envolvidos **atomicamente**.
  /// [newParentId] passa a ter filhas; [emptiedParentId] é o pai antigo que
  /// ficou sem nenhuma (`null` quando não se aplica).
  Future<Either<Failure, Unit>> moveTask(
    List<TaskEntity> subtree, {
    String? newParentId,
    String? emptiedParentId,
  });

  /// Exclui a subárvore (ela e todas as descendentes) e marca
  /// [emptiedParentId] como folha **atomicamente**.
  Future<Either<Failure, Unit>> deleteSubtree(
    List<String> taskIds, {
    String? emptiedParentId,
  });

  /// Recria a subárvore com os ids originais e remarca [parentId] como
  /// não-folha **atomicamente** — desfazer da exclusão em cascata.
  Future<Either<Failure, Unit>> restoreSubtree(
    List<TaskEntity> tasks, {
    String? parentId,
  });

  /// Acrescenta (delta) minutos de tempo real a uma folha.
  Future<Either<Failure, Unit>> addSpentMinutes(String taskId, int delta);

  /// Leitura pontual de todas as tarefas do usuário.
  Future<Either<Failure, List<TaskEntity>>> getTasks();

  /// Marca/desmarca uma tarefa como concluída.
  Future<Either<Failure, Unit>> setDone(String taskId, bool value);

  /// Substitui o documento da tarefa (edição/mover).
  Future<Either<Failure, Unit>> update(TaskEntity task);

  /// Remove **uma** tarefa isolada, sem tocar na hierarquia.
  ///
  /// Para excluir tarefa com filhas use [deleteSubtree] — ele faz a cascata e
  /// libera o pai no mesmo commit. Usar `delete` num nó da hierarquia deixaria
  /// descendentes órfãs e o `hasChildren` do pai desatualizado.
  Future<Either<Failure, Unit>> delete(String taskId);
}
