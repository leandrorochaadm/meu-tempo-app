import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/auth/domain/entities/password_rule_enum.dart';

void main() {
  // REQ-003: "1" meets only the digit rule
  test('should meet only digit for "1"', () {
    expect(PasswordRuleEnum.digit.isMetBy('1'), isTrue);
    expect(PasswordRuleEnum.uppercase.isMetBy('1'), isFalse);
    expect(PasswordRuleEnum.lowercase.isMetBy('1'), isFalse);
    expect(PasswordRuleEnum.minLength.isMetBy('1'), isFalse);
  });

  // REQ-003: "É" (accented uppercase) meets only the uppercase rule
  test('should meet only uppercase for "É"', () {
    expect(PasswordRuleEnum.uppercase.isMetBy('É'), isTrue);
    expect(PasswordRuleEnum.lowercase.isMetBy('É'), isFalse);
    expect(PasswordRuleEnum.digit.isMetBy('É'), isFalse);
  });

  // REQ-003: "é" (accented lowercase) meets only the lowercase rule
  test('should meet only lowercase for "é"', () {
    expect(PasswordRuleEnum.lowercase.isMetBy('é'), isTrue);
    expect(PasswordRuleEnum.uppercase.isMetBy('é'), isFalse);
    expect(PasswordRuleEnum.digit.isMetBy('é'), isFalse);
  });

  // REQ-003: Arabic-Indic digits "١٢٣" do not meet the digit rule (only 0 to 9 count)
  test('should not meet digit for Arabic-Indic digits', () {
    expect(PasswordRuleEnum.digit.isMetBy('١٢٣'), isFalse);
  });

  // REQ-003: 8 characters meet minLength, 7 do not
  test('should meet minLength at 8 characters and not at 7', () {
    expect(PasswordRuleEnum.minLength.isMetBy('a' * 8), isTrue);
    expect(PasswordRuleEnum.minLength.isMetBy('a' * 7), isFalse);
  });

  // REQ-003: spaces count as characters and meet no letter or digit rule
  test('should count spaces for minLength only', () {
    expect(PasswordRuleEnum.minLength.isMetBy(' ' * 8), isTrue);
    expect(PasswordRuleEnum.digit.isMetBy(' ' * 8), isFalse);
    expect(PasswordRuleEnum.uppercase.isMetBy(' ' * 8), isFalse);
    expect(PasswordRuleEnum.lowercase.isMetBy(' ' * 8), isFalse);
  });

  // REQ-003: "Abc" meets 2 rules (uppercase, lowercase)
  test('should meet uppercase and lowercase for "Abc"', () {
    final met = PasswordRuleEnum.values.where((r) => r.isMetBy('Abc'));
    expect(met, {PasswordRuleEnum.uppercase, PasswordRuleEnum.lowercase});
  });

  // REQ-012: password "abc" meets 1 rule (lowercase)
  test('should meet only lowercase when password is abc', () {
    expect(metPasswordRules('abc'), [PasswordRuleEnum.lowercase]);
  });

  // REQ-012: password "Abc" meets 2 rules (uppercase, lowercase)
  test('should meet uppercase and lowercase when password is Abc', () {
    expect(metPasswordRules('Abc'), [
      PasswordRuleEnum.uppercase,
      PasswordRuleEnum.lowercase,
    ]);
  });

  // REQ-012: password "Abcdefg" (7 characters) meets 2 rules and not minLength
  test('should not meet minLength when password has 7 characters', () {
    final met = metPasswordRules('Abcdefg');
    expect(met, [PasswordRuleEnum.uppercase, PasswordRuleEnum.lowercase]);
    expect(met, isNot(contains(PasswordRuleEnum.minLength)));
  });

  // REQ-012: password "Abcdefgh" (8 characters) meets 3 rules and not digit
  test('should meet 3 rules without digit when password is Abcdefgh', () {
    final met = metPasswordRules('Abcdefgh');
    expect(met, [
      PasswordRuleEnum.minLength,
      PasswordRuleEnum.uppercase,
      PasswordRuleEnum.lowercase,
    ]);
    expect(met, isNot(contains(PasswordRuleEnum.digit)));
  });

  // REQ-012: password "Abcdefg1" meets all 4 rules, in enum order
  test('should meet all 4 rules when password is Abcdefg1', () {
    expect(metPasswordRules('Abcdefg1'), [
      PasswordRuleEnum.minLength,
      PasswordRuleEnum.digit,
      PasswordRuleEnum.uppercase,
      PasswordRuleEnum.lowercase,
    ]);
  });

  // REQ-012: empty password meets 0 rules
  test('should meet no rule when password is empty', () {
    expect(metPasswordRules(''), isEmpty);
  });

  // REQ-012: the list of met rules cannot be changed
  test('should return an unmodifiable list of met rules', () {
    expect(
      () => metPasswordRules('Abc').add(PasswordRuleEnum.digit),
      throwsUnsupportedError,
    );
  });
}
