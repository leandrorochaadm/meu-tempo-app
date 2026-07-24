import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/active_timer_entity.dart';
import '../../domain/repositories/timer_repository.dart';
import '../datasources/timer_remote_data_source.dart';
import '../models/active_timer_model.dart';

@LazySingleton(as: TimerRepository)
class TimerRepositoryImpl implements TimerRepository {
  const TimerRepositoryImpl(this._dataSource);

  final TimerRemoteDataSource _dataSource;

  @override
  Stream<Either<Failure, ActiveTimerEntity?>> watchActive() async* {
    try {
      yield* _dataSource.watchActive().map<Either<Failure, ActiveTimerEntity?>>(
            (model) => Right(model?.toEntity()),
          );
    } on AppException catch (e, s) {
      AppLogger.logError('watchActive falhou', error: e, stackTrace: s);
      yield Left(e.toFailure());
    } catch (e, s) {
      AppLogger.logError('watchActive falhou', error: e, stackTrace: s);
      yield const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, ActiveTimerEntity?>> getActive() async {
    try {
      final model = await _dataSource.getActive();
      return Right(model?.toEntity());
    } on AppException catch (e, s) {
      AppLogger.logError('getActive falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> setActive(ActiveTimerEntity timer) async {
    try {
      await _dataSource.setActive(ActiveTimerModel.fromEntity(timer));
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('setActive falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, ActiveTimerEntity?>> claimActive() async {
    try {
      final model = await _dataSource.claimActive();
      return Right(model?.toEntity());
    } on AppException catch (e, s) {
      AppLogger.logError('claimActive falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> clear() async {
    try {
      await _dataSource.clear();
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('clear timer falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }
}
