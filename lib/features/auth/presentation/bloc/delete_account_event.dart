part of 'delete_account_bloc.dart';

sealed class DeleteAccountEvent extends Equatable {
  const DeleteAccountEvent();

  @override
  List<Object?> get props => const [];
}

/// The user confirmed "Excluir" in the dialog.
final class DeleteAccountRequested extends DeleteAccountEvent {
  const DeleteAccountRequested();
}
