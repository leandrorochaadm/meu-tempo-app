import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/recurring_task_entity.dart';

/// Contrato de I/O dos modelos de tarefa recorrente (H15).
abstract class RecurringTaskRepository {
  /// Fluxo dos modelos do usuário logado, em ordem de título.
  Stream<Either<Failure, List<RecurringTaskEntity>>> watchAll();

  /// Leitura pontual dos modelos do usuário logado.
  Future<Either<Failure, List<RecurringTaskEntity>>> getAll();

  /// Cria um modelo e devolve com o `id` gerado (o `id` recebido é ignorado).
  Future<Either<Failure, RecurringTaskEntity>> create(
    RecurringTaskEntity template,
  );

  /// Grava os campos editáveis de um modelo existente (mesmo `id`) e o
  /// devolve. Não grava `lastGeneratedOn`: só [claimGeneration] mexe nele,
  /// para uma edição com valor antigo não apagar a marca de geração do dia.
  /// Modelo que não existe mais → `Left(NotFoundFailure())`.
  Future<Either<Failure, RecurringTaskEntity>> update(
    RecurringTaskEntity template,
  );

  /// Remove um modelo. As tarefas já geradas por ele não mudam (R6).
  Future<Either<Failure, Unit>> delete(String id);

  /// Recria um modelo excluído com o **mesmo `id`** (desfazer exclusão).
  Future<Either<Failure, Unit>> restore(RecurringTaskEntity template);

  /// Move para [toListId] todos os modelos da lista [fromListId].
  Future<Either<Failure, Unit>> moveToList(String fromListId, String toListId);

  /// Remove todos os modelos da lista [listId].
  Future<Either<Failure, Unit>> deleteByList(String listId);

  /// Marca, de forma atômica, que o modelo [id] gerou tarefa no dia [day]
  /// (grava `lastGeneratedOn`). Devolve `Right(true)` se marcou agora e
  /// `Right(false)` se o mesmo dia já estava marcado — evita gerar duas
  /// vezes com dois aparelhos abertos (R3).
  Future<Either<Failure, bool>> claimGeneration(String id, DateTime day);
}
