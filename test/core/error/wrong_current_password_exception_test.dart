import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/exceptions.dart';

void main() {
  // REQ-007: WrongCurrentPasswordException becomes WrongCurrentPasswordFailure
  test('should convert to WrongCurrentPasswordFailure', () {
    expect(
      const WrongCurrentPasswordException().toFailure(),
      const WrongCurrentPasswordFailure(),
    );
  });
}
