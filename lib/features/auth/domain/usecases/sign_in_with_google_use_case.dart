import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Dispara o login SSO Google.
@lazySingleton
class SignInWithGoogleUseCase implements UseCase<UserEntity, NoParams> {
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      _repository.signInWithGoogle();
}
