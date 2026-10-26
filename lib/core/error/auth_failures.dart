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
