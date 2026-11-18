import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/sign_up_use_case.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

/// Account creation request. Success emits nothing: the session starts, the
/// [AuthBloc] sees it and the router leaves the screen.
@injectable
class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc(this._signUp) : super(const SignUpIdle()) {
    on<SignUpSubmitted>(_onSubmitted);
  }

  static const Duration _signUpTimeout = Duration(seconds: 30);

  final SignUpUseCase _signUp;

  Future<void> _onSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    if (state is SignUpInProgress) return;
    emit(const SignUpInProgress());
    try {
      final result = await _signUp(
        SignUpParams(
          displayName: event.displayName,
          email: event.email,
          password: event.password,
        ),
      ).timeout(_signUpTimeout);
      result.match(
        (failure) => emit(SignUpFailed(_mapFailure(failure))),
        (_) {},
      );
    } on TimeoutException {
      emit(SignUpFailed(_mapFailure(const ServerFailure())));
    }
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem internet. Tente de novo.',
    _ => 'Não foi possível criar a conta. Tente de novo.',
  };
}
