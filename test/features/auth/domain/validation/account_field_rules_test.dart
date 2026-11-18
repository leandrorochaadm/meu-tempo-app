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
}
