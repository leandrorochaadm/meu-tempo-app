import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:meu_tempo/features/task/presentation/widgets/recurring_task_presentation.dart';

void main() {
  RecurringTaskEntity template(Set<WeekdayEnum> weekdays) =>
      RecurringTaskEntity(
        id: 'r1',
        title: 'Academia',
        listId: 'work',
        estimatedMinutes: 60,
        importance: ImportanceEnum.high,
        weekdays: weekdays,
        createdAt: DateTime(2026, 10, 1),
      );

  test('scheduleLabel should list days Monday-first', () {
    final t = template({
      WeekdayEnum.friday,
      WeekdayEnum.monday,
      WeekdayEnum.wednesday,
    });

    expect(t.scheduleLabel, 'Seg · Qua · Sex');
  });

  test('scheduleLabel should be Todo dia with 7 days', () {
    final t = template(WeekdayEnum.values.toSet());

    expect(t.scheduleLabel, 'Todo dia');
  });

  test('scheduleLabel should be Sem dia fixo without days', () {
    final t = template({});

    expect(t.scheduleLabel, 'Sem dia fixo');
  });
}
