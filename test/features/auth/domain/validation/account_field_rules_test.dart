import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/features/auth/domain/validation/account_field_rules.dart';

void main() {
  const rejected = [AccountFieldErrorEnum.displayNameLength];

  // REQ-002: Update name, name with 49 characters: accepted
  test('should accept 49 characters', () {
    expect(checkDisplayName('a' * 49), isEmpty);
  });

  // REQ-002: Update name, name with 50 characters: accepted
  test('should accept 50 characters', () {
    expect(checkDisplayName('a' * 50), isEmpty);
  });

  // REQ-002: Update name, name with 51 characters: rejected with displayNameLength
  test('should reject 51 characters', () {
    expect(checkDisplayName('a' * 51), rejected);
  });

  // REQ-002: Update name, 50 characters with 2 spaces on each end: accepted
  test('should accept 50 characters surrounded by spaces', () {
    expect(checkDisplayName('  ${'a' * 50}  '), isEmpty);
  });

  // REQ-002: Empty name is rejected with displayNameLength
  test('should reject empty name', () {
    expect(checkDisplayName(''), rejected);
  });

  // REQ-002: Sign up, name "José" with "e" + combining accent (4 characters): accepted
  test('should count José as 4', () {
    expect(checkDisplayName('José'), isEmpty);
    expect(checkDisplayName('Á'), rejected);
  });

  // REQ-002: Sign up, name with only spaces: rejected with displayNameLength
  test('should reject name with only spaces', () {
    expect(checkDisplayName('   '), rejected);
  });

  // REQ-002: Sign up, name " A " (space, letter, space): rejected with displayNameLength
  test('should reject " A " after trimming', () {
    expect(checkDisplayName(' A '), rejected);
  });

  // REQ-002: Sign up, name "😀" (1 emoji): rejected; "😀😀" (2 emojis): accepted
  test('should count emojis as one character each', () {
    expect(checkDisplayName('😀'), rejected);
    expect(checkDisplayName('😀😀'), isEmpty);
  });

  // REQ-002: Sign up, names "Al" (2), "Ana" (3) and "A B" (inner space counts): accepted
  test('should accept the minimum length and inner spaces', () {
    expect(checkDisplayName('Al'), isEmpty);
    expect(checkDisplayName('Ana'), isEmpty);
    expect(checkDisplayName('A B'), isEmpty);
    expect(checkDisplayName('A'), rejected);
  });

  group('checkEmail', () {
    const invalid = [AccountFieldErrorEnum.invalidEmail];

    // REQ-010: E-mail "ana@exemplo.com": accepted
    test('should accept ana@exemplo.com', () {
      expect(checkEmail('ana@exemplo.com'), isEmpty);
    });

    // REQ-010: E-mail "a@b.co": accepted
    test('should accept a@b.co', () {
      expect(checkEmail('a@b.co'), isEmpty);
    });

    // REQ-010: E-mail "ana@": rejected with invalidEmail
    test('should reject ana@ with invalidEmail', () {
      expect(checkEmail('ana@'), invalid);
    });

    // REQ-010: E-mail "ana.exemplo.com" (no "@"): rejected with invalidEmail
    test('should reject email without at sign', () {
      expect(checkEmail('ana.exemplo.com'), invalid);
    });

    // REQ-010: Empty e-mail: rejected with invalidEmail
    test('should reject empty email', () {
      expect(checkEmail(''), invalid);
    });

    // REQ-010: E-mail "@exemplo.com" (nothing before "@"): rejected with invalidEmail
    test('should reject email with nothing before at sign', () {
      expect(checkEmail('@exemplo.com'), invalid);
    });

    // REQ-010: E-mail "ana@@exemplo.com" (two "@"): rejected with invalidEmail
    test('should reject email with two at signs', () {
      expect(checkEmail('ana@@exemplo.com'), invalid);
    });

    // REQ-010: E-mail "ana@exemplo" (domain without dot): rejected with invalidEmail
    test('should reject domain without dot', () {
      expect(checkEmail('ana@exemplo'), invalid);
    });

    // REQ-010: E-mail "ana@exemplo." (dot at the end): rejected with invalidEmail
    test('should reject domain ending with dot', () {
      expect(checkEmail('ana@exemplo.'), invalid);
    });

    // REQ-010: E-mail "ana@.exemplo.com" (dot at the start of the domain): rejected with invalidEmail
    test('should reject domain starting with dot', () {
      expect(checkEmail('ana@.exemplo.com'), invalid);
    });

    // REQ-010: E-mail "ana @exemplo.com" (inner space): rejected with invalidEmail
    test('should reject email with inner space', () {
      expect(checkEmail('ana @exemplo.com'), invalid);
    });

    // REQ-010: E-mail "ana@exemplo..com" (two dots in a row in the domain): rejected with invalidEmail
    test('should reject consecutive dots in domain', () {
      expect(checkEmail('ana@exemplo..com'), invalid);
    });

    // REQ-010: E-mail "ana..lima@exemplo.com" (two dots in a row before "@"): rejected with invalidEmail
    test('should reject consecutive dots before at sign', () {
      expect(checkEmail('ana..lima@exemplo.com'), invalid);
    });

    // REQ-010: E-mail "ana.lima@exemplo.com.br" (separate dots): accepted
    test('should accept ana.lima@exemplo.com.br', () {
      expect(checkEmail('ana.lima@exemplo.com.br'), isEmpty);
    });

    // REQ-005, REQ-010: E-mail " Ana@Exemplo.com " is normalized before the check: accepted
    test('should accept email with edge spaces and uppercase', () {
      expect(checkEmail(' Ana@Exemplo.com '), isEmpty);
    });

    // REQ-010: any whitespace inside the e-mail (tab, line break) is rejected, not only the space character
    test('should reject email with tab or line break inside', () {
      expect(checkEmail('ana\t@exemplo.com'), invalid);
      expect(checkEmail('ana@exemplo\n.com'), invalid);
    });
  });

  group('checkPassword', () {
    const tooShort = AccountFieldErrorEnum.passwordTooShort;
    const tooLong = AccountFieldErrorEnum.passwordTooLong;
    const noDigit = AccountFieldErrorEnum.passwordMissingDigit;
    const noUpper = AccountFieldErrorEnum.passwordMissingUppercase;
    const noLower = AccountFieldErrorEnum.passwordMissingLowercase;

    // REQ-003: Password "Abcd123" (7 characters): rejected with passwordTooShort
    test('should reject Abcd123 with passwordTooShort', () {
      expect(checkPassword('Abcd123'), [tooShort]);
    });

    // REQ-003: Password "Abcd1234" (8 characters): accepted
    test('should accept Abcd1234', () {
      expect(checkPassword('Abcd1234'), isEmpty);
    });

    // REQ-003: Password "Abcd12345" (9 characters): accepted
    test('should accept Abcd12345', () {
      expect(checkPassword('Abcd12345'), isEmpty);
    });

    // REQ-003: Password " Abcd123" (8 characters, leading space): accepted, the space counts
    test('should accept leading space counted as a character', () {
      expect(checkPassword(' Abcd123'), isEmpty);
    });

    // REQ-003: Empty password: 4 errors in fixed order
    test('should return 4 errors in order for empty password', () {
      expect(checkPassword(''), [tooShort, noDigit, noUpper, noLower]);
    });

    // REQ-003: Password with 70 characters, with digit, uppercase and lowercase: accepted
    test('should accept 70 characters', () {
      expect(checkPassword('Ab1${'x' * 67}'), isEmpty);
    });

    // REQ-003: Password with 71 characters (limit): accepted
    test('should accept 71 characters', () {
      expect(checkPassword('Ab1${'x' * 68}'), isEmpty);
    });

    // REQ-003: Password with 72 characters: rejected with passwordTooLong only
    test('should reject 72 characters with passwordTooLong only', () {
      expect(checkPassword('Ab1${'x' * 69}'), [tooLong]);
    });

    // REQ-003: Password "Abcdefgh" (no digit): rejected with passwordMissingDigit
    test('should reject Abcdefgh with passwordMissingDigit', () {
      expect(checkPassword('Abcdefgh'), [noDigit]);
    });

    // REQ-003: Password "abcd1234" (no uppercase): rejected with passwordMissingUppercase
    test('should reject abcd1234 with passwordMissingUppercase', () {
      expect(checkPassword('abcd1234'), [noUpper]);
    });

    // REQ-003: Password "ABCD1234" (no lowercase): rejected with passwordMissingLowercase
    test('should reject ABCD1234 with passwordMissingLowercase', () {
      expect(checkPassword('ABCD1234'), [noLower]);
    });

    // REQ-003: Password "Ébcd1234" (accented uppercase): accepted
    test('should accept accented uppercase Ébcd1234', () {
      expect(checkPassword('Ébcd1234'), isEmpty);
    });

    // REQ-003: Password "ABCDé123" (accented lowercase): accepted
    test('should accept accented lowercase ABCDé123', () {
      expect(checkPassword('ABCDé123'), isEmpty);
    });

    // REQ-003: Password with 8 spaces: 3 errors (digit, uppercase, lowercase)
    test('should return 3 errors for 8 spaces', () {
      expect(checkPassword('        '), [noDigit, noUpper, noLower]);
    });
  });

  group('checkPrivacyPolicyAccepted', () {
    // REQ-004: acceptance checked: no error
    test('should return no error when accepted', () {
      expect(checkPrivacyPolicyAccepted(true), isEmpty);
    });

    // REQ-004: acceptance unchecked: privacyPolicyNotAccepted
    test('should return privacyPolicyNotAccepted when not accepted', () {
      expect(checkPrivacyPolicyAccepted(false), [
        AccountFieldErrorEnum.privacyPolicyNotAccepted,
      ]);
    });
  });

  group('checkSignUpFields', () {
    // REQ-011: Name "A", email "ana@", password "abc", acceptance unchecked: 6 errors in field order
    test('should return 6 errors in field order when every field is wrong', () {
      expect(
        checkSignUpFields(
          displayName: 'A',
          email: 'ana@',
          password: 'abc',
          acceptedPrivacyPolicy: false,
        ),
        [
          AccountFieldErrorEnum.displayNameLength,
          AccountFieldErrorEnum.invalidEmail,
          AccountFieldErrorEnum.passwordTooShort,
          AccountFieldErrorEnum.passwordMissingDigit,
          AccountFieldErrorEnum.passwordMissingUppercase,
          AccountFieldErrorEnum.privacyPolicyNotAccepted,
        ],
      );
    });

    // REQ-011: Name "Ana", email "ana@", password "Abcd1234", acceptance checked: only invalidEmail
    test('should return only invalidEmail when only the email is wrong', () {
      expect(
        checkSignUpFields(
          displayName: 'Ana',
          email: 'ana@',
          password: 'Abcd1234',
          acceptedPrivacyPolicy: true,
        ),
        [AccountFieldErrorEnum.invalidEmail],
      );
    });

    // REQ-011: valid data ("Ana", "ana@exemplo.com", "Abcd1234", acceptance checked): no errors
    test('should return no errors when every field is right', () {
      expect(
        checkSignUpFields(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
          acceptedPrivacyPolicy: true,
        ),
        isEmpty,
      );
    });

    // REQ-011: the returned list cannot be modified
    test('should return an unmodifiable list', () {
      final errors = checkSignUpFields(
        displayName: 'A',
        email: 'ana@',
        password: 'abc',
        acceptedPrivacyPolicy: false,
      );

      expect(
        () => errors.add(AccountFieldErrorEnum.samePassword),
        throwsUnsupportedError,
      );
    });
  });

  group('checkNewPassword', () {
    // REQ-008: current "abcd1234", new "Wxyz567" (7 characters): passwordTooShort
    test('should return passwordTooShort when new has 7 characters', () {
      expect(
        checkNewPassword(currentPassword: 'abcd1234', newPassword: 'Wxyz567'),
        [AccountFieldErrorEnum.passwordTooShort],
      );
    });

    // REQ-008: current "abcd1234", new "wxyz5678" (no uppercase): passwordMissingUppercase
    test(
      'should return passwordMissingUppercase when new has no uppercase',
      () {
        expect(
          checkNewPassword(
            currentPassword: 'abcd1234',
            newPassword: 'wxyz5678',
          ),
          [AccountFieldErrorEnum.passwordMissingUppercase],
        );
      },
    );

    // REQ-008: current "Abcd1234", new "Abcd1234": samePassword
    test('should return samePassword when new equals current', () {
      expect(
        checkNewPassword(currentPassword: 'Abcd1234', newPassword: 'Abcd1234'),
        [AccountFieldErrorEnum.samePassword],
      );
    });

    // REQ-008: current "Abcd123", new "Abcd123": passwordTooShort then samePassword
    test('should return passwordTooShort then samePassword', () {
      expect(
        checkNewPassword(currentPassword: 'Abcd123', newPassword: 'Abcd123'),
        [
          AccountFieldErrorEnum.passwordTooShort,
          AccountFieldErrorEnum.samePassword,
        ],
      );
    });

    // REQ-012: current "Abcd1234", new "Abcd1234 " (trailing space): different, no errors
    test('should not trim when comparing passwords', () {
      expect(
        checkNewPassword(currentPassword: 'Abcd1234', newPassword: 'Abcd1234 '),
        isEmpty,
      );
    });
  });

  group('checkDisplayNameChange', () {
    // REQ-006: current "Ana", new "Ana Lima": no errors
    test('should return no errors when new name differs', () {
      expect(
        checkDisplayNameChange(
          currentDisplayName: 'Ana',
          newDisplayName: 'Ana Lima',
        ),
        isEmpty,
      );
    });

    // REQ-006: current "Ana", new " Ana ": sameDisplayName
    test('should return sameDisplayName when trimmed name equals current', () {
      expect(
        checkDisplayNameChange(
          currentDisplayName: 'Ana',
          newDisplayName: ' Ana ',
        ),
        [AccountFieldErrorEnum.sameDisplayName],
      );
    });

    // REQ-006: current "Ana", new "ana": different (case counts), no errors
    test('should treat different case as a different name', () {
      expect(
        checkDisplayNameChange(
          currentDisplayName: 'Ana',
          newDisplayName: 'ana',
        ),
        isEmpty,
      );
    });

    // REQ-006: current "Ana", new "A": displayNameLength
    test('should return displayNameLength when new name has 1 character', () {
      expect(
        checkDisplayNameChange(currentDisplayName: 'Ana', newDisplayName: 'A'),
        [AccountFieldErrorEnum.displayNameLength],
      );
    });

    // REQ-006: current null (old account), new "Ana": never sameDisplayName
    test('should not return sameDisplayName when current name is null', () {
      expect(
        checkDisplayNameChange(currentDisplayName: null, newDisplayName: 'Ana'),
        isEmpty,
      );
    });

    // REQ-006: current "A", new "A": displayNameLength then sameDisplayName
    test('should return both errors when name is short and equals current', () {
      expect(
        checkDisplayNameChange(currentDisplayName: 'A', newDisplayName: 'A'),
        [
          AccountFieldErrorEnum.displayNameLength,
          AccountFieldErrorEnum.sameDisplayName,
        ],
      );
    });
  });

  group('checkEmailChange', () {
    // REQ-007: current "ana@exemplo.com", new "ana@": only invalidEmail
    test('should return only invalidEmail when new email is malformed', () {
      expect(
        checkEmailChange(currentEmail: 'ana@exemplo.com', newEmail: 'ana@'),
        [AccountFieldErrorEnum.invalidEmail],
      );
    });

    // REQ-007: current "ana@exemplo.com", new " ANA@exemplo.com ": only sameEmail
    test('should return only sameEmail when new email equals current', () {
      expect(
        checkEmailChange(
          currentEmail: 'ana@exemplo.com',
          newEmail: ' ANA@exemplo.com ',
        ),
        [AccountFieldErrorEnum.sameEmail],
      );
    });

    // REQ-007: current "ana@exemplo.com", new "ana.lima@exemplo.com": no errors
    test('should return no errors when new email is valid and different', () {
      expect(
        checkEmailChange(
          currentEmail: 'ana@exemplo.com',
          newEmail: 'ana.lima@exemplo.com',
        ),
        isEmpty,
      );
    });

    // REQ-007: the returned list cannot be changed
    test('should return an unmodifiable list', () {
      final errors = checkEmailChange(
        currentEmail: 'ana@exemplo.com',
        newEmail: 'ana@',
      );
      expect(
        () => errors.add(AccountFieldErrorEnum.sameEmail),
        throwsUnsupportedError,
      );
    });
  });
}
