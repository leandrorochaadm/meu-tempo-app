import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/change_password_form_entity.dart';

part 'change_password_form_event.dart';
part 'change_password_form_state.dart';

/// Holds the change-password form snapshot; every decision comes from the entity.
@injectable
class ChangePasswordFormBloc
    extends Bloc<ChangePasswordFormEvent, ChangePasswordFormState> {
  ChangePasswordFormBloc()
    : super(const ChangePasswordFormEditing(ChangePasswordFormEntity())) {
    on<ChangePasswordFormChanged>((event, emit) {
      emit(
        ChangePasswordFormEditing(
          ChangePasswordFormEntity(
            currentPassword: event.currentPassword,
            newPassword: event.newPassword,
          ),
        ),
      );
    });
  }
}
