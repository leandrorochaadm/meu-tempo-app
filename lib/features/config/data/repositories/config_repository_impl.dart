import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/day_config_entity.dart';
import '../../domain/repositories/config_repository.dart';
import '../datasources/config_remote_data_source.dart';

@LazySingleton(as: ConfigRepository)
class ConfigRepositoryImpl implements ConfigRepository {
  const ConfigRepositoryImpl(this._dataSource);

  final ConfigRemoteDataSource _dataSource;

  @override
  Stream<Either<Failure, DayConfigEntity>> watchConfig() async* {
    try {
      yield* _dataSource.watchConfig().map<Either<Failure, DayConfigEntity>>(
            (model) => Right(model.toEntity()),
          );
    } on AppException catch (e, s) {
      AppLogger.logError('watchConfig falhou', error: e, stackTrace: s);
      yield Left(e.toFailure());
    } catch (e, s) {
      AppLogger.logError('watchConfig falhou', error: e, stackTrace: s);
      yield const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> setAvailableMinutes(int minutes) async {
    try {
      await _dataSource.setAvailableMinutes(minutes);
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('setAvailableMinutes falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }
}
