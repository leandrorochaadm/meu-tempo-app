import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/auth/domain/entities/change_password_form_entity.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/change_password_form_bloc.dart';

void main() {
  // REQ-012: initial state is the empty form
  test('should start with the empty form', () {
    expect(
      ChangePasswordFormBloc().state,
      const ChangePasswordFormEditing(ChangePasswordFormEntity()),
    );
  });

  // REQ-012: a field change emits the form with the two typed values
  blocTest<ChangePasswordFormBloc, ChangePasswordFormState>(
    'should emit editing form with typed values when a field changes',
    build: ChangePasswordFormBloc.new,
    act: (bloc) => bloc.add(
      const ChangePasswordFormChanged(
        currentPassword: 'abcd1234',
        newPassword: 'Wxyz5678',
      ),
    ),
    expect: () => [
      const ChangePasswordFormEditing(
        ChangePasswordFormEntity(
          currentPassword: 'abcd1234',
          newPassword: 'Wxyz5678',
        ),
      ),
    ],
  );
}
