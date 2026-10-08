import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/lock_screen/domain/lock_screen_rules.dart';

void main() {
  test('janela de confirmação do parar é de 5 segundos', () {
    expect(LockScreenRules.stopConfirmationWindow, const Duration(seconds: 5));
  });
}
