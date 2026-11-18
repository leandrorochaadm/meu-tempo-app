part of 'change_password_bloc.dart';

/// Field of the screen that shows a refusal message.
enum ChangePasswordFieldEnum { currentPassword }

sealed class ChangePasswordState extends Equatable {
  const ChangePasswordState();

  @override
  List<Object?> get props => const [];
}

final class ChangePasswordIdle extends ChangePasswordState {
  const ChangePasswordIdle();
}

final class ChangePasswordInProgress extends ChangePasswordState {
  const ChangePasswordInProgress();
}

final class ChangePasswordInvalid extends ChangePasswordState {
  ChangePasswordInvalid(List<AccountFieldErrorEnum> errors)
    : errors = List.unmodifiable(errors);
  final List<AccountFieldErrorEnum> errors;

  @override
  List<Object?> get props => [errors];
}

/// Failure already translated to Portuguese by the Bloc. A null [field]
/// means a general message below the button.
final class ChangePasswordFailed extends ChangePasswordState {
  const ChangePasswordFailed(this.message, {this.field});
  final String message;
  final ChangePasswordFieldEnum? field;

  @override
  List<Object?> get props => [message, field];
}

final class ChangePasswordDone extends ChangePasswordState {
  const ChangePasswordDone();
}
