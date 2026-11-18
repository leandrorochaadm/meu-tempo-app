import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/auth/domain/usecases/change_password_use_case.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/change_password_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockUseCase extends Mock implements ChangePasswordUseCase {}

void main() {
  late _MockUseCase useCase;

  setUpAll(
    () => registerFallbackValue(
      const ChangePasswordParams(currentPassword: 'x', newPassword: 'y'),
    ),
  );

  setUp(() => useCase = _MockUseCase());

  void useCaseReturns(Either<Failure, Unit> result) {
    when(() => useCase(any())).thenAnswer((_) async => result);
  }

  const submitted = ChangePasswordSubmitted(
    currentPassword: 'abcd1234',
    newPassword: 'Wxyz5678',
  );

  // REQ-008: current "abcd1234", new "Wxyz5678", use case Right: InProgress then Done, use case called once with exact params
  blocTest<ChangePasswordBloc, ChangePasswordState>(
    'should emit [InProgress, Done] when use case succeeds',
    setUp: () => useCaseReturns(const Right(unit)),
    build: () => ChangePasswordBloc(useCase),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ChangePasswordInProgress(),
      const ChangePasswordDone(),
    ],
    verify: (_) => verify(
      () => useCase(
        const ChangePasswordParams(
          currentPassword: 'abcd1234',
          newPassword: 'Wxyz5678',
        ),
      ),
    ).called(1),
  );

  // REQ-008: server answers wrong current password: Failed on the current password field
  blocTest<ChangePasswordBloc, ChangePasswordState>(
    'should emit Failed on current password field when current password is wrong',
    setUp: () => useCaseReturns(const Left(WrongCurrentPasswordFailure())),
    build: () => ChangePasswordBloc(useCase),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ChangePasswordInProgress(),
      const ChangePasswordFailed(
        'Senha atual incorreta.',
        field: ChangePasswordFieldEnum.currentPassword,
      ),
    ],
  );

  // REQ-008: current "Abcd123", new "Abcd123": use case refuses with 2 errors (passwordTooShort, samePassword)
  blocTest<ChangePasswordBloc, ChangePasswordState>(
    'should emit Invalid with errors when use case refuses fields',
    setUp: () => useCaseReturns(
      Left(
        InvalidAccountFieldsFailure([
          AccountFieldErrorEnum.passwordTooShort,
          AccountFieldErrorEnum.samePassword,
        ]),
      ),
    ),
    build: () => ChangePasswordBloc(useCase),
    act: (bloc) => bloc.add(
      const ChangePasswordSubmitted(
        currentPassword: 'Abcd123',
        newPassword: 'Abcd123',
      ),
    ),
    expect: () => [
      const ChangePasswordInProgress(),
      ChangePasswordInvalid([
        AccountFieldErrorEnum.passwordTooShort,
        AccountFieldErrorEnum.samePassword,
      ]),
    ],
  );

  // Offline: general Failed below the button
  blocTest<ChangePasswordBloc, ChangePasswordState>(
    'should emit network message when offline',
    setUp: () => useCaseReturns(const Left(NetworkFailure())),
    build: () => ChangePasswordBloc(useCase),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ChangePasswordInProgress(),
      const ChangePasswordFailed('Sem internet. Tente de novo.'),
    ],
  );

  // Server error: generic Failed message
  blocTest<ChangePasswordBloc, ChangePasswordState>(
    'should emit generic message on server failure',
    setUp: () => useCaseReturns(const Left(ServerFailure())),
    build: () => ChangePasswordBloc(useCase),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ChangePasswordInProgress(),
      const ChangePasswordFailed('Não foi possível salvar. Tente de novo.'),
    ],
  );

  // Expired session: Failed with session message
  blocTest<ChangePasswordBloc, ChangePasswordState>(
    'should emit session message when unauthenticated',
    setUp: () => useCaseReturns(const Left(UnauthenticatedFailure())),
    build: () => ChangePasswordBloc(useCase),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ChangePasswordInProgress(),
      const ChangePasswordFailed('Sua sessão terminou. Entre de novo.'),
    ],
  );

  // Double tap while sending: second submit is ignored, use case called once
  test('should ignore submit while in progress', () async {
    final completer = Completer<Either<Failure, Unit>>();
    when(() => useCase(any())).thenAnswer((_) => completer.future);
    final bloc = ChangePasswordBloc(useCase);
    addTearDown(bloc.close);

    bloc.add(submitted);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, const ChangePasswordInProgress());

    bloc.add(submitted);
    await Future<void>.delayed(Duration.zero);
    completer.complete(const Right(unit));
    await Future<void>.delayed(Duration.zero);

    verify(() => useCase(any())).called(1);
    expect(bloc.state, const ChangePasswordDone());
  });

  // Fresh Bloc: initial state is Idle
  test('should start idle', () {
    final bloc = ChangePasswordBloc(useCase);
    addTearDown(bloc.close);

    expect(bloc.state, const ChangePasswordIdle());
  });
}
