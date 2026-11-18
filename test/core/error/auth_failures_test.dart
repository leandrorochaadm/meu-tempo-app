import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';

void main() {
  // REQ-002: InvalidAccountFieldsFailure([displayNameLength]) equals another with the same errors and differs with other errors
  test('InvalidAccountFieldsFailure should compare by value', () {
    final a = InvalidAccountFieldsFailure([
      AccountFieldErrorEnum.displayNameLength,
    ]);
    final b = InvalidAccountFieldsFailure([
      AccountFieldErrorEnum.displayNameLength,
    ]);
    final other = InvalidAccountFieldsFailure([
      AccountFieldErrorEnum.invalidEmail,
    ]);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(other));
  });

  // REQ-002: the errors list of InvalidAccountFieldsFailure cannot be changed
  test('should expose an unmodifiable list', () {
    final failure = InvalidAccountFieldsFailure([
      AccountFieldErrorEnum.displayNameLength,
    ]);

    expect(
      () => failure.errors.add(AccountFieldErrorEnum.invalidEmail),
      throwsUnsupportedError,
    );
  });

  // REQ-005: EmailAlreadyInUseFailure equals another one and differs from ServerFailure
  test('EmailAlreadyInUseFailure should be equal by value', () {
    expect(const EmailAlreadyInUseFailure(), const EmailAlreadyInUseFailure());
    expect(
      const EmailAlreadyInUseFailure().hashCode,
      const EmailAlreadyInUseFailure().hashCode,
    );
    expect(const EmailAlreadyInUseFailure(), isNot(const ServerFailure()));
  });
}
