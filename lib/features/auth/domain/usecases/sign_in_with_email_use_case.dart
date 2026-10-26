import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Signs in with e-mail and password. Blank fields never reach the server.
/// The user arrives through the auth stream.
@lazySingleton
class SignInWithEmailUseCase implements UseCase<Unit, SignInWithEmailParams> {
  const SignInWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SignInWithEmailParams params) async {
    final email = params.email.trim();
    // The password is kept as typed: spaces may be part of it.
    if (email.isEmpty || params.password.isEmpty) {
      return const Left(EmptyCredentialsFailure());
    }
    return _repository.signInWithEmail(email, params.password);
  }
}

class SignInWithEmailParams extends Equatable {
  const SignInWithEmailParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
