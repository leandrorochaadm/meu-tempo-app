import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

@LazySingleton(as: TaskRepository)
class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._dataSource);

  final TaskRemoteDataSource _dataSource;

  @override
  Stream<Either<Failure, List<TaskEntity>>> watchTasks() async* {
    try {
      yield* _dataSource.watchTasks().map<Either<Failure, List<TaskEntity>>>(
            (models) => Right(models.map((m) => m.toEntity()).toList()),
          );
    } on AppException catch (e, s) {
      AppLogger.logError('watchTasks falhou', error: e, stackTrace: s);
      yield Left(e.toFailure());
    } catch (e, s) {
      AppLogger.logError('watchTasks falhou', error: e, stackTrace: s);
      yield const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> create(TaskEntity task) async {
    try {
      final model = await _dataSource.create(TaskModel.fromEntity(task));
      return Right(model.toEntity());
    } on AppException catch (e, s) {
      AppLogger.logError('create task falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> setHasChildren(
    String taskId,
    bool value,
  ) async {
    try {
      await _dataSource.setHasChildren(taskId, value);
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('setHasChildren falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }
}
