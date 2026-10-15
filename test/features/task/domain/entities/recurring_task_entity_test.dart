import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';

RecurringTaskEntity build({
  Set<WeekdayEnum> weekdays = const {
    WeekdayEnum.monday,
    WeekdayEnum.wednesday,
    WeekdayEnum.friday,
  },
  DateTime? lastGeneratedOn,
}) => RecurringTaskEntity(
  id: 'r1',
  title: 'Academia',
  listId: 'l1',
  estimatedMinutes: 60,
  importance: ImportanceEnum.high,
  weekdays: weekdays,
  createdAt: DateTime(2026, 10, 1),
  lastGeneratedOn: lastGeneratedOn,
);

void main() {
  test('should be due when weekday matches', () {
    final entity = build();

    expect(entity.isScheduled, isTrue);
    expect(entity.isDueOn(DateTime(2026, 10, 12)), isTrue); // Monday
    expect(entity.isDueOn(DateTime(2026, 10, 13)), isFalse); // Tuesday
  });

  test('should not be due when unscheduled', () {
    final entity = build(weekdays: {});

    expect(entity.isScheduled, isFalse);
    for (var i = 0; i < 7; i++) {
      expect(entity.isDueOn(DateTime(2026, 10, 12 + i)), isFalse);
    }
  });

  test('isEveryDay should be true only with 7 days', () {
    expect(build(weekdays: WeekdayEnum.values.toSet()).isEveryDay, isTrue);
    expect(
      build(weekdays: WeekdayEnum.values.take(6).toSet()).isEveryDay,
      isFalse,
    );
    expect(build(weekdays: {}).isEveryDay, isFalse);
  });

  test('wasGeneratedOn should ignore time of day', () {
    final entity = build(lastGeneratedOn: DateTime(2026, 10, 12));

    expect(entity.wasGeneratedOn(DateTime(2026, 10, 12, 23, 59)), isTrue);
    expect(entity.wasGeneratedOn(DateTime(2026, 10, 13)), isFalse);
    expect(build().wasGeneratedOn(DateTime(2026, 10, 12)), isFalse);
  });

  test('weekdays should be unmodifiable', () {
    final entity = build();

    expect(
      () => entity.weekdays.add(WeekdayEnum.sunday),
      throwsUnsupportedError,
    );
  });

  test('equality should consider all fields', () {
    final a = build(
      weekdays: {WeekdayEnum.monday, WeekdayEnum.friday},
      lastGeneratedOn: DateTime(2026, 10, 12),
    );
    final sameDaysOtherOrder = build(
      weekdays: {WeekdayEnum.friday, WeekdayEnum.monday},
      lastGeneratedOn: DateTime(2026, 10, 12),
    );
    final otherGeneration = build(
      weekdays: {WeekdayEnum.monday, WeekdayEnum.friday},
      lastGeneratedOn: DateTime(2026, 10, 13),
    );

    expect(a, equals(sameDaysOtherOrder));
    expect(a, isNot(equals(otherGeneration)));
  });
}
