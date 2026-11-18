import 'package:equatable/equatable.dart';

import '../../../../core/error/account_field_error_enum.dart';
import '../validation/account_field_rules.dart';
import 'password_rule_enum.dart';

/// Snapshot of the sign-up form with everything the screen needs already decided.
class SignUpFormEntity extends Equatable {
  const SignUpFormEntity({
    this.displayName = '',
    this.email = '',
    this.password = '',
    this.acceptedPrivacyPolicy = false,
    this.displayNameLeft = false,
    this.emailLeft = false,
  });

  final String displayName;
  final String email;
  final String password;
  final bool acceptedPrivacyPolicy;
  final bool displayNameLeft;
  final bool emailLeft;

  /// REQ-012, REQ-011: same check the use case runs on submit.
  List<AccountFieldErrorEnum> get errors => checkSignUpFields(
    displayName: displayName,
    email: email,
    password: password,
    acceptedPrivacyPolicy: acceptedPrivacyPolicy,
  );

  /// REQ-012
  List<PasswordRuleEnum> get metPasswordRules => _metRules(password);

  /// REQ-012
  bool get canSubmit => errors.isEmpty;

  /// REQ-012: shown only after the person leaves the field.
  AccountFieldErrorEnum? get displayNameWarning =>
      displayNameLeft && checkDisplayName(displayName).isNotEmpty
      ? AccountFieldErrorEnum.displayNameLength
      : null;

  /// REQ-012: shown only after the person leaves the field.
  AccountFieldErrorEnum? get emailWarning =>
      emailLeft && checkEmail(email).isNotEmpty
      ? AccountFieldErrorEnum.invalidEmail
      : null;

  /// REQ-012: shown at once; the other password errors live in the checklist.
  AccountFieldErrorEnum? get passwordWarning =>
      checkPassword(password).contains(AccountFieldErrorEnum.passwordTooLong)
      ? AccountFieldErrorEnum.passwordTooLong
      : null;

  @override
  List<Object?> get props => [
    displayName,
    email,
    password,
    acceptedPrivacyPolicy,
    displayNameLeft,
    emailLeft,
  ];
}

List<PasswordRuleEnum> _metRules(String password) => metPasswordRules(password);
