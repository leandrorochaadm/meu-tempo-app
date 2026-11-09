import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/repositories/account_data_repository.dart';
import '../datasources/account_data_remote_data_source.dart';
import '../datasources/account_local_data_source.dart';

@LazySingleton(as: AccountDataRepository)
class AccountDataRepositoryImpl implements AccountDataRepository {
  const AccountDataRepositoryImpl(this._remote, this._local);

  final AccountDataRemoteDataSource _remote;
  final AccountLocalDataSource _local;

  @override
  Future<Either<Failure, Unit>> deleteBlockingRecords() async {
    try {
      await _remote.deleteBlockingRecords();
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError(
        'deleteBlockingRecords falhou',
        error: e,
        stackTrace: s,
      );
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> clearLocalData() async {
    try {
      await _local.clear();
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('clearLocalData falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }
}
