import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_in_with_google_use_case.dart';
import '../../domain/usecases/sign_out_use_case.dart';
import '../../domain/usecases/watch_auth_state_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Orquestra a autenticação. Só traduz `Failure` → estado; nenhuma regra de negócio.
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._signInWithGoogle,
    this._signOut,
    this._watchAuthState,
  ) : super(const AuthInitial()) {
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthGoogleSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);

    _authSub = _watchAuthState(const NoParams())
        .listen((user) => add(AuthStateChanged(user)));
  }

  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;
  final WatchAuthStateUseCase _watchAuthState;

  late final StreamSubscription<UserEntity?> _authSub;

  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) {
    emit(event.user == null
        ? const AuthUnauthenticated()
        : AuthAuthenticated(event.user!));
  }

  /// Rede de segurança: se o login não iniciar/resolver nesse tempo, sai do
  /// estado de carregamento com erro em vez de ficar girando para sempre.
  static const _signInTimeout = Duration(seconds: 30);

  Future<void> _onSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result =
          await _signInWithGoogle(const NoParams()).timeout(_signInTimeout);
      // Sucesso emite via stream (AuthStateChanged); aqui só tratamos erro.
      result.match(
        (failure) => emit(AuthError(_mapFailure(failure))),
        (_) {},
      );
    } on TimeoutException {
      emit(AuthError(_mapFailure(const AuthFailure())));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _signOut(const NoParams());
    result.match(
      (failure) => emit(AuthError(_mapFailure(failure))),
      (_) {},
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
        SignInCancelledFailure() => 'Login cancelado.',
        NetworkFailure() => 'Sem conexão. Verifique a internet.',
        _ => 'Não foi possível entrar. Tente novamente.',
      };

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
