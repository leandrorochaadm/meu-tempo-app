import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final model = await _dataSource.signInWithGoogle();
      return Right(model.toEntity());
    } on AppException catch (e, s) {
      AppLogger.logError('signInWithGoogle falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(unit);
    } on AppException catch (e, s) {
      AppLogger.logError('signOut falhou', error: e, stackTrace: s);
      return Left(e.toFailure());
    }
  }

  @override
  Stream<UserEntity?> authState() =>
      _dataSource.authState().map((model) => model?.toEntity());

  @override
  UserEntity? currentUser() => _dataSource.currentUser()?.toEntity();
}
