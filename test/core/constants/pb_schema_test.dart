import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/pb_schema.dart';

void main() {
  const collections = <String>[
    PbCollections.users,
    PbCollections.taskLists,
    PbCollections.tasks,
    PbCollections.appointments,
    PbCollections.timeEntries,
    PbCollections.recurringTasks,
    PbCollections.recurringTaskClaims,
    PbCollections.dayConfigs,
    PbCollections.activeTimers,
  ];
  const fields = <String>[
    PbFields.id,
    PbFields.user,
    PbFields.createdAt,
    PbFields.email,
    PbFields.name,
    PbFields.isDefault,
    PbFields.title,
    PbFields.list,
    PbFields.parent,
    PbFields.estimatedMinutes,
    PbFields.dueDate,
    PbFields.importance,
    PbFields.isDone,
    PbFields.hasChildren,
    PbFields.spentMinutes,
    PbFields.recurringTaskId,
    PbFields.listId,
    PbFields.date,
    PbFields.startMinute,
    PbFields.durationMinutes,
    PbFields.targetId,
    PbFields.targetType,
    PbFields.origin,
    PbFields.minutes,
    PbFields.occurredAt,
    PbFields.weekdays,
    PbFields.lastGeneratedOn,
    PbFields.recurringTask,
    PbFields.availableMinutesPerDay,
    PbFields.onboarded,
    PbFields.status,
    PbFields.startedAt,
  ];

  final migration = File(
    'pocketbase/pb_migrations/1792900000_init_schema.js',
  ).readAsStringSync();

  bool quoted(String value) =>
      migration.contains("'$value'") || migration.contains('"$value"');

  group('pb_schema', () {
    test('collections and fields appear in the init migration', () {
      const builtIn = {'users', 'id', 'email'};
      for (final value in [...collections, ...fields]) {
        if (builtIn.contains(value)) continue;
        expect(quoted(value), isTrue, reason: '$value not in migration');
      }
    });

    test('every name is snake_case', () {
      final snake = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final value in [...collections, ...fields]) {
        expect(snake.hasMatch(value), isTrue, reason: value);
      }
    });

    test('increment appends the plus modifier', () {
      expect(PbFields.increment(PbFields.spentMinutes), 'spent_minutes+');
    });
  });
}
