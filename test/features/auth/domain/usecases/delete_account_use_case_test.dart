import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/domain/repositories/account_data_repository.dart';
import 'package:meu_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_tempo/features/auth/domain/usecases/delete_account_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAccountDataRepository extends Mock
    implements AccountDataRepository {}

const _user = UserEntity(uid: 'u1', email: 'a@b.com');

void main() {
  late _MockAuthRepository auth;
  late _MockAccountDataRepository data;
  late DeleteAccountUseCase useCase;

  setUp(() {
    auth = _MockAuthRepository();
    data = _MockAccountDataRepository();
    useCase = DeleteAccountUseCase(auth, data);
    when(() => auth.currentUser()).thenReturn(_user);
    when(
      () => data.deleteBlockingRecords(),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => data.clearLocalData(),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => auth.deleteCurrentUser(),
    ).thenAnswer((_) async => const Right(unit));
  });

  test(
    'should delete data, clear local data and delete user in order',
    () async {
      expect(await useCase(const NoParams()), const Right(unit));
      verifyInOrder([
        () => data.deleteBlockingRecords(),
        () => data.clearLocalData(),
        () => auth.deleteCurrentUser(),
      ]);
    },
  );

  test(
    'should fail without calling repositories when there is no current user',
    () async {
      when(() => auth.currentUser()).thenReturn(null);
      expect(
        await useCase(const NoParams()),
        const Left(UnauthenticatedFailure()),
      );
      verifyNever(() => data.deleteBlockingRecords());
      verifyNever(() => data.clearLocalData());
      verifyNever(() => auth.deleteCurrentUser());
    },
  );

  test('should not delete user when blocking records deletion fails', () async {
    when(
      () => data.deleteBlockingRecords(),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    expect(await useCase(const NoParams()), const Left(NetworkFailure()));
    verifyNever(() => data.clearLocalData());
    verifyNever(() => auth.deleteCurrentUser());
  });

  test('should delete user even when local clear fails', () async {
    when(
      () => data.clearLocalData(),
    ).thenAnswer((_) async => const Left(ServerFailure()));
    expect(await useCase(const NoParams()), const Right(unit));
    verify(() => auth.deleteCurrentUser()).called(1);
  });

  test('should return failure when user deletion fails', () async {
    when(
      () => auth.deleteCurrentUser(),
    ).thenAnswer((_) async => const Left(ServerFailure()));
    expect(await useCase(const NoParams()), const Left(ServerFailure()));
  });
}
