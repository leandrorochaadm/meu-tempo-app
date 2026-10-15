import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/data/models/recurring_task_model.dart';
import 'package:meu_tempo/features/task/data/recurring_task_fields.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';

void main() {
  RecurringTaskEntity entity({
    Set<WeekdayEnum> weekdays = const {WeekdayEnum.friday, WeekdayEnum.monday},
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

  test('fromDoc should map raw payload to entity', () {
    final raw = <String, dynamic>{
      RecurringTaskFields.title: 'Academia',
      RecurringTaskFields.listId: 'l1',
      'estimatedMinutes': 60,
      'importance': 'high',
      'weekdays': ['monday', 'wednesday', 'friday'],
      'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
      RecurringTaskFields.lastGeneratedOn: Timestamp.fromDate(
        DateTime(2026, 10, 12),
      ),
    };

    expect(
      RecurringTaskModel.fromDoc('r1', raw).toEntity(),
      entity(
        weekdays: {
          WeekdayEnum.monday,
          WeekdayEnum.wednesday,
          WeekdayEnum.friday,
        },
        lastGeneratedOn: DateTime(2026, 10, 12),
      ),
    );
  });

  test('toJson should write weekdays by name in week order and omit id', () {
    final json = RecurringTaskModel.fromEntity(entity()).toJson();

    expect(json['weekdays'], ['monday', 'friday']);
    expect(json.containsKey('id'), isFalse);
  });

  test('toJson should omit lastGeneratedOn when null', () {
    final json = RecurringTaskModel.fromEntity(entity()).toJson();

    expect(json.containsKey(RecurringTaskFields.lastGeneratedOn), isFalse);
  });

  test('missing weekdays should read as unscheduled', () {
    final raw = <String, dynamic>{
      RecurringTaskFields.title: 'Reunião',
      RecurringTaskFields.listId: 'l1',
      'estimatedMinutes': 30,
      'importance': 'high',
      'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
    };

    expect(RecurringTaskModel.fromDoc('r2', raw).toEntity().weekdays, isEmpty);
  });

  test('round-trip should preserve the entity', () {
    for (final e in [
      entity(),
      entity(lastGeneratedOn: DateTime(2026, 10, 12)),
    ]) {
      final json = RecurringTaskModel.fromEntity(e).toJson()..['id'] = e.id;

      expect(RecurringTaskModel.fromJson(json).toEntity(), e);
    }
  });
}
