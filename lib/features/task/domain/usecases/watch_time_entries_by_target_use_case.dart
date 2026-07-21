import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/time_entry_entity.dart';
import '../repositories/time_entry_repository.dart';

class WatchTimeEntriesByTargetParams extends Equatable {
  const WatchTimeEntriesByTargetParams({required this.targetId});
  final String targetId;

  @override
  List<Object?> get props => [targetId];
}

/// Fluxo dos registros de tempo de uma folha (`targetId`), mais recentes
/// primeiro — base do CRUD de tempo gasto.
@lazySingleton
class WatchTimeEntriesByTargetUseCase
    implements
        StreamUseCase<Either<Failure, List<TimeEntryEntity>>,
            WatchTimeEntriesByTargetParams> {
  const WatchTimeEntriesByTargetUseCase(this._repository);

  final TimeEntryRepository _repository;

  @override
  Stream<Either<Failure, List<TimeEntryEntity>>> call(
    WatchTimeEntriesByTargetParams params,
  ) =>
      _repository.watchByTarget(params.targetId);
}
