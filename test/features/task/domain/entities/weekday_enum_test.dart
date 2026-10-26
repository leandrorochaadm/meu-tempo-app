import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';

void main() {
  test('fromDate should map all 7 days', () {
    const expected = [
      WeekdayEnum.monday,
      WeekdayEnum.tuesday,
      WeekdayEnum.wednesday,
      WeekdayEnum.thursday,
      WeekdayEnum.friday,
      WeekdayEnum.saturday,
      WeekdayEnum.sunday,
    ];

    for (var i = 0; i < expected.length; i++) {
      // 12/10/2026 is a Monday.
      expect(WeekdayEnum.fromDate(DateTime(2026, 10, 12 + i)), expected[i]);
    }
  });

  test('isoValue should match DateTime constants', () {
    expect(WeekdayEnum.monday.isoValue, DateTime.monday);
    expect(WeekdayEnum.sunday.isoValue, DateTime.sunday);
  });

  test('apiValue of the 7 days', () {
    expect(WeekdayEnum.values.map((d) => d.apiValue), [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ]);
  });

  test('fromApi reads each spelling back', () {
    for (final day in WeekdayEnum.values) {
      expect(WeekdayEnum.fromApi(day.apiValue), day);
    }
  });

  test('fromApi unknown or missing returns null', () {
    expect(WeekdayEnum.fromApi(null), isNull);
    expect(WeekdayEnum.fromApi(''), isNull);
    expect(WeekdayEnum.fromApi('Monday'), isNull);
    expect(WeekdayEnum.fromApi('mon'), isNull);
  });
}
