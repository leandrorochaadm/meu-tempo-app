import 'failures.dart';

/// Usuário não autenticado (sem sessão válida).
class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure();
}

/// Falha genérica no fluxo de autenticação.
class AuthFailure extends Failure {
  const AuthFailure();
}

/// O usuário fechou/cancelou o popup do Google.
class SignInCancelledFailure extends Failure {
  const SignInCancelledFailure();
}
