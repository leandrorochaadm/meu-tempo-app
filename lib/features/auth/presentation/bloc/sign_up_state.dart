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
