import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/features/auth/domain/entities/password_rule_enum.dart';
import 'package:meu_tempo/features/auth/domain/entities/sign_up_form_entity.dart';

void main() {
  const valid = SignUpFormEntity(
    displayName: 'Ana',
    email: 'ana@exemplo.com',
    password: 'Abcd1234',
    acceptedPrivacyPolicy: true,
  );

  // REQ-012: Name "Ana", e-mail "ana@exemplo.com", password "Abcd1234", policy accepted: button active, no warnings
  test('should allow submit when every field is right', () {
    expect(valid.canSubmit, isTrue);
    expect(valid.errors, isEmpty);
    expect(valid.displayNameWarning, isNull);
    expect(valid.emailWarning, isNull);
    expect(valid.passwordWarning, isNull);
  });

  // REQ-012: password "abcd1234" (no uppercase) keeps the button disabled, without a warning under the field
  test('should block submit when password has no uppercase', () {
    const form = SignUpFormEntity(
      displayName: 'Ana',
      email: 'ana@exemplo.com',
      password: 'abcd1234',
      acceptedPrivacyPolicy: true,
    );
    expect(form.canSubmit, isFalse);
    expect(form.errors, [AccountFieldErrorEnum.passwordMissingUppercase]);
    expect(form.passwordWarning, isNull);
  });

  // REQ-012: policy not accepted keeps the button disabled
  test('should block submit when policy is not accepted', () {
    const form = SignUpFormEntity(
      displayName: 'Ana',
      email: 'ana@exemplo.com',
      password: 'Abcd1234',
    );
    expect(form.canSubmit, isFalse);
    expect(form.errors, [AccountFieldErrorEnum.privacyPolicyNotAccepted]);
  });

  // REQ-012: password with 72 characters warns passwordTooLong at once and blocks the button
  test('should warn long password at once when it has 72 characters', () {
    final form = SignUpFormEntity(
      displayName: 'Ana',
      email: 'ana@exemplo.com',
      password: 'Abcd1234' * 9,
      acceptedPrivacyPolicy: true,
    );
    expect(form.passwordWarning, AccountFieldErrorEnum.passwordTooLong);
    expect(form.canSubmit, isFalse);
  });

  // REQ-012: password with 71 characters has no warning and the button is active
  test('should not warn when password has 71 characters', () {
    final form = SignUpFormEntity(
      displayName: 'Ana',
      email: 'ana@exemplo.com',
      password: '${'Abcd1234' * 8}Abcdefg',
      acceptedPrivacyPolicy: true,
    );
    expect(form.password.length, 71);
    expect(form.passwordWarning, isNull);
    expect(form.canSubmit, isTrue);
  });

  // REQ-012: name "A" and e-mail "ana@" while the person is still in the field: no warnings
  test('should not warn name or email before leaving the field', () {
    const form = SignUpFormEntity(displayName: 'A', email: 'ana@');
    expect(form.displayNameWarning, isNull);
    expect(form.emailWarning, isNull);
  });

  // REQ-012: after leaving the name and e-mail fields with wrong values, both warnings show together
  test('should warn name and email after leaving the fields', () {
    const form = SignUpFormEntity(
      displayName: 'A',
      email: 'ana@',
      displayNameLeft: true,
      emailLeft: true,
    );
    expect(form.displayNameWarning, AccountFieldErrorEnum.displayNameLength);
    expect(form.emailWarning, AccountFieldErrorEnum.invalidEmail);
  });

  // REQ-012: leaving a field with a right value shows no warning
  test('should not warn after leaving a valid field', () {
    const form = SignUpFormEntity(
      displayName: 'Ana',
      email: 'ana@exemplo.com',
      displayNameLeft: true,
      emailLeft: true,
    );
    expect(form.displayNameWarning, isNull);
    expect(form.emailWarning, isNull);
  });

  // REQ-012: empty form keeps the button disabled and meets no password rule
  test('should block submit when form is empty', () {
    const form = SignUpFormEntity();
    expect(form.canSubmit, isFalse);
    expect(form.metPasswordRules, isEmpty);
  });

  // REQ-012: the form exposes the password rules met by the typed password
  test('should expose the met password rules', () {
    expect(valid.metPasswordRules, PasswordRuleEnum.values);
  });

  // REQ-012: two forms with the same fields are equal; changing any of the 6 fields makes them different
  test('should compare by value', () {
    const base = SignUpFormEntity(
      displayName: 'Ana',
      email: 'ana@exemplo.com',
      password: 'Abcd1234',
      acceptedPrivacyPolicy: true,
      displayNameLeft: true,
      emailLeft: true,
    );
    const same = SignUpFormEntity(
      displayName: 'Ana',
      email: 'ana@exemplo.com',
      password: 'Abcd1234',
      acceptedPrivacyPolicy: true,
      displayNameLeft: true,
      emailLeft: true,
    );
    expect(base, same);
    expect(base.hashCode, same.hashCode);

    final others = [
      const SignUpFormEntity(
        displayName: 'Bia',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
        acceptedPrivacyPolicy: true,
        displayNameLeft: true,
        emailLeft: true,
      ),
      const SignUpFormEntity(
        displayName: 'Ana',
        email: 'bia@exemplo.com',
        password: 'Abcd1234',
        acceptedPrivacyPolicy: true,
        displayNameLeft: true,
        emailLeft: true,
      ),
      const SignUpFormEntity(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: 'Wxyz5678',
        acceptedPrivacyPolicy: true,
        displayNameLeft: true,
        emailLeft: true,
      ),
      const SignUpFormEntity(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
        displayNameLeft: true,
        emailLeft: true,
      ),
      const SignUpFormEntity(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
        acceptedPrivacyPolicy: true,
        emailLeft: true,
      ),
      const SignUpFormEntity(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
        acceptedPrivacyPolicy: true,
        displayNameLeft: true,
      ),
    ];
    for (final other in others) {
      expect(base, isNot(other));
    }
  });
}
