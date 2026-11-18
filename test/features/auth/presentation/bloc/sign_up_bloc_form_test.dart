import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/auth/domain/entities/sign_up_form_entity.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignUpUseCase extends Mock implements SignUpUseCase {}

void main() {
  late _MockSignUpUseCase signUp;
  late Completer<Either<Failure, Unit>> completer;

  const typed = SignUpFormChanged(
    displayName: 'Ana',
    email: 'ana@exemplo.com',
    password: 'Abcd1234',
  );

  setUpAll(() {
    registerFallbackValue(
      const SignUpParams(displayName: '', email: '', password: ''),
    );
  });

  setUp(() {
    signUp = _MockSignUpUseCase();
    completer = Completer<Either<Failure, Unit>>();
  });

  // REQ-012: the bloc starts with an empty form (button disabled, nothing met)
  test('should start with an empty form', () {
    expect(SignUpBloc(signUp).state, const SignUpEditing(SignUpFormEntity()));
  });

  // REQ-012: typing name, e-mail and password emits the form with those values and policy not accepted
  blocTest<SignUpBloc, SignUpState>(
    'should emit SignUpEditing with typed values',
    build: () => SignUpBloc(signUp),
    act: (bloc) => bloc
      ..add(const SignUpStarted())
      ..add(typed),
    expect: () => [
      const SignUpEditing(
        SignUpFormEntity(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
      ),
    ],
  );

  // REQ-012: after accepting the policy, a new change rechecks the form with the policy accepted
  blocTest<SignUpBloc, SignUpState>(
    'should recheck with the accepted policy',
    build: () => SignUpBloc(signUp),
    act: (bloc) => bloc
      ..add(const SignUpStarted())
      ..add(typed)
      ..add(const SignUpPrivacyPolicyChanged(true))
      ..add(typed),
    expect: () => [
      const SignUpEditing(
        SignUpFormEntity(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
      ),
      const SignUpEditing(
        SignUpFormEntity(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
          acceptedPrivacyPolicy: true,
        ),
      ),
    ],
    verify: (bloc) {
      final state = bloc.state as SignUpEditing;
      expect(state.form.canSubmit, isTrue);
    },
  );

  // REQ-012: leaving the e-mail field after "ana@" marks it as left and warns invalidEmail
  blocTest<SignUpBloc, SignUpState>(
    'should mark email as left',
    build: () => SignUpBloc(signUp),
    act: (bloc) => bloc
      ..add(
        const SignUpFormChanged(displayName: '', email: 'ana@', password: ''),
      )
      ..add(const SignUpEmailLeft()),
    expect: () => [
      const SignUpEditing(SignUpFormEntity(email: 'ana@')),
      const SignUpEditing(SignUpFormEntity(email: 'ana@', emailLeft: true)),
    ],
    verify: (bloc) {
      final state = bloc.state as SignUpEditing;
      expect(state.form.emailWarning, AccountFieldErrorEnum.invalidEmail);
    },
  );

  // REQ-012: leaving the name field marks it as left
  blocTest<SignUpBloc, SignUpState>(
    'should mark name as left',
    build: () => SignUpBloc(signUp),
    act: (bloc) => bloc.add(const SignUpDisplayNameLeft()),
    expect: () => [
      const SignUpEditing(SignUpFormEntity(displayNameLeft: true)),
    ],
  );

  // REQ-012: form changes while the sign-up is in progress emit nothing; the submit goes on to the final state
  blocTest<SignUpBloc, SignUpState>(
    'should not emit form changes while in progress',
    build: () {
      when(() => signUp(any())).thenAnswer((_) => completer.future);
      return SignUpBloc(signUp);
    },
    act: (bloc) async {
      bloc.add(
        const SignUpSubmitted(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(typed)
        ..add(const SignUpDisplayNameLeft())
        ..add(const SignUpEmailLeft());
      await Future<void>.delayed(Duration.zero);
      completer.complete(const Left(ServerFailure()));
    },
    expect: () => [const SignUpInProgress(), isA<SignUpFailed>()],
  );
}
