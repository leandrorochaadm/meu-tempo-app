import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/auth/domain/usecases/normalize_email.dart';

void main() {
  // REQ-001: normalizeEmail(" Ana@Exemplo.com ") / "ana@exemplo.com" / "" gives "ana@exemplo.com" / same / ""
  test('should trim and lowercase email', () {
    expect(normalizeEmail(' Ana@Exemplo.com '), 'ana@exemplo.com');
    expect(normalizeEmail('ana@exemplo.com'), 'ana@exemplo.com');
    expect(normalizeEmail(''), '');
  });
}
