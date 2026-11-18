import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/pocketbase_error_code_enum.dart';

void main() {
  test('round trips every value', () {
    for (final code in PocketBaseErrorCodeEnum.values) {
      expect(PocketBaseErrorCodeEnum.fromApi(code.apiValue), code);
    }
  });

  test('null, empty and unknown return unknown', () {
    expect(
      PocketBaseErrorCodeEnum.fromApi(null),
      PocketBaseErrorCodeEnum.unknown,
    );
    expect(
      PocketBaseErrorCodeEnum.fromApi(''),
      PocketBaseErrorCodeEnum.unknown,
    );
    expect(
      PocketBaseErrorCodeEnum.fromApi('xyz'),
      PocketBaseErrorCodeEnum.unknown,
    );
  });

  // REQ-007: validation_invalid_old_password becomes invalidOldPassword and is not a conflict
  test(
    'should parse validation_invalid_old_password and not be a conflict',
    () {
      final code = PocketBaseErrorCodeEnum.fromApi(
        'validation_invalid_old_password',
      );

      expect(code, PocketBaseErrorCodeEnum.invalidOldPassword);
      expect(code.isConflict, isFalse);
    },
  );
}
