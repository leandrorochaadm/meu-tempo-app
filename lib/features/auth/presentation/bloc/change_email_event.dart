part of 'change_email_bloc.dart';

sealed class ChangeEmailEvent extends Equatable {
  const ChangeEmailEvent();

  @override
  List<Object?> get props => const [];
}

final class ChangeEmailSubmitted extends ChangeEmailEvent {
  const ChangeEmailSubmitted({
    required this.newEmail,
    required this.currentPassword,
  });
  final String newEmail;
  final String currentPassword;

  @override
  List<Object?> get props => [newEmail, currentPassword];
}
