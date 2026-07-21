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
}
