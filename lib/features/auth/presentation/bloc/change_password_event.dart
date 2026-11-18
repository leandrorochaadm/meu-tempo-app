part of 'change_password_bloc.dart';

sealed class ChangePasswordEvent extends Equatable {
  const ChangePasswordEvent();

  @override
  List<Object?> get props => const [];
}

final class ChangePasswordSubmitted extends ChangePasswordEvent {
  const ChangePasswordSubmitted({
    required this.currentPassword,
    required this.newPassword,
  });
  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}
