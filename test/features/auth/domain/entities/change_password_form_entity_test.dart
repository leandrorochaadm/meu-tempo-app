import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/features/auth/domain/entities/change_password_form_entity.dart';

void main() {
  // REQ-012: current "abcd1234" (old account, breaks REQ-003 rules), new "Wxyz5678": button active
  test(
    'canSubmit should be true when current password breaks REQ-003 rules',
    () {
      const form = ChangePasswordFormEntity(
        currentPassword: 'abcd1234',
        newPassword: 'Wxyz5678',
      );

      expect(form.canSubmit, isTrue);
    },
  );

  // REQ-012: both empty: samePassword is in errors but no warning is shown
  test('newPasswordWarning should be null when new password is empty', () {
    const form = ChangePasswordFormEntity();

    expect(form.errors, contains(AccountFieldErrorEnum.samePassword));
    expect(form.newPasswordWarning, isNull);
    expect(form.canSubmit, isFalse);
  });

  // REQ-012: new password over 71 characters and equal to current: passwordTooLong wins over samePassword
  test(
    'newPasswordWarning should prefer passwordTooLong over samePassword',
    () {
      final tooLong = 'Aa1${'b' * 69}';
      final form = ChangePasswordFormEntity(
        currentPassword: tooLong,
        newPassword: tooLong,
      );

      expect(form.errors, contains(AccountFieldErrorEnum.samePassword));
      expect(form.newPasswordWarning, AccountFieldErrorEnum.passwordTooLong);
    },
  );

  // REQ-012: current "   " (only spaces), new "Wxyz5678": counts as filled, button active
  test('canSubmit should be true when current password is only spaces', () {
    const form = ChangePasswordFormEntity(
      currentPassword: '   ',
      newPassword: 'Wxyz5678',
    );

    expect(form.canSubmit, isTrue);
  });

  // REQ-012: current "Abcd1234", new "Abcd1234": samePassword warning shown, button disabled
  test('newPasswordWarning should be samePassword when new equals current', () {
    const form = ChangePasswordFormEntity(
      currentPassword: 'Abcd1234',
      newPassword: 'Abcd1234',
    );

    expect(form.newPasswordWarning, AccountFieldErrorEnum.samePassword);
    expect(form.canSubmit, isFalse);
  });

  // REQ-012: criteria errors never become a warning, only the checklist shows them
  test(
    'newPasswordWarning should be null when new password only misses criteria',
    () {
      const form = ChangePasswordFormEntity(
        currentPassword: 'abcd1234',
        newPassword: 'abc',
      );

      expect(form.newPasswordWarning, isNull);
      expect(form.canSubmit, isFalse);
    },
  );

  // REQ-012: current empty, new "Wxyz5678": button disabled
  test('canSubmit should be false when current password is empty', () {
    const form = ChangePasswordFormEntity(newPassword: 'Wxyz5678');

    expect(form.canSubmit, isFalse);
  });

  // REQ-012: equality by value
  test('should compare by value', () {
    const base = ChangePasswordFormEntity(
      currentPassword: 'abcd1234',
      newPassword: 'Wxyz5678',
    );
    const same = ChangePasswordFormEntity(
      currentPassword: 'abcd1234',
      newPassword: 'Wxyz5678',
    );

    expect(base, same);
    expect(base.hashCode, same.hashCode);
    expect(
      base,
      isNot(
        const ChangePasswordFormEntity(
          currentPassword: 'other1234',
          newPassword: 'Wxyz5678',
        ),
      ),
    );
    expect(
      base,
      isNot(
        const ChangePasswordFormEntity(
          currentPassword: 'abcd1234',
          newPassword: 'Other5678',
        ),
      ),
    );
  });
}
