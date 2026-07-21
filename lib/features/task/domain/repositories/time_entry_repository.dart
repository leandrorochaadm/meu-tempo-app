import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/time_entry_entity.dart';

/// Contrato dos registros de tempo datados (`users/{uid}/timeEntries`).
abstract class TimeEntryRepository {
  /// Persiste um novo registro de tempo. O `id` da entity é ignorado na escrita
  /// (o Firestore gera o doc.id).
  Future<Either<Failure, Unit>> add(TimeEntryEntity entry);

  /// Fluxo dos registros com `occurredAt` no intervalo `[start, end)`.
  Stream<Either<Failure, List<TimeEntryEntity>>> watchBetween(
    DateTime start,
    DateTime end,
  );

  /// Fluxo dos registros de uma folha/compromisso (`targetId`), mais recentes
  /// primeiro.
  Stream<Either<Failure, List<TimeEntryEntity>>> watchByTarget(String targetId);

  /// Substitui um registro existente (edição de minutos/data).
  Future<Either<Failure, Unit>> update(TimeEntryEntity entry);

  /// Remove um registro pelo `id`.
  Future<Either<Failure, Unit>> delete(String id);
}
