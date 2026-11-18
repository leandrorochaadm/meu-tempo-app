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
}
