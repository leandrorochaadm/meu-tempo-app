part of 'update_display_name_bloc.dart';

sealed class UpdateDisplayNameEvent extends Equatable {
  const UpdateDisplayNameEvent();

  @override
  List<Object?> get props => const [];
}

/// The user tapped "Salvar" with the name as typed.
final class UpdateDisplayNameSubmitted extends UpdateDisplayNameEvent {
  const UpdateDisplayNameSubmitted(this.displayName);
  final String displayName;

  @override
  List<Object?> get props => [displayName];
}
