import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/auth/domain/usecases/change_email_use_case.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/change_email_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockUseCase extends Mock implements ChangeEmailUseCase {}

void main() {
  late _MockUseCase useCase;

  setUpAll(
    () => registerFallbackValue(
      const ChangeEmailParams(newEmail: 'x', currentPassword: 'x'),
    ),
  );

  setUp(() => useCase = _MockUseCase());

  void useCaseReturns(Either<Failure, Unit> result) {
    when(() => useCase(any())).thenAnswer((_) async => result);
  }

  const submitted = ChangeEmailSubmitted(
    newEmail: 'ana.lima@exemplo.com',
    currentPassword: 'abcd1234',
  );

  // REQ-007: Ana changes to "ana.lima@exemplo.com" with "abcd1234": InProgress then Done, use case called once
  blocTest<ChangeEmailBloc, ChangeEmailState>(
    'should emit [InProgress, Done] when change succeeds',
    setUp: () => useCaseReturns(const Right(unit)),
    build: () => ChangeEmailBloc(useCase),
    act: (bloc) => bloc.add(submitted),
    expect: () => [const ChangeEmailInProgress(), const ChangeEmailDone()],
    verify: (_) => verify(
      () => useCase(
        const ChangeEmailParams(
          newEmail: 'ana.lima@exemplo.com',
          currentPassword: 'abcd1234',
        ),
      ),
    ).called(1),
  );

  // REQ-007: Ana changes to " Ana.Lima@Exemplo.com ": the Bloc passes the text as typed, without trimming
  blocTest<ChangeEmailBloc, ChangeEmailState>(
    'should pass typed e-mail as is to the use case',
    setUp: () => useCaseReturns(const Right(unit)),
    build: () => ChangeEmailBloc(useCase),
    act: (bloc) => bloc.add(
      const ChangeEmailSubmitted(
        newEmail: ' Ana.Lima@Exemplo.com ',
        currentPassword: 'abcd1234',
      ),
    ),
    verify: (_) => verify(
      () => useCase(
        const ChangeEmailParams(
          newEmail: ' Ana.Lima@Exemplo.com ',
          currentPassword: 'abcd1234',
        ),
      ),
    ).called(1),
  );

  // REQ-007: change to the same e-mail as the current one: Invalid([sameEmail])
  blocTest<ChangeEmailBloc, ChangeEmailState>(
    'should emit Invalid([sameEmail]) when use case refuses same e-mail',
    setUp: () => useCaseReturns(
      Left(InvalidAccountFieldsFailure([AccountFieldErrorEnum.sameEmail])),
    ),
    build: () => ChangeEmailBloc(useCase),
    act: (bloc) => bloc.add(
      const ChangeEmailSubmitted(
        newEmail: 'ana@exemplo.com',
        currentPassword: 'abcd1234',
      ),
    ),
    expect: () => [
      const ChangeEmailInProgress(),
      ChangeEmailInvalid([AccountFieldErrorEnum.sameEmail]),
    ],
  );

  // REQ-007: Ana changes to "ana@": Invalid([invalidEmail])
  blocTest<ChangeEmailBloc, ChangeEmailState>(
    'should emit Invalid([invalidEmail]) when e-mail is malformed',
    setUp: () => useCaseReturns(
      Left(InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail])),
    ),
    build: () => ChangeEmailBloc(useCase),
    act: (bloc) => bloc.add(
      const ChangeEmailSubmitted(newEmail: 'ana@', currentPassword: 'abcd1234'),
    ),
    expect: () => [
      const ChangeEmailInProgress(),
      ChangeEmailInvalid([AccountFieldErrorEnum.invalidEmail]),
    ],
  );

  // REQ-007: server answers wrong current password: Failed on the current password field
  blocTest<ChangeEmailBloc, ChangeEmailState>(
    'should emit Failed on current password field when password is wrong',
    setUp: () => useCaseReturns(const Left(WrongCurrentPasswordFailure())),
    build: () => ChangeEmailBloc(useCase),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ChangeEmailInProgress(),
      const ChangeEmailFailed(
        'Senha atual incorreta.',
        field: ChangeEmailFieldEnum.currentPassword,
      ),
    ],
  );

  // REQ-007: server answers e-mail already in use: Failed on the new e-mail field
  blocTest<ChangeEmailBloc, ChangeEmailState>(
    'should emit Failed on new e-mail field when e-mail is in use',
    setUp: () => useCaseReturns(const Left(EmailAlreadyInUseFailure())),
    build: () => ChangeEmailBloc(useCase),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ChangeEmailInProgress(),
      const ChangeEmailFailed(
        'Este e-mail já tem conta.',
        field: ChangeEmailFieldEnum.newEmail,
      ),
    ],
  );

  // Offline: general Failed below the button
  blocTest<ChangeEmailBloc, ChangeEmailState>(
    'should emit general Failed when offline',
    setUp: () => useCaseReturns(const Left(NetworkFailure())),
    build: () => ChangeEmailBloc(useCase),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ChangeEmailInProgress(),
      const ChangeEmailFailed('Sem internet. Tente de novo.'),
    ],
  );

  // Server error: generic Failed message
  blocTest<ChangeEmailBloc, ChangeEmailState>(
    'should emit generic Failed on server failure',
    setUp: () => useCaseReturns(const Left(ServerFailure())),
    build: () => ChangeEmailBloc(useCase),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ChangeEmailInProgress(),
      const ChangeEmailFailed('Não foi possível salvar. Tente de novo.'),
    ],
  );

  // Expired session: Failed with session message
  blocTest<ChangeEmailBloc, ChangeEmailState>(
    'should emit Failed when signed out',
    setUp: () => useCaseReturns(const Left(UnauthenticatedFailure())),
    build: () => ChangeEmailBloc(useCase),
    act: (bloc) => bloc.add(submitted),
    expect: () => [
      const ChangeEmailInProgress(),
      const ChangeEmailFailed('Sua sessão terminou. Entre de novo.'),
    ],
  );

  // Double tap while sending: second submit is ignored
  blocTest<ChangeEmailBloc, ChangeEmailState>(
    'should call use case once when submitted twice while in progress',
    setUp: () => when(() => useCase(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return const Right(unit);
    }),
    build: () => ChangeEmailBloc(useCase),
    act: (bloc) {
      bloc.add(submitted);
      bloc.add(submitted);
    },
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => useCase(any())).called(1),
  );
}
