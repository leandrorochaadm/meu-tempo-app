part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Emitido internamente quando o stream de auth muda.
class AuthStateChanged extends AuthEvent {
  const AuthStateChanged(this.user);
  final UserEntity? user;

  @override
  List<Object?> get props => [user];
}

/// Usuário tocou em "Entrar com Google".
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Usuário pediu para sair.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
