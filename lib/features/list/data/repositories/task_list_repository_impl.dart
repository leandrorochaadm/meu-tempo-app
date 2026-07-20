import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/task_list_entity.dart';
import '../../domain/repositories/task_list_repository.dart';
import '../datasources/task_list_remote_data_source.dart';
import '../models/task_list_model.dart';

@LazySingleton(as: TaskListRepository)
class TaskListRepositoryImpl implements TaskListRepository {
  const TaskListRepositoryImpl(this._dataSource);

  final TaskListRemoteDataSource _dataSource;

  @override
  Stream<Either<Failure, List<TaskListEntity>>> watchLists() async* {
    try {
      yield* _dataSource.watchLists().map<Either<Failure, List<TaskListEntity>>>(
            (models) => Right(models.map((m) => m.toEntity()).toList()),
          );
    } on AppException catch (e, s) {
      AppLogger.logError('watchLists falhou', error: e, stackTrace: s);
      yield Left(e.toFailure());
    } catch (e, s) {
      AppLogger.logError('watchLists falhou', error: e, stackTrace: s);
      yield const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<TaskListEntity>>> getLists() async {
    try {
      final models = await _dataSource.getLists();
      return Right(models.map((m) => m.toEntity()).toList());
    } on AppException catch (e, s) {
      AppLogger.logError('getLists falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, TaskListEntity>> create(TaskListEntity list) async {
    try {
      final model = await _dataSource.create(TaskListModel.fromEntity(list));
      return Right(model.toEntity());
    } on AppException catch (e, s) {
      AppLogger.logError('create list falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }
}
