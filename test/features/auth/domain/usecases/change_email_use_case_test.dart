import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_tempo/features/auth/domain/usecases/change_email_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

void main() {
  late _MockRepository repo;
  late ChangeEmailUseCase useCase;

  Future<Either<Failure, Unit>> change(String email) =>
      useCase(ChangeEmailParams(newEmail: email, currentPassword: 'abcd1234'));

  Matcher refusedWith(AccountFieldErrorEnum error) =>
      isA<InvalidAccountFieldsFailure>().having((f) => f.errors, 'errors', [
        error,
      ]);

  void neverCalled() {
    verifyNever(
      () => repo.changeEmail(
        email: any(named: 'email'),
        currentPassword: any(named: 'currentPassword'),
      ),
    );
    verifyNever(() => repo.signOutOtherDevices());
  }

  setUp(() {
    repo = _MockRepository();
    useCase = ChangeEmailUseCase(repo);
    when(() => repo.currentUser()).thenReturn(
      const UserEntity(uid: 'u1', email: 'ana@exemplo.com', displayName: 'Ana'),
    );
    when(
      () => repo.changeEmail(
        email: any(named: 'email'),
        currentPassword: any(named: 'currentPassword'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repo.signOutOtherDevices(),
    ).thenAnswer((_) async => const Right(unit));
  });

  // REQ-007: Ana ("ana@exemplo.com") changes to "ana.lima@exemplo.com" with "abcd1234": repository called once and 1 call to sign out other devices
  test(
    'should change email and sign out other devices when email and password are valid',
    () async {
      final result = await change('ana.lima@exemplo.com');

      expect(result, const Right<Failure, Unit>(unit));
      verify(
        () => repo.changeEmail(
          email: 'ana.lima@exemplo.com',
          currentPassword: 'abcd1234',
        ),
      ).called(1);
      verify(() => repo.signOutOtherDevices()).called(1);
    },
  );

  // REQ-007: Ana changes to " Ana.Lima@Exemplo.com " with "abcd1234": repository receives "ana.lima@exemplo.com", 1 call
  test(
    'should send the normalized email when it has spaces and uppercase',
    () async {
      await change(' Ana.Lima@Exemplo.com ');

      verify(
        () => repo.changeEmail(
          email: 'ana.lima@exemplo.com',
          currentPassword: 'abcd1234',
        ),
      ).called(1);
    },
  );

  // REQ-007: Ana changes to "ana@exemplo.com" with "abcd1234": refused with sameEmail, 0 server calls
  test(
    'should refuse with sameEmail when the new email equals the current one',
    () async {
      final result = await change('ana@exemplo.com');

      expect(
        result.getLeft().toNullable(),
        refusedWith(AccountFieldErrorEnum.sameEmail),
      );
      neverCalled();
    },
  );

  // REQ-007: Ana changes to "ANA@exemplo.com" with "abcd1234": refused with sameEmail, 0 server calls
  test(
    'should refuse with sameEmail when the new email differs only in case',
    () async {
      final result = await change('ANA@exemplo.com');

      expect(
        result.getLeft().toNullable(),
        refusedWith(AccountFieldErrorEnum.sameEmail),
      );
      neverCalled();
    },
  );

  // REQ-007: Ana changes to "ana@" with "abcd1234": refused with invalidEmail, 0 server calls
  test(
    'should refuse with invalidEmail when the new email is malformed',
    () async {
      final result = await change('ana@');

      expect(
        result.getLeft().toNullable(),
        refusedWith(AccountFieldErrorEnum.invalidEmail),
      );
      neverCalled();
    },
  );

  // REQ-007: server answers wrong current password: WrongCurrentPasswordFailure, 0 calls to sign out other devices
  test(
    'should return WrongCurrentPasswordFailure and not sign out other devices when the password is wrong',
    () async {
      when(
        () => repo.changeEmail(
          email: any(named: 'email'),
          currentPassword: any(named: 'currentPassword'),
        ),
      ).thenAnswer((_) async => const Left(WrongCurrentPasswordFailure()));

      final result = await change('ana.lima@exemplo.com');

      expect(result, const Left<Failure, Unit>(WrongCurrentPasswordFailure()));
      verifyNever(() => repo.signOutOtherDevices());
    },
  );

  // REQ-007: server answers email already in use: EmailAlreadyInUseFailure, 0 calls to sign out other devices
  test(
    'should return EmailAlreadyInUseFailure and not sign out other devices when the email is taken',
    () async {
      when(
        () => repo.changeEmail(
          email: any(named: 'email'),
          currentPassword: any(named: 'currentPassword'),
        ),
      ).thenAnswer((_) async => const Left(EmailAlreadyInUseFailure()));

      final result = await change('ana.lima@exemplo.com');

      expect(result, const Left<Failure, Unit>(EmailAlreadyInUseFailure()));
      verifyNever(() => repo.signOutOtherDevices());
    },
  );

  // REQ-007: no session: UnauthenticatedFailure, 0 calls
  test('should return UnauthenticatedFailure when there is no user', () async {
    when(() => repo.currentUser()).thenReturn(null);

    final result = await change('ana.lima@exemplo.com');

    expect(result, const Left<Failure, Unit>(UnauthenticatedFailure()));
    neverCalled();
  });

  // REQ-007: change accepted but sign out fails (no internet): returns NetworkFailure, change already done
  test(
    'should return the sign-out failure when signing out other devices fails',
    () async {
      when(
        () => repo.signOutOtherDevices(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await change('ana.lima@exemplo.com');

      expect(result, const Left<Failure, Unit>(NetworkFailure()));
      verify(
        () => repo.changeEmail(
          email: 'ana.lima@exemplo.com',
          currentPassword: 'abcd1234',
        ),
      ).called(1);
    },
  );

  // REQ-007: no internet on the change: NetworkFailure, 0 calls to sign out other devices
  test(
    'should not sign out other devices when change email fails with NetworkFailure',
    () async {
      when(
        () => repo.changeEmail(
          email: any(named: 'email'),
          currentPassword: any(named: 'currentPassword'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await change('ana.lima@exemplo.com');

      expect(result, const Left<Failure, Unit>(NetworkFailure()));
      verifyNever(() => repo.signOutOtherDevices());
    },
  );

  // REQ-007: ChangeEmailParams with the same fields are equal; changing one field makes them different
  test('ChangeEmailParams should compare by value', () {
    const a = ChangeEmailParams(newEmail: 'a@b.com', currentPassword: 'x');
    const b = ChangeEmailParams(newEmail: 'a@b.com', currentPassword: 'x');

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a,
      isNot(const ChangeEmailParams(newEmail: 'c@b.com', currentPassword: 'x')),
    );
    expect(
      a,
      isNot(const ChangeEmailParams(newEmail: 'a@b.com', currentPassword: 'y')),
    );
  });
}
