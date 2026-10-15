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
}
