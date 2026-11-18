import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_tempo/features/auth/domain/usecases/change_password_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

void main() {
  late _MockRepository repo;
  late ChangePasswordUseCase useCase;

  Future<Either<Failure, Unit>> change(String current, String next) => useCase(
    ChangePasswordParams(currentPassword: current, newPassword: next),
  );

  Matcher refusedWith(List<AccountFieldErrorEnum> errors) =>
      isA<InvalidAccountFieldsFailure>().having(
        (f) => f.errors,
        'errors',
        errors,
      );

  void neverCalled() {
    verifyNever(
      () => repo.changePassword(
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    );
    verifyNever(() => repo.signOutOtherDevices());
  }

  void changeReturns(Either<Failure, Unit> result) => when(
    () => repo.changePassword(
      currentPassword: any(named: 'currentPassword'),
      newPassword: any(named: 'newPassword'),
    ),
  ).thenAnswer((_) async => result);

  setUp(() {
    repo = _MockRepository();
    useCase = ChangePasswordUseCase(repo);
    changeReturns(const Right(unit));
    when(
      () => repo.signOutOtherDevices(),
    ).thenAnswer((_) async => const Right(unit));
  });

  // REQ-008: current "abcd1234" (old account, no uppercase), new "Wxyz5678" (8 characters): repository called once and 1 call to sign out other devices
  test(
    'should change password and sign out other devices when new password is valid',
    () async {
      final result = await change('abcd1234', 'Wxyz5678');

      expect(result, const Right<Failure, Unit>(unit));
      verify(
        () => repo.changePassword(
          currentPassword: 'abcd1234',
          newPassword: 'Wxyz5678',
        ),
      ).called(1);
      verify(() => repo.signOutOtherDevices()).called(1);
    },
  );

  // REQ-008: current "abcd1234", new "Wxyz567" (7 characters): refused with passwordTooShort, 0 server calls
  test(
    'should refuse with passwordTooShort when new password has 7 characters',
    () async {
      final result = await change('abcd1234', 'Wxyz567');

      expect(
        result.getLeft().toNullable(),
        refusedWith([AccountFieldErrorEnum.passwordTooShort]),
      );
      neverCalled();
    },
  );

  // REQ-008: current "abcd1234", new "wxyz5678" (no uppercase): refused with passwordMissingUppercase, 0 server calls
  test(
    'should refuse with passwordMissingUppercase when new password has no uppercase',
    () async {
      final result = await change('abcd1234', 'wxyz5678');

      expect(
        result.getLeft().toNullable(),
        refusedWith([AccountFieldErrorEnum.passwordMissingUppercase]),
      );
      neverCalled();
    },
  );

  // REQ-008: current "Abcd1234", new "Abcd1234": refused with samePassword, 0 server calls
  test(
    'should refuse with samePassword when new password equals current',
    () async {
      final result = await change('Abcd1234', 'Abcd1234');

      expect(
        result.getLeft().toNullable(),
        refusedWith([AccountFieldErrorEnum.samePassword]),
      );
      neverCalled();
    },
  );

  // REQ-008: current "Abcd123", new "Abcd123": refused with 2 errors (passwordTooShort, samePassword), 0 server calls
  test(
    'should refuse with two errors when new password is short and equals current',
    () async {
      final result = await change('Abcd123', 'Abcd123');

      expect(
        result.getLeft().toNullable(),
        refusedWith([
          AccountFieldErrorEnum.passwordTooShort,
          AccountFieldErrorEnum.samePassword,
        ]),
      );
      neverCalled();
    },
  );

  // REQ-008: server answers wrong current password: WrongCurrentPasswordFailure, 0 calls to sign out other devices
  test(
    'should return WrongCurrentPasswordFailure and not sign out others when current password is wrong',
    () async {
      changeReturns(const Left(WrongCurrentPasswordFailure()));

      final result = await change('abcd1234', 'Wxyz5678');

      expect(result, const Left<Failure, Unit>(WrongCurrentPasswordFailure()));
      verifyNever(() => repo.signOutOtherDevices());
    },
  );

  // REQ-008: change accepted but sign out of other devices fails (no internet): returns the NetworkFailure, password already changed
  test(
    'should return sign out failure when signing out other devices fails',
    () async {
      when(
        () => repo.signOutOtherDevices(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await change('abcd1234', 'Wxyz5678');

      expect(result, const Left<Failure, Unit>(NetworkFailure()));
      verify(
        () => repo.changePassword(
          currentPassword: 'abcd1234',
          newPassword: 'Wxyz5678',
        ),
      ).called(1);
    },
  );

  // REQ-008: change fails by network or server: returns that failure, 0 calls to sign out other devices
  test(
    'should return network failure and not sign out others when change fails',
    () async {
      changeReturns(const Left(NetworkFailure()));
      expect(
        await change('abcd1234', 'Wxyz5678'),
        const Left<Failure, Unit>(NetworkFailure()),
      );

      changeReturns(const Left(ServerFailure()));
      expect(
        await change('abcd1234', 'Wxyz5678'),
        const Left<Failure, Unit>(ServerFailure()),
      );

      verifyNever(() => repo.signOutOtherDevices());
    },
  );

  // REQ-008: ChangePasswordParams with the same fields are equal; changing one field makes them different
  test('ChangePasswordParams should compare by value', () {
    const a = ChangePasswordParams(currentPassword: 'x', newPassword: 'y');
    const b = ChangePasswordParams(currentPassword: 'x', newPassword: 'y');

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a,
      isNot(const ChangePasswordParams(currentPassword: 'z', newPassword: 'y')),
    );
    expect(
      a,
      isNot(const ChangePasswordParams(currentPassword: 'x', newPassword: 'z')),
    );
  });
}
