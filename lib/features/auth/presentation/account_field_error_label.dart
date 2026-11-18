import '../../../core/error/account_field_error_enum.dart';

/// Screen text of each account field error.
extension AccountFieldErrorLabel on AccountFieldErrorEnum {
  String get label => switch (this) {
    AccountFieldErrorEnum.displayNameLength => 'Use de 2 a 50 caracteres.',
    AccountFieldErrorEnum.sameDisplayName => 'Esse já é o seu nome.',
    AccountFieldErrorEnum.invalidEmail => 'Confira o e-mail.',
    AccountFieldErrorEnum.sameEmail => 'Esse já é o seu e-mail.',
    AccountFieldErrorEnum.passwordTooShort => 'Pelo menos 8 caracteres',
    AccountFieldErrorEnum.passwordTooLong => 'Use no máximo 71 caracteres.',
    AccountFieldErrorEnum.passwordMissingDigit => 'Pelo menos 1 número',
    AccountFieldErrorEnum.passwordMissingUppercase =>
      'Pelo menos 1 letra maiúscula',
    AccountFieldErrorEnum.passwordMissingLowercase =>
      'Pelo menos 1 letra minúscula',
    AccountFieldErrorEnum.samePassword => 'É igual à senha atual.',
    AccountFieldErrorEnum.privacyPolicyNotAccepted => 'Marque para continuar.',
  };
}
