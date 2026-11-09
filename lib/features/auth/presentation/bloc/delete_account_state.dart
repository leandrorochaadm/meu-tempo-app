part of 'delete_account_bloc.dart';

sealed class DeleteAccountState extends Equatable {
  const DeleteAccountState();

  @override
  List<Object?> get props => const [];
}

final class DeleteAccountIdle extends DeleteAccountState {
  const DeleteAccountIdle();
}

final class DeleteAccountInProgress extends DeleteAccountState {
  const DeleteAccountInProgress();
}

/// Failure already translated to Portuguese by the Bloc.
final class DeleteAccountFailed extends DeleteAccountState {
  const DeleteAccountFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
