import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/account_field_error_enum.dart';
import '../../../../core/error/auth_failures.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/update_display_name_use_case.dart';

part 'update_display_name_event.dart';
part 'update_display_name_state.dart';

/// Saves the display name from the Profile section of Settings.
@injectable
class UpdateDisplayNameBloc
    extends Bloc<UpdateDisplayNameEvent, UpdateDisplayNameState> {
  UpdateDisplayNameBloc(this._updateDisplayName)
    : super(const UpdateDisplayNameIdle()) {
    on<UpdateDisplayNameSubmitted>(_onSubmitted);
  }

  final UpdateDisplayNameUseCase _updateDisplayName;

  Future<void> _onSubmitted(
    UpdateDisplayNameSubmitted event,
    Emitter<UpdateDisplayNameState> emit,
  ) async {
    if (state is UpdateDisplayNameInProgress) return;
    emit(const UpdateDisplayNameInProgress());
    final result = await _updateDisplayName(
      UpdateDisplayNameParams(displayName: event.displayName),
    );
    result.match(
      (failure) => switch (failure) {
        InvalidAccountFieldsFailure(:final errors) => emit(
          UpdateDisplayNameInvalid(errors),
        ),
        _ => emit(UpdateDisplayNameFailed(_mapFailure(failure))),
      },
      (_) => emit(const UpdateDisplayNameSaved()),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem internet. Tente de novo.',
    UnauthenticatedFailure() => 'Sua sessão terminou. Entre de novo.',
    _ => 'Não foi possível salvar. Tente de novo.',
  };
}
