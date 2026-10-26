import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/utils/instant_codec.dart';

void main() {
  final isBrasilia =
      DateTime(2026, 10, 24).timeZoneOffset == const Duration(hours: -3);

  group('InstantCodec', () {
    test('format uses UTC with 3 millisecond digits', () {
      expect(
        InstantCodec.format(DateTime.utc(2026, 10, 25, 0, 30, 5, 7, 999)),
        '2026-10-25 00:30:05.007Z',
      );
    });

    test('round trip returns a local instant', () {
      final instant = DateTime(2026, 10, 24, 21, 30);
      final back = InstantCodec.parse(InstantCodec.format(instant));
      expect(back.isAtSameMomentAs(instant), isTrue);
      expect(back.isUtc, isFalse);
    });

    test('parse accepts space and T', () {
      final a = InstantCodec.parse('2026-10-25 00:30:00.000Z');
      final b = InstantCodec.parse('2026-10-25T00:30:00.000Z');
      expect(a.isAtSameMomentAs(b), isTrue);
    });

    test('parse rejects invalid text', () {
      for (final raw in [
        '',
        '2026-10-24 21:30:00.000',
        '2026-10-24 21:30:00.000+00:00',
      ]) {
        expect(
          () => InstantCodec.parse(raw),
          throwsFormatException,
          reason: raw,
        );
      }
    });

    test('Brasília time zone', () {
      expect(
        InstantCodec.format(DateTime(2026, 10, 24, 21, 30)),
        '2026-10-25 00:30:00.000Z',
      );
      expect(
        InstantCodec.parse('2026-10-25 00:30:00.000Z'),
        DateTime(2026, 10, 24, 21, 30),
      );
    }, skip: !isBrasilia);
  });

  group('InstantConverter', () {
    const converter = InstantConverter();

    test('null and empty', () {
      expect(converter.fromJson(null), isNull);
      expect(converter.fromJson(''), isNull);
      expect(converter.toJson(null), isNull);
    });
  });
}
