import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('without dart-define, reports the PocketBase URL as missing', () {
      expect(AppConfig.missingKeys, contains('POCKETBASE_URL'));
      expect(AppConfig.pocketBaseUrl, isEmpty);
    });
  });
}
