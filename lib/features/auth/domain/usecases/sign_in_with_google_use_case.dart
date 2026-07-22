import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Dispara o login SSO Google (redirect). O usuário chega pelo stream de auth.
@lazySingleton
class SignInWithGoogleUseCase implements UseCase<Unit, NoParams> {
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.signInWithGoogle();
}
