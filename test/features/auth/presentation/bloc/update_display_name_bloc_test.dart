import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/auth/domain/usecases/update_display_name_use_case.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/update_display_name_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockUseCase extends Mock implements UpdateDisplayNameUseCase {}

void main() {
  late _MockUseCase useCase;

  setUpAll(
    () =>
        registerFallbackValue(const UpdateDisplayNameParams(displayName: 'x')),
  );

  setUp(() => useCase = _MockUseCase());

  void useCaseReturns(Either<Failure, Unit> result) {
    when(() => useCase(any())).thenAnswer((_) async => result);
  }

  // REQ-006: saving a valid name: InProgress then Saved, use case called with the typed text
  blocTest<UpdateDisplayNameBloc, UpdateDisplayNameState>(
    'should emit Saved after InProgress when name is saved',
    setUp: () => useCaseReturns(const Right(unit)),
    build: () => UpdateDisplayNameBloc(useCase),
    act: (bloc) => bloc.add(const UpdateDisplayNameSubmitted(' Ana Lima ')),
    expect: () => [
      const UpdateDisplayNameInProgress(),
      const UpdateDisplayNameSaved(),
    ],
    verify: (_) => verify(
      () => useCase(const UpdateDisplayNameParams(displayName: ' Ana Lima ')),
    ).called(1),
  );

  // REQ-006: use case returns InvalidAccountFieldsFailure([sameDisplayName]): InProgress then Invalid
  blocTest<UpdateDisplayNameBloc, UpdateDisplayNameState>(
    'should emit Invalid with errors when use case returns InvalidAccountFieldsFailure',
    setUp: () => useCaseReturns(
      Left(
        InvalidAccountFieldsFailure([AccountFieldErrorEnum.sameDisplayName]),
      ),
    ),
    build: () => UpdateDisplayNameBloc(useCase),
    act: (bloc) => bloc.add(const UpdateDisplayNameSubmitted('Ana')),
    expect: () => [
      const UpdateDisplayNameInProgress(),
      UpdateDisplayNameInvalid([AccountFieldErrorEnum.sameDisplayName]),
    ],
  );

  // REQ-006: no session: Failed with session message
  blocTest<UpdateDisplayNameBloc, UpdateDisplayNameState>(
    'should emit Failed with session message',
    setUp: () => useCaseReturns(const Left(UnauthenticatedFailure())),
    build: () => UpdateDisplayNameBloc(useCase),
    act: (bloc) => bloc.add(const UpdateDisplayNameSubmitted('Ana Lima')),
    expect: () => [
      const UpdateDisplayNameInProgress(),
      const UpdateDisplayNameFailed('Sua sessão terminou. Entre de novo.'),
    ],
  );

  // REQ-006: no internet: Failed with no-internet message
  blocTest<UpdateDisplayNameBloc, UpdateDisplayNameState>(
    'should emit Failed with no-internet message',
    setUp: () => useCaseReturns(const Left(NetworkFailure())),
    build: () => UpdateDisplayNameBloc(useCase),
    act: (bloc) => bloc.add(const UpdateDisplayNameSubmitted('Ana Lima')),
    expect: () => [
      const UpdateDisplayNameInProgress(),
      const UpdateDisplayNameFailed('Sem internet. Tente de novo.'),
    ],
  );

  // REQ-006: server error: Failed with generic message
  blocTest<UpdateDisplayNameBloc, UpdateDisplayNameState>(
    'should emit Failed with generic message',
    setUp: () => useCaseReturns(const Left(ServerFailure())),
    build: () => UpdateDisplayNameBloc(useCase),
    act: (bloc) => bloc.add(const UpdateDisplayNameSubmitted('Ana Lima')),
    expect: () => [
      const UpdateDisplayNameInProgress(),
      const UpdateDisplayNameFailed('Não foi possível salvar. Tente de novo.'),
    ],
  );

  // REQ-006: double tap on "Salvar": 1 use case call
  test('should ignore submit while in progress', () async {
    useCaseReturns(const Right(unit));
    when(() => useCase(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return const Right(unit);
    });
    final bloc = UpdateDisplayNameBloc(useCase)
      ..add(const UpdateDisplayNameSubmitted('Ana Lima'))
      ..add(const UpdateDisplayNameSubmitted('Ana Lima'));

    await bloc.stream.firstWhere((s) => s is UpdateDisplayNameSaved);

    verify(() => useCase(any())).called(1);
    await bloc.close();
  });
}
