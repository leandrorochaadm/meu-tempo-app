import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_data_source.dart';
import '../models/appointment_model.dart';

@LazySingleton(as: AppointmentRepository)
class AppointmentRepositoryImpl implements AppointmentRepository {
  const AppointmentRepositoryImpl(this._dataSource);

  final AppointmentRemoteDataSource _dataSource;

  @override
  Stream<Either<Failure, List<AppointmentEntity>>> watchForDay(
    DateTime day,
  ) async* {
    try {
      yield* _dataSource.watchForDay(day).map<
          Either<Failure, List<AppointmentEntity>>>(
        (models) => Right(models.map((m) => m.toEntity()).toList()),
      );
    } on AppException catch (e, s) {
      AppLogger.logError('watchForDay falhou', error: e, stackTrace: s);
      yield Left(e.toFailure());
    } catch (e, s) {
      AppLogger.logError('watchForDay falhou', error: e, stackTrace: s);
      yield const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> create(
    AppointmentEntity a,
  ) async {
    try {
      final model = await _dataSource.create(AppointmentModel.fromEntity(a));
      return Right(model.toEntity());
    } on AppException catch (e, s) {
      AppLogger.logError('create appointment falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String appointmentId) async {
    try {
      await _dataSource.delete(appointmentId);
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('delete appointment falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> addSpentMinutes(
    String appointmentId,
    int minutes,
  ) async {
    try {
      await _dataSource.addSpentMinutes(appointmentId, minutes);
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('addSpentMinutes appointment falhou',
          error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }
}
