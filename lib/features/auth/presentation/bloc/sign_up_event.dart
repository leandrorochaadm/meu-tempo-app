part of 'sign_up_bloc.dart';

sealed class SignUpEvent extends Equatable {
  const SignUpEvent();

  @override
  List<Object?> get props => const [];
}

/// The person asked to create the account with the typed values.
final class SignUpSubmitted extends SignUpEvent {
  const SignUpSubmitted({
    required this.displayName,
    required this.email,
    required this.password,
  });

  final String displayName;
  final String email;
  final String password;

  @override
  List<Object?> get props => [displayName, email, password];
}

/// The sign-up screen opened: the privacy policy box starts unchecked (REQ-004).
final class SignUpStarted extends SignUpEvent {
  const SignUpStarted();
}

/// The person checked or unchecked the privacy policy box.
final class SignUpPrivacyPolicyChanged extends SignUpEvent {
  const SignUpPrivacyPolicyChanged(this.accepted);

  final bool accepted;

  @override
  List<Object?> get props => [accepted];
}

/// Any text field changed: the form snapshot is rebuilt (REQ-012).
final class SignUpFormChanged extends SignUpEvent {
  const SignUpFormChanged({
    required this.displayName,
    required this.email,
    required this.password,
  });

  final String displayName;
  final String email;
  final String password;

  @override
  List<Object?> get props => [displayName, email, password];
}

/// The person left the name field.
final class SignUpDisplayNameLeft extends SignUpEvent {
  const SignUpDisplayNameLeft();
}

/// The person left the e-mail field.
final class SignUpEmailLeft extends SignUpEvent {
  const SignUpEmailLeft();
}
