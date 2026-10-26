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
}
