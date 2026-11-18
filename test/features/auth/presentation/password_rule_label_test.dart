import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/auth/domain/entities/password_rule_enum.dart';
import 'package:meu_tempo/features/auth/presentation/password_rule_label.dart';

void main() {
  // REQ-012: each password rule has the checklist text, in this order
  test('should label each password rule', () {
    expect(PasswordRuleEnum.values.map((r) => r.label).toList(), [
      'Pelo menos 8 caracteres',
      'Pelo menos 1 número',
      'Pelo menos 1 letra maiúscula',
      'Pelo menos 1 letra minúscula',
    ]);
  });
}
