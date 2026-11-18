import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/exceptions.dart';

void main() {
  // REQ-005: EmailAlreadyInUseException becomes EmailAlreadyInUseFailure and is a ConflictException
  test(
    'should convert to EmailAlreadyInUseFailure and be a ConflictException',
    () {
      const exception = EmailAlreadyInUseException();

      expect(exception.toFailure(), const EmailAlreadyInUseFailure());
      expect(exception, isA<ConflictException>());
    },
  );
}
