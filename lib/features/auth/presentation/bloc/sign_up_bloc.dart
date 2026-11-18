import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/account_field_error_enum.dart';
import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/sign_up_use_case.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

/// Account creation request. Success emits nothing: the session starts, the
/// [AuthBloc] sees it and the router leaves the screen.
@injectable
class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc(this._signUp) : super(const SignUpIdle()) {
    on<SignUpStarted>((_, _) => _acceptedPrivacyPolicy = false);
    on<SignUpPrivacyPolicyChanged>(
      (event, _) => _acceptedPrivacyPolicy = event.accepted,
    );
    on<SignUpSubmitted>(_onSubmitted);
  }

  static const Duration _signUpTimeout = Duration(seconds: 30);

  final SignUpUseCase _signUp;
  // Starts true only for callers that never send SignUpStarted; the router always does.
  bool _acceptedPrivacyPolicy = true;

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
          acceptedPrivacyPolicy: _acceptedPrivacyPolicy,
        ),
      ).timeout(_signUpTimeout);
      result.match(
        (failure) => switch (failure) {
          InvalidAccountFieldsFailure(:final errors) => emit(
            SignUpFieldsInvalid(errors),
          ),
          EmailAlreadyInUseFailure() => emit(
            SignUpEmailInUse(_mapFailure(failure)),
          ),
          _ => emit(SignUpFailed(_mapFailure(failure))),
        },
        (_) {},
      );
    } on TimeoutException {
      emit(SignUpFailed(_mapFailure(const ServerFailure())));
    }
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem internet. Tente de novo.',
    EmailAlreadyInUseFailure() => 'Este e-mail já tem conta. Entre com ele.',
    _ => 'Não foi possível criar a conta. Tente de novo.',
  };
}
