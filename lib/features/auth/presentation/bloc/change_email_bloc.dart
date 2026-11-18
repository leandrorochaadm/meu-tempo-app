import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/account_field_error_enum.dart';
import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/change_email_use_case.dart';

part 'change_email_event.dart';
part 'change_email_state.dart';

/// Changes the account e-mail from the Profile section of Settings.
@injectable
class ChangeEmailBloc extends Bloc<ChangeEmailEvent, ChangeEmailState> {
  ChangeEmailBloc(this._changeEmail) : super(const ChangeEmailIdle()) {
    on<ChangeEmailSubmitted>(_onSubmitted);
  }

  final ChangeEmailUseCase _changeEmail;

  // REQ-007
  Future<void> _onSubmitted(
    ChangeEmailSubmitted event,
    Emitter<ChangeEmailState> emit,
  ) async {
    if (state is ChangeEmailInProgress) return;
    emit(const ChangeEmailInProgress());
    final result = await _changeEmail(
      ChangeEmailParams(
        newEmail: event.newEmail,
        currentPassword: event.currentPassword,
      ),
    );
    result.match(
      (failure) => switch (failure) {
        InvalidAccountFieldsFailure(:final errors) => emit(
          ChangeEmailInvalid(errors),
        ),
        _ => emit(
          ChangeEmailFailed(_mapFailure(failure), field: _fieldOf(failure)),
        ),
      },
      (_) => emit(const ChangeEmailDone()),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    WrongCurrentPasswordFailure() => 'Senha atual incorreta.',
    EmailAlreadyInUseFailure() => 'Este e-mail já tem conta.',
    NetworkFailure() => 'Sem internet. Tente de novo.',
    UnauthenticatedFailure() => 'Sua sessão terminou. Entre de novo.',
    _ => 'Não foi possível salvar. Tente de novo.',
  };

  ChangeEmailFieldEnum? _fieldOf(Failure failure) => switch (failure) {
    WrongCurrentPasswordFailure() => ChangeEmailFieldEnum.currentPassword,
    EmailAlreadyInUseFailure() => ChangeEmailFieldEnum.newEmail,
    _ => null,
  };
}
