part of 'change_email_bloc.dart';

/// Field of the screen that shows a refusal message.
enum ChangeEmailFieldEnum { newEmail, currentPassword }

sealed class ChangeEmailState extends Equatable {
  const ChangeEmailState();

  @override
  List<Object?> get props => const [];
}

final class ChangeEmailIdle extends ChangeEmailState {
  const ChangeEmailIdle();
}

final class ChangeEmailInProgress extends ChangeEmailState {
  const ChangeEmailInProgress();
}

final class ChangeEmailInvalid extends ChangeEmailState {
  ChangeEmailInvalid(List<AccountFieldErrorEnum> errors)
    : errors = List.unmodifiable(errors);
  final List<AccountFieldErrorEnum> errors;

  @override
  List<Object?> get props => [errors];
}

/// Failure already translated to Portuguese by the Bloc. A null [field]
/// means a general message below the button.
final class ChangeEmailFailed extends ChangeEmailState {
  const ChangeEmailFailed(this.message, {this.field});
  final String message;
  final ChangeEmailFieldEnum? field;

  @override
  List<Object?> get props => [message, field];
}

final class ChangeEmailDone extends ChangeEmailState {
  const ChangeEmailDone();
}
