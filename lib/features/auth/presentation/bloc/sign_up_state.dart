part of 'sign_up_bloc.dart';

sealed class SignUpState extends Equatable {
  const SignUpState();

  @override
  List<Object?> get props => const [];
}

final class SignUpIdle extends SignUpState {
  const SignUpIdle();
}

final class SignUpInProgress extends SignUpState {
  const SignUpInProgress();
}

final class SignUpFailed extends SignUpState {
  const SignUpFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class SignUpEmailInUse extends SignUpState {
  const SignUpEmailInUse(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class SignUpFieldsInvalid extends SignUpState {
  SignUpFieldsInvalid(List<AccountFieldErrorEnum> errors)
    : errors = List.unmodifiable(errors);

  final List<AccountFieldErrorEnum> errors;

  @override
  List<Object?> get props => [errors];
}

/// The form being edited, with the entity ready for the screen (REQ-012).
final class SignUpEditing extends SignUpState {
  const SignUpEditing(this.form);

  final SignUpFormEntity form;

  @override
  List<Object?> get props => [form];
}
