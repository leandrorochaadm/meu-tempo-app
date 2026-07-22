import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/utils/formatters/duration_formatter.dart';

void main() {
  group('DurationFormatter.hms', () {
    test('zero → 00:00:00', () {
      expect(DurationFormatter.hms(0), '00:00:00');
    });

    test('só segundos → 00:00:05', () {
      expect(DurationFormatter.hms(5), '00:00:05');
    });

    test('menos de 1 hora → 00:01:05', () {
      expect(DurationFormatter.hms(65), '00:01:05');
    });

    test('mais de 1 hora → 01:01:01', () {
      expect(DurationFormatter.hms(3661), '01:01:01');
    });

    test('negativo é tratado como zero', () {
      expect(DurationFormatter.hms(-10), '00:00:00');
    });
  });
}
