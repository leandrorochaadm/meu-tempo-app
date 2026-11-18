import 'package:equatable/equatable.dart';

import '../../../../core/error/account_field_error_enum.dart';
import '../validation/account_field_rules.dart';
import 'password_rule_enum.dart';

/// Snapshot of the change-password form with everything the screen needs already decided.
class ChangePasswordFormEntity extends Equatable {
  const ChangePasswordFormEntity({
    this.currentPassword = '',
    this.newPassword = '',
  });

  final String currentPassword;
  final String newPassword;

  /// REQ-012, REQ-008: same check the use case runs on submit.
  List<AccountFieldErrorEnum> get errors => checkNewPassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  /// REQ-012
  List<PasswordRuleEnum> get metPasswordRules => _metRules(newPassword);

  /// REQ-012: the current password is not trimmed; only spaces counts as filled.
  bool get canSubmit => currentPassword.isNotEmpty && errors.isEmpty;

  /// REQ-012: too long wins over same password; criteria errors live in the checklist only.
  AccountFieldErrorEnum? get newPasswordWarning {
    final all = errors;
    if (all.contains(AccountFieldErrorEnum.passwordTooLong)) {
      return AccountFieldErrorEnum.passwordTooLong;
    }
    if (newPassword.isNotEmpty &&
        all.contains(AccountFieldErrorEnum.samePassword)) {
      return AccountFieldErrorEnum.samePassword;
    }
    return null;
  }

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

List<PasswordRuleEnum> _metRules(String password) => metPasswordRules(password);
