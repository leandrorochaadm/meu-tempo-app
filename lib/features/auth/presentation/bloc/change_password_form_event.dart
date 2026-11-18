part of 'change_password_form_bloc.dart';

sealed class ChangePasswordFormEvent extends Equatable {
  const ChangePasswordFormEvent();

  @override
  List<Object?> get props => const [];
}

/// One of the two fields changed.
final class ChangePasswordFormChanged extends ChangePasswordFormEvent {
  const ChangePasswordFormChanged({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}
