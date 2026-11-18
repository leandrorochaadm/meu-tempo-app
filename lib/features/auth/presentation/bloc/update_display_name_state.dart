part of 'update_display_name_bloc.dart';

sealed class UpdateDisplayNameState extends Equatable {
  const UpdateDisplayNameState();

  @override
  List<Object?> get props => const [];
}

final class UpdateDisplayNameIdle extends UpdateDisplayNameState {
  const UpdateDisplayNameIdle();
}

final class UpdateDisplayNameInProgress extends UpdateDisplayNameState {
  const UpdateDisplayNameInProgress();
}

final class UpdateDisplayNameInvalid extends UpdateDisplayNameState {
  UpdateDisplayNameInvalid(List<AccountFieldErrorEnum> errors)
    : errors = List.unmodifiable(errors);
  final List<AccountFieldErrorEnum> errors;

  @override
  List<Object?> get props => [errors];
}

/// Failure already translated to Portuguese by the Bloc.
final class UpdateDisplayNameFailed extends UpdateDisplayNameState {
  const UpdateDisplayNameFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class UpdateDisplayNameSaved extends UpdateDisplayNameState {
  const UpdateDisplayNameSaved();
}
