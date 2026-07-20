import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/time_entry_entity.dart';
import '../../domain/repositories/time_entry_repository.dart';
import '../datasources/time_entry_remote_data_source.dart';
import '../models/time_entry_model.dart';

@LazySingleton(as: TimeEntryRepository)
class TimeEntryRepositoryImpl implements TimeEntryRepository {
  const TimeEntryRepositoryImpl(this._dataSource);

  final TimeEntryRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, Unit>> add(TimeEntryEntity entry) async {
    try {
      await _dataSource.add(TimeEntryModel.fromEntity(entry));
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('add timeEntry falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Stream<Either<Failure, List<TimeEntryEntity>>> watchBetween(
    DateTime start,
    DateTime end,
  ) async* {
    try {
      yield* _dataSource.watchBetween(start, end).map<
          Either<Failure, List<TimeEntryEntity>>>(
        (models) => Right(models.map((m) => m.toEntity()).toList()),
      );
    } on AppException catch (e, s) {
      AppLogger.logError('watchBetween falhou', error: e, stackTrace: s);
      yield Left(e.toFailure());
    } catch (e, s) {
      AppLogger.logError('watchBetween falhou', error: e, stackTrace: s);
      yield const Left(ServerFailure());
    }
  }
}
