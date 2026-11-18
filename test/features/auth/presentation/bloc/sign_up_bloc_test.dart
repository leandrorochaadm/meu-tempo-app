import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignUpUseCase extends Mock implements SignUpUseCase {}

void main() {
  late _MockSignUpUseCase signUp;

  const submitted = SignUpSubmitted(
    displayName: 'Ana',
    email: 'ana@exemplo.com',
    password: 'Abcd1234',
  );
  const params = SignUpParams(
    displayName: 'Ana',
    email: 'ana@exemplo.com',
    password: 'Abcd1234',
  );

  setUpAll(() {
    registerFallbackValue(
      const SignUpParams(displayName: '', email: '', password: ''),
    );
  });

  setUp(() => signUp = _MockSignUpUseCase());

  // REQ-001: Name "Ana", email "ana@exemplo.com", password "Abcd1234": the use case is called once and success emits no state after in-progress
  blocTest<SignUpBloc, SignUpState>(
    'should emit [SignUpInProgress] and call the use case once when sign-up succeeds',
    build: () {
      when(() => signUp(any())).thenAnswer((_) async => const Right(unit));
      return SignUpBloc(signUp);
    },
    act: (bloc) => bloc.add(submitted),
    expect: () => [const SignUpInProgress()],
    verify: (_) => verify(() => signUp(params)).called(1),
  );

  // REQ-001: typed values with spaces are passed to the use case unchanged (trimming and normalizing belong to the use case)
  blocTest<SignUpBloc, SignUpState>(
    'should pass typed values unchanged to the use case',
    build: () {
      when(() => signUp(any())).thenAnswer((_) async => const Right(unit));
      return SignUpBloc(signUp);
    },
    act: (bloc) => bloc.add(
      const SignUpSubmitted(
        displayName: '  Ana  ',
        email: ' Ana@Exemplo.com ',
        password: 'Abcd1234',
      ),
    ),
    verify: (_) => verify(
      () => signUp(
        const SignUpParams(
          displayName: '  Ana  ',
          email: ' Ana@Exemplo.com ',
          password: 'Abcd1234',
        ),
      ),
    ).called(1),
  );

  // REQ-001: a second submit while sign-up is in progress is ignored
  blocTest<SignUpBloc, SignUpState>(
    'should ignore a second submit while in progress',
    build: () {
      when(
        () => signUp(any()),
      ).thenAnswer((_) => Completer<Either<Failure, Unit>>().future);
      return SignUpBloc(signUp);
    },
    act: (bloc) async {
      bloc.add(submitted);
      await Future<void>.delayed(Duration.zero);
      bloc.add(submitted);
    },
    expect: () => [const SignUpInProgress()],
    verify: (_) => verify(() => signUp(any())).called(1),
  );

  // REQ-001: no internet shows the network message
  blocTest<SignUpBloc, SignUpState>(
    'should emit SignUpFailed with network message on NetworkFailure',
    build: () {
      when(
        () => signUp(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return SignUpBloc(signUp);
    },
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const SignUpInProgress(),
      const SignUpFailed('Sem internet. Tente de novo.'),
    ],
  );

  // REQ-001: server failure shows the generic message
  blocTest<SignUpBloc, SignUpState>(
    'should emit SignUpFailed with generic message on ServerFailure',
    build: () {
      when(
        () => signUp(any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return SignUpBloc(signUp);
    },
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const SignUpInProgress(),
      const SignUpFailed('Não foi possível criar a conta. Tente de novo.'),
    ],
  );

  // REQ-001: a use case that never answers within 30 seconds fails with the server failure message
  test('should emit SignUpFailed when the use case times out', () {
    fakeAsync((async) {
      when(
        () => signUp(any()),
      ).thenAnswer((_) => Completer<Either<Failure, Unit>>().future);
      final bloc = SignUpBloc(signUp);
      final states = <SignUpState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(submitted);
      async.elapse(const Duration(seconds: 31));

      expect(states, [
        const SignUpInProgress(),
        const SignUpFailed('Não foi possível criar a conta. Tente de novo.'),
      ]);
      sub.cancel();
      bloc.close();
    });
  });

  // REQ-001: submitting again after a failure starts a new attempt
  blocTest<SignUpBloc, SignUpState>(
    'should submit again after a failure',
    build: () {
      when(
        () => signUp(any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return SignUpBloc(signUp);
    },
    act: (bloc) async {
      bloc.add(submitted);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      bloc.add(submitted);
    },
    expect: () => [
      const SignUpInProgress(),
      const SignUpFailed('Não foi possível criar a conta. Tente de novo.'),
      const SignUpInProgress(),
      const SignUpFailed('Não foi possível criar a conta. Tente de novo.'),
    ],
    verify: (_) => verify(() => signUp(any())).called(2),
  );

  // REQ-002: the use case rejects the name with displayNameLength: the bloc emits SignUpFieldsInvalid with that error
  blocTest<SignUpBloc, SignUpState>(
    'should emit SignUpFieldsInvalid when use case rejects fields',
    build: () {
      when(() => signUp(any())).thenAnswer(
        (_) async => Left(
          InvalidAccountFieldsFailure([
            AccountFieldErrorEnum.displayNameLength,
          ]),
        ),
      );
      return SignUpBloc(signUp);
    },
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const SignUpInProgress(),
      SignUpFieldsInvalid([AccountFieldErrorEnum.displayNameLength]),
    ],
  );

  // REQ-002: a new valid submit after SignUpFieldsInvalid starts again with SignUpInProgress
  blocTest<SignUpBloc, SignUpState>(
    'should accept a new submit after SignUpFieldsInvalid',
    build: () {
      when(() => signUp(any())).thenAnswer((_) async => const Right(unit));
      return SignUpBloc(signUp);
    },
    seed: () => SignUpFieldsInvalid([AccountFieldErrorEnum.displayNameLength]),
    act: (bloc) => bloc.add(submitted),
    expect: () => [const SignUpInProgress()],
    verify: (_) => verify(() => signUp(params)).called(1),
  );

  // REQ-010: the use case rejects the e-mail with invalidEmail: the bloc emits SignUpFieldsInvalid with that error
  blocTest<SignUpBloc, SignUpState>(
    'should emit SignUpFieldsInvalid with invalidEmail',
    build: () {
      when(() => signUp(any())).thenAnswer(
        (_) async => Left(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
        ),
      );
      return SignUpBloc(signUp);
    },
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const SignUpInProgress(),
      SignUpFieldsInvalid([AccountFieldErrorEnum.invalidEmail]),
    ],
  );
}
