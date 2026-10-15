import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/recurring_task_entity.dart';
import '../../domain/repositories/recurring_task_repository.dart';
import '../datasources/recurring_task_remote_data_source.dart';
import '../models/recurring_task_model.dart';

@LazySingleton(as: RecurringTaskRepository)
class RecurringTaskRepositoryImpl implements RecurringTaskRepository {
  const RecurringTaskRepositoryImpl(this._dataSource);

  final RecurringTaskRemoteDataSource _dataSource;

  @override
  Stream<Either<Failure, List<RecurringTaskEntity>>> watchAll() async* {
    try {
      // `await for` (e não `yield*`) para erros do stream caírem no `catch`.
      await for (final models in _dataSource.watchAll()) {
        yield Right(models.map((m) => m.toEntity()).toList());
      }
    } on AppException catch (e, s) {
      AppLogger.logError('watchAll recurring falhou', error: e, stackTrace: s);
      yield Left(e.toFailure());
    } catch (e, s) {
      AppLogger.logError('watchAll recurring falhou', error: e, stackTrace: s);
      yield const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<RecurringTaskEntity>>> getAll() async {
    try {
      final models = await _dataSource.getAll();
      return Right(models.map((m) => m.toEntity()).toList());
    } on AppException catch (e, s) {
      AppLogger.logError('getAll recurring falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    } catch (e, s) {
      AppLogger.logError('getAll recurring falhou', error: e, stackTrace: s);
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, RecurringTaskEntity>> create(
    RecurringTaskEntity template,
  ) async {
    try {
      final model = await _dataSource.create(
        RecurringTaskModel.fromEntity(template),
      );
      return Right(model.toEntity());
    } on AppException catch (e, s) {
      AppLogger.logError('create recurring falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, RecurringTaskEntity>> update(
    RecurringTaskEntity template,
  ) async {
    try {
      await _dataSource.update(RecurringTaskModel.fromEntity(template));
      return Right(template);
    } on AppException catch (e, s) {
      AppLogger.logError('update recurring falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    try {
      await _dataSource.delete(id);
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('delete recurring falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> restore(RecurringTaskEntity template) async {
    try {
      await _dataSource.restore(RecurringTaskModel.fromEntity(template));
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('restore recurring falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> moveToList(
    String fromListId,
    String toListId,
  ) async {
    try {
      await _dataSource.moveToList(fromListId, toListId);
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError(
        'moveToList recurring falhou',
        error: e,
        stackTrace: s,
      );
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteByList(String listId) async {
    try {
      await _dataSource.deleteByList(listId);
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError(
        'deleteByList recurring falhou',
        error: e,
        stackTrace: s,
      );
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> claimGeneration(String id, DateTime day) async {
    try {
      final claimed = await _dataSource.claimGeneration(
        id,
        day,
        // "Já gerou nesse dia?" é regra do domínio (R3): a entity decide.
        canClaim: (current) => !current.toEntity().wasGeneratedOn(day),
      );
      return Right(claimed);
    } on AppException catch (e, s) {
      AppLogger.logError(
        'claimGeneration recurring falhou',
        error: e,
        stackTrace: s,
      );
      return Left(e.toFailure());
    } catch (e, s) {
      AppLogger.logError(
        'claimGeneration recurring falhou',
        error: e,
        stackTrace: s,
      );
      return const Left(ServerFailure());
    }
  }
}
