import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';
import '../validation/account_field_rules.dart';
import 'normalize_email.dart';

/// Creates an account and starts the session. The user arrives through the auth stream.
@lazySingleton
class SignUpUseCase implements UseCase<Unit, SignUpParams> {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SignUpParams params) async {
    // REQ-002, REQ-010, REQ-011
    final errors = [
      ...checkDisplayName(params.displayName),
      ...checkEmail(params.email),
    ];
    if (errors.isNotEmpty) return Left(InvalidAccountFieldsFailure(errors));
    // REQ-001, REQ-005
    return _repository.signUp(
      displayName: params.displayName.trim(),
      email: normalizeEmail(params.email),
      // REQ-003: the password is kept as typed; spaces may be part of it.
      password: params.password,
    );
  }
}

class SignUpParams extends Equatable {
  const SignUpParams({
    required this.displayName,
    required this.email,
    required this.password,
  });

  final String displayName;
  final String email;
  final String password;

  @override
  List<Object?> get props => [displayName, email, password];
}
