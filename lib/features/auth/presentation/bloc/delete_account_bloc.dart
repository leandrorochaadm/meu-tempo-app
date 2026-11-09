import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/delete_account_use_case.dart';

part 'delete_account_event.dart';
part 'delete_account_state.dart';

/// Account deletion request. Kept apart from [AuthBloc] so a failure here does
/// not show sign-in messages. Success emits nothing: the session ends and the
/// router leaves the screen.
@injectable
class DeleteAccountBloc extends Bloc<DeleteAccountEvent, DeleteAccountState> {
  DeleteAccountBloc(this._deleteAccount) : super(const DeleteAccountIdle()) {
    on<DeleteAccountRequested>(_onRequested);
  }

  final DeleteAccountUseCase _deleteAccount;

  Future<void> _onRequested(
    DeleteAccountRequested event,
    Emitter<DeleteAccountState> emit,
  ) async {
    if (state is DeleteAccountInProgress) return;
    emit(const DeleteAccountInProgress());
    final result = await _deleteAccount(const NoParams());
    result.match(
      (failure) => emit(DeleteAccountFailed(_mapFailure(failure))),
      (_) {},
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão. Verifique a internet.',
    UnauthenticatedFailure() => 'Sua sessão terminou. Entre de novo.',
    _ => 'Não foi possível excluir a conta. Tente de novo.',
  };
}
