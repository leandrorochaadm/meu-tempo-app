import 'package:characters/characters.dart';

import '../../../../core/error/account_field_error_enum.dart';
import '../entities/password_rule_enum.dart';
import '../usecases/normalize_email.dart';

const int displayNameMinLength = 2; // REQ-002
const int displayNameMaxLength = 50; // REQ-002

/// Checks the display name length, counting characters as the person sees them.
List<AccountFieldErrorEnum> checkDisplayName(String displayName) {
  // REQ-002
  final length = displayName.trim().characters.length;
  if (length < displayNameMinLength || length > displayNameMaxLength) {
    return const [AccountFieldErrorEnum.displayNameLength];
  }
  return const [];
}

const String _emailAtSign = '@';
const String _emailDot = '.';
const String _emailDoubleDot = '..';
final RegExp _whitespace = RegExp(r'\s');

/// Checks the e-mail format after normalizing it.
List<AccountFieldErrorEnum> checkEmail(String email) {
  // REQ-005: normalize before checking.
  final normalized = normalizeEmail(email);
  // REQ-010
  final parts = normalized.split(_emailAtSign);
  final valid =
      parts.length == 2 &&
      parts[0].isNotEmpty &&
      parts[1].contains(_emailDot) &&
      !parts[1].startsWith(_emailDot) &&
      !parts[1].endsWith(_emailDot) &&
      !_whitespace.hasMatch(normalized) &&
      !normalized.contains(_emailDoubleDot);
  return valid ? const [] : const [AccountFieldErrorEnum.invalidEmail];
}

/// Checks the password as typed (no trim): length from 8 to 71, a digit, an uppercase and a lowercase letter.
List<AccountFieldErrorEnum> checkPassword(String password) {
  // REQ-003
  final errors = <AccountFieldErrorEnum>[];
  for (final rule in PasswordRuleEnum.values) {
    if (!rule.isMetBy(password)) errors.add(_errorFor(rule));
    if (rule == PasswordRuleEnum.minLength &&
        passwordLength(password) > passwordMaxLength) {
      errors.add(AccountFieldErrorEnum.passwordTooLong);
    }
  }
  return errors;
}

AccountFieldErrorEnum _errorFor(PasswordRuleEnum rule) => switch (rule) {
  PasswordRuleEnum.minLength => AccountFieldErrorEnum.passwordTooShort,
  PasswordRuleEnum.digit => AccountFieldErrorEnum.passwordMissingDigit,
  PasswordRuleEnum.uppercase => AccountFieldErrorEnum.passwordMissingUppercase,
  PasswordRuleEnum.lowercase => AccountFieldErrorEnum.passwordMissingLowercase,
};

/// Checks the privacy policy box.
List<AccountFieldErrorEnum> checkPrivacyPolicyAccepted(bool accepted) {
  // REQ-004
  return accepted
      ? const []
      : const [AccountFieldErrorEnum.privacyPolicyNotAccepted];
}

/// Checks every sign-up field at once, in screen order. Empty when all fields are right.
// REQ-011
List<AccountFieldErrorEnum> checkSignUpFields({
  required String displayName,
  required String email,
  required String password,
  required bool acceptedPrivacyPolicy,
}) => List.unmodifiable([
  ...checkDisplayName(displayName),
  ...checkEmail(email),
  ...checkPassword(password),
  ...checkPrivacyPolicyAccepted(acceptedPrivacyPolicy),
]);

/// Checks the new password of the change-password form: the sign-up rules plus "not the current one".
/// The current password is never checked against the rules (old accounts may break them).
// REQ-003, REQ-008, REQ-011
List<AccountFieldErrorEnum> checkNewPassword({
  required String currentPassword,
  required String newPassword,
}) => List.unmodifiable([
  ...checkPassword(newPassword),
  if (newPassword == currentPassword) AccountFieldErrorEnum.samePassword,
]);
