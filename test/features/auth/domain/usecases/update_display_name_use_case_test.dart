import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_tempo/features/auth/domain/usecases/update_display_name_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

void main() {
  late _MockRepository repo;
  late UpdateDisplayNameUseCase useCase;

  void signedInAs(String? displayName) {
    when(() => repo.currentUser()).thenReturn(
      UserEntity(uid: 'u1', email: 'ana@exemplo.com', displayName: displayName),
    );
  }

  Future<Either<Failure, Unit>> save(String name) =>
      useCase(UpdateDisplayNameParams(displayName: name));

  setUp(() {
    repo = _MockRepository();
    useCase = UpdateDisplayNameUseCase(repo);
    when(
      () => repo.updateDisplayName(any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  // REQ-006: Name "Ana", saves "Ana Lima": Name "Ana Lima", 1 write
  test('should save "Ana Lima" once when current name is "Ana"', () async {
    signedInAs('Ana');

    final result = await save('Ana Lima');

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repo.updateDisplayName('Ana Lima')).called(1);
  });

  // REQ-006: Name "Ana", saves " Ana Lima ": Name "Ana Lima", 1 write
  test(
    'should save trimmed "Ana Lima" once when input has edge spaces',
    () async {
      signedInAs('Ana');

      await save(' Ana Lima ');

      verify(() => repo.updateDisplayName('Ana Lima')).called(1);
    },
  );

  // REQ-006: Name "Ana", saves "Ana": refused with sameDisplayName, 0 writes
  test('should refuse with sameDisplayName when name equals current', () async {
    signedInAs('Ana');

    final result = await save('Ana');

    expect(
      result.getLeft().toNullable(),
      isA<InvalidAccountFieldsFailure>().having((f) => f.errors, 'errors', [
        AccountFieldErrorEnum.sameDisplayName,
      ]),
    );
    verifyNever(() => repo.updateDisplayName(any()));
  });

  // REQ-006: Name "Ana", saves " Ana ": refused with sameDisplayName, 0 writes
  test(
    'should refuse with sameDisplayName when trimmed name equals current',
    () async {
      signedInAs('Ana');

      final result = await save(' Ana ');

      expect(
        result.getLeft().toNullable(),
        isA<InvalidAccountFieldsFailure>().having((f) => f.errors, 'errors', [
          AccountFieldErrorEnum.sameDisplayName,
        ]),
      );
      verifyNever(() => repo.updateDisplayName(any()));
    },
  );

  // REQ-006: Name "Ana", saves "A" (1 character): refused with displayNameLength, 0 writes
  test(
    'should refuse with displayNameLength when name has 1 character',
    () async {
      signedInAs('Ana');

      final result = await save('A');

      expect(
        result.getLeft().toNullable(),
        isA<InvalidAccountFieldsFailure>().having((f) => f.errors, 'errors', [
          AccountFieldErrorEnum.displayNameLength,
        ]),
      );
      verifyNever(() => repo.updateDisplayName(any()));
    },
  );

  // REQ-006: Account without Name, saves "Ana": Name "Ana", 1 write
  test('should save "Ana" once when account has no name', () async {
    signedInAs(null);

    final result = await save('Ana');

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repo.updateDisplayName('Ana')).called(1);
  });

  // REQ-006: no session: UnauthenticatedFailure, 0 writes
  test(
    'should return UnauthenticatedFailure when there is no current user',
    () async {
      when(() => repo.currentUser()).thenReturn(null);

      final result = await save('Ana Lima');

      expect(result, const Left<Failure, Unit>(UnauthenticatedFailure()));
      verifyNever(() => repo.updateDisplayName(any()));
    },
  );

  // REQ-006: repository fails: the failure is returned as is
  test('should return the repository failure when saving fails', () async {
    signedInAs('Ana');
    when(
      () => repo.updateDisplayName(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    expect(await save('Ana Lima'), const Left<Failure, Unit>(NetworkFailure()));
  });
}
