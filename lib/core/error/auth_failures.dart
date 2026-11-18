import 'account_field_error_enum.dart';
import 'failures.dart';

/// Usuário não autenticado (sem sessão válida).
class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure();
}

/// Wrong e-mail or password (or unknown account).
class AuthFailure extends Failure {
  const AuthFailure();
}

/// E-mail or password left blank on sign-in.
class EmptyCredentialsFailure extends Failure {
  const EmptyCredentialsFailure();
}

/// The e-mail already has an account. // REQ-005
class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure();
}

/// The server refused the current password. // REQ-007, REQ-008
class WrongCurrentPasswordFailure extends Failure {
  const WrongCurrentPasswordFailure();
}

/// One or more account fields were refused; carries every reason at once.
class InvalidAccountFieldsFailure extends Failure {
  InvalidAccountFieldsFailure(List<AccountFieldErrorEnum> errors)
    : errors = List.unmodifiable(errors);

  final List<AccountFieldErrorEnum> errors;

  @override
  List<Object?> get props => [errors];
}
