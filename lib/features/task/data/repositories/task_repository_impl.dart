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
  Stream<Either<Failure, List<TaskEntity>>> watchTasks({
    required bool includeDone,
  }) async* {
    try {
      yield* _dataSource
          .watchTasks(includeDone: includeDone)
          .map<Either<Failure, List<TaskEntity>>>(
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
  Future<Either<Failure, TaskEntity>> createChild(
    TaskEntity child, {
    required String parentId,
  }) async {
    try {
      final model = await _dataSource.createChild(
        TaskModel.fromEntity(child),
        parentId: parentId,
      );
      return Right(model.toEntity());
    } on AppException catch (e, s) {
      AppLogger.logError('createChild falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> moveTask(
    List<TaskEntity> subtree, {
    String? newParentId,
    String? emptiedParentId,
  }) async {
    try {
      await _dataSource.moveTask(
        subtree.map(TaskModel.fromEntity).toList(),
        newParentId: newParentId,
        emptiedParentId: emptiedParentId,
      );
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('moveTask falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updateAll(List<TaskEntity> tasks) async {
    try {
      await _dataSource.updateAll(tasks.map(TaskModel.fromEntity).toList());
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('updateAll falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteSubtree(
    List<String> taskIds, {
    String? emptiedParentId,
  }) async {
    try {
      await _dataSource.deleteSubtree(
        taskIds,
        emptiedParentId: emptiedParentId,
      );
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('deleteSubtree falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> restoreSubtree(
    List<TaskEntity> tasks, {
    String? parentId,
  }) async {
    try {
      await _dataSource.restoreSubtree(
        tasks.map(TaskModel.fromEntity).toList(),
        parentId: parentId,
      );
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('restoreSubtree falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> addSpentMinutes(
    String taskId,
    int delta,
  ) async {
    try {
      await _dataSource.addSpentMinutes(taskId, delta);
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('addSpentMinutes falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasks() async {
    try {
      final models = await _dataSource.getTasks();
      return Right(models.map((m) => m.toEntity()).toList());
    } on AppException catch (e, s) {
      AppLogger.logError('getTasks falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> setDone(String taskId, bool value) async {
    try {
      await _dataSource.setDone(taskId, value);
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('setDone falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> update(TaskEntity task) async {
    try {
      await _dataSource.update(TaskModel.fromEntity(task));
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('update task falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String taskId) async {
    try {
      await _dataSource.delete(taskId);
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('delete task falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }
}
