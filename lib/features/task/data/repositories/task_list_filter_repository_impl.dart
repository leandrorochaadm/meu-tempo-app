import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/repositories/task_list_filter_repository.dart';
import '../datasources/task_list_filter_local_data_source.dart';

@LazySingleton(as: TaskListFilterRepository)
class TaskListFilterRepositoryImpl implements TaskListFilterRepository {
  const TaskListFilterRepositoryImpl(this._dataSource);

  final TaskListFilterLocalDataSource _dataSource;

  @override
  Future<Either<Failure, String?>> getSelectedListId() async {
    try {
      return Right(_dataSource.getSelectedListId());
    } catch (e, s) {
      // Falha nunca chega ao usuário: o Bloc cai em "Todas as listas".
      AppLogger.logError('getSelectedListId falhou', error: e, stackTrace: s);
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> setSelectedListId(String? listId) async {
    try {
      await _dataSource.setSelectedListId(listId);
      return const Right(unit);
    } catch (e, s) {
      AppLogger.logError('setSelectedListId falhou', error: e, stackTrace: s);
      return const Left(ServerFailure());
    }
  }
}
