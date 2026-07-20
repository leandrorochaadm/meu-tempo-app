import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/time_entry_entity.dart';
import '../repositories/time_entry_repository.dart';

class WatchTimeEntriesParams extends Equatable {
  const WatchTimeEntriesParams({required this.start, required this.end});
  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}

/// Fluxo dos registros de tempo no intervalo `[start, end)`.
@lazySingleton
class WatchTimeEntriesUseCase
    implements
        StreamUseCase<Either<Failure, List<TimeEntryEntity>>,
            WatchTimeEntriesParams> {
  const WatchTimeEntriesUseCase(this._repository);

  final TimeEntryRepository _repository;

  @override
  Stream<Either<Failure, List<TimeEntryEntity>>> call(
    WatchTimeEntriesParams params,
  ) =>
      _repository.watchBetween(params.start, params.end);
}
