import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/account_field_error_enum.dart';
import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/change_password_use_case.dart';

part 'change_password_event.dart';
part 'change_password_state.dart';

/// Changes the account password from the Profile section of Settings.
@injectable
class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  ChangePasswordBloc(this._changePassword) : super(const ChangePasswordIdle()) {
    on<ChangePasswordSubmitted>(_onSubmitted);
  }

  final ChangePasswordUseCase _changePassword;

  // REQ-008
  Future<void> _onSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    if (state is ChangePasswordInProgress) return;
    emit(const ChangePasswordInProgress());
    final result = await _changePassword(
      ChangePasswordParams(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      ),
    );
    result.match(
      (failure) => switch (failure) {
        InvalidAccountFieldsFailure(:final errors) => emit(
          ChangePasswordInvalid(errors),
        ),
        _ => emit(
          ChangePasswordFailed(_mapFailure(failure), field: _fieldOf(failure)),
        ),
      },
      (_) => emit(const ChangePasswordDone()),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    WrongCurrentPasswordFailure() => 'Senha atual incorreta.',
    NetworkFailure() => 'Sem internet. Tente de novo.',
    UnauthenticatedFailure() => 'Sua sessão terminou. Entre de novo.',
    _ => 'Não foi possível salvar. Tente de novo.',
  };

  ChangePasswordFieldEnum? _fieldOf(Failure failure) => switch (failure) {
    WrongCurrentPasswordFailure() => ChangePasswordFieldEnum.currentPassword,
    _ => null,
  };
}
