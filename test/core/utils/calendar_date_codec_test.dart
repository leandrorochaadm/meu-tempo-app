import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/utils/calendar_date_codec.dart';

void main() {
  group('CalendarDateCodec', () {
    test('format writes midnight UTC of the given day', () {
      expect(
        CalendarDateCodec.format(DateTime(2026, 12, 31)),
        '2026-12-31 00:00:00.000Z',
      );
      expect(
        CalendarDateCodec.format(DateTime(2027, 1, 1)),
        '2027-01-01 00:00:00.000Z',
      );
      expect(
        CalendarDateCodec.format(DateTime(2026, 10, 24, 23, 59)),
        '2026-10-24 00:00:00.000Z',
      );
    });

    test('parse accepts space and T', () {
      for (final raw in [
        '2026-12-31 00:00:00.000Z',
        '2026-12-31T00:00:00.000Z',
      ]) {
        final day = CalendarDateCodec.parse(raw);
        expect(day, DateTime(2026, 12, 31));
        expect(day.isUtc, isFalse);
        expect(day.hour, 0);
      }
    });

    test('round trip on year boundaries', () {
      for (final day in [DateTime(2026, 12, 31), DateTime(2027, 1, 1)]) {
        expect(CalendarDateCodec.parse(CalendarDateCodec.format(day)), day);
      }
    });

    test('parse rejects invalid text', () {
      for (final raw in [
        '',
        '2026-10-24',
        '2026-10-24 03:00:00.000Z',
        '2026-10-24 00:00:00.000+00:00',
        '2026-02-30 00:00:00.000Z',
      ]) {
        expect(
          () => CalendarDateCodec.parse(raw),
          throwsFormatException,
          reason: raw,
        );
      }
    });

    test(
      'parse keeps the day in Brasília time zone',
      () {
        expect(
          CalendarDateCodec.parse('2026-12-31 00:00:00.000Z'),
          DateTime(2026, 12, 31),
        );
      },
      skip: DateTime(2026, 12, 31).timeZoneOffset != const Duration(hours: -3),
    );
  });

  group('CalendarDateConverter', () {
    const converter = CalendarDateConverter();

    test('null and empty', () {
      expect(converter.fromJson(null), isNull);
      expect(converter.fromJson(''), isNull);
      expect(converter.toJson(null), isNull);
    });

    test('round trip', () {
      final day = DateTime(2026, 10, 24);
      expect(converter.fromJson(converter.toJson(day)), day);
    });
  });
}
