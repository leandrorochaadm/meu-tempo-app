import '../domain/entities/password_rule_enum.dart';

extension PasswordRuleLabel on PasswordRuleEnum {
  String get label => switch (this) {
    PasswordRuleEnum.minLength => 'Pelo menos 8 caracteres',
    PasswordRuleEnum.digit => 'Pelo menos 1 número',
    PasswordRuleEnum.uppercase => 'Pelo menos 1 letra maiúscula',
    PasswordRuleEnum.lowercase => 'Pelo menos 1 letra minúscula',
  };
}
