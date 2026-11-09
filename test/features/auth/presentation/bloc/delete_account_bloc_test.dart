import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/auth/domain/usecases/delete_account_use_case.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/delete_account_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeleteAccount extends Mock implements DeleteAccountUseCase {}

void main() {
  late _MockDeleteAccount deleteAccount;

  setUpAll(() => registerFallbackValue(const NoParams()));
  setUp(() => deleteAccount = _MockDeleteAccount());

  void answer(Either<Failure, Unit> result) =>
      when(() => deleteAccount(any())).thenAnswer((_) async => result);

  blocTest<DeleteAccountBloc, DeleteAccountState>(
    'should emit only in progress on success',
    setUp: () => answer(const Right(unit)),
    build: () => DeleteAccountBloc(deleteAccount),
    act: (bloc) => bloc.add(const DeleteAccountRequested()),
    expect: () => const [DeleteAccountInProgress()],
  );

  blocTest<DeleteAccountBloc, DeleteAccountState>(
    'should emit session message on UnauthenticatedFailure',
    setUp: () => answer(const Left(UnauthenticatedFailure())),
    build: () => DeleteAccountBloc(deleteAccount),
    act: (bloc) => bloc.add(const DeleteAccountRequested()),
    expect: () => const [
      DeleteAccountInProgress(),
      DeleteAccountFailed('Sua sessão terminou. Entre de novo.'),
    ],
  );

  blocTest<DeleteAccountBloc, DeleteAccountState>(
    'should emit failed with generic message on ServerFailure',
    setUp: () => answer(const Left(ServerFailure())),
    build: () => DeleteAccountBloc(deleteAccount),
    act: (bloc) => bloc.add(const DeleteAccountRequested()),
    expect: () => const [
      DeleteAccountInProgress(),
      DeleteAccountFailed('Não foi possível excluir a conta. Tente de novo.'),
    ],
  );

  blocTest<DeleteAccountBloc, DeleteAccountState>(
    'should emit connection message on NetworkFailure',
    setUp: () => answer(const Left(NetworkFailure())),
    build: () => DeleteAccountBloc(deleteAccount),
    act: (bloc) => bloc.add(const DeleteAccountRequested()),
    expect: () => const [
      DeleteAccountInProgress(),
      DeleteAccountFailed('Sem conexão. Verifique a internet.'),
    ],
  );

  blocTest<DeleteAccountBloc, DeleteAccountState>(
    'should ignore request while in progress',
    setUp: () => answer(const Right(unit)),
    build: () => DeleteAccountBloc(deleteAccount),
    act: (bloc) => bloc
      ..add(const DeleteAccountRequested())
      ..add(const DeleteAccountRequested()),
    expect: () => const [DeleteAccountInProgress()],
    verify: (_) => verify(() => deleteAccount(any())).called(1),
  );
}
