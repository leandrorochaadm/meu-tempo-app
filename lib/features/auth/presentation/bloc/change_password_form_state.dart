part of 'change_password_form_bloc.dart';

sealed class ChangePasswordFormState extends Equatable {
  const ChangePasswordFormState();

  @override
  List<Object?> get props => const [];
}

final class ChangePasswordFormEditing extends ChangePasswordFormState {
  const ChangePasswordFormEditing(this.form);

  final ChangePasswordFormEntity form;

  @override
  List<Object?> get props => [form];
}
