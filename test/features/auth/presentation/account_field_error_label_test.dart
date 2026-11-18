import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/features/auth/presentation/account_field_error_label.dart';

void main() {
  // REQ-002: every AccountFieldErrorEnum value has its wireframe text (displayNameLength: "Use de 2 a 50 caracteres.")
  test('should map every AccountFieldErrorEnum to its wireframe text', () {
    const expected = {
      AccountFieldErrorEnum.displayNameLength: 'Use de 2 a 50 caracteres.',
      AccountFieldErrorEnum.sameDisplayName: 'Esse já é o seu nome.',
      AccountFieldErrorEnum.invalidEmail: 'Confira o e-mail.',
      AccountFieldErrorEnum.sameEmail: 'Esse já é o seu e-mail.',
      AccountFieldErrorEnum.passwordTooShort: 'Pelo menos 8 caracteres',
      AccountFieldErrorEnum.passwordTooLong: 'Use no máximo 71 caracteres.',
      AccountFieldErrorEnum.passwordMissingDigit: 'Pelo menos 1 número',
      AccountFieldErrorEnum.passwordMissingUppercase:
          'Pelo menos 1 letra maiúscula',
      AccountFieldErrorEnum.passwordMissingLowercase:
          'Pelo menos 1 letra minúscula',
      AccountFieldErrorEnum.samePassword: 'É igual à senha atual.',
      AccountFieldErrorEnum.privacyPolicyNotAccepted: 'Marque para continuar.',
    };

    expect(AccountFieldErrorEnum.values.length, 11);
    for (final error in AccountFieldErrorEnum.values) {
      expect(error.label, expected[error], reason: error.name);
    }
  });
}
