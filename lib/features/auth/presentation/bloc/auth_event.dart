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

/// Usuário tocou em "Entrar".
class AuthEmailSignInRequested extends AuthEvent {
  const AuthEmailSignInRequested({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Usuário pediu para sair.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
