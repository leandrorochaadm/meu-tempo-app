import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/data/models/recurring_task_model.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:pocketbase/pocketbase.dart';

Map<String, dynamic> _json([Map<String, dynamic> overrides = const {}]) => {
  'id': 'r1',
  'collectionId': 'pbc_2',
  'collectionName': 'recurring_tasks',
  'user': 'user-a',
  'title': 'Academia',
  'list': 'l1',
  'estimated_minutes': 60,
  'importance': 'high',
  'weekdays': ['monday', 'wednesday', 'friday'],
  'created_at': '2026-10-01 03:00:00.000Z',
  'last_generated_on': '2026-10-12 00:00:00.000Z',
  ...overrides,
};

RecurringTaskModel _record([Map<String, dynamic> overrides = const {}]) =>
    RecurringTaskModel.fromRecord(RecordModel.fromJson(_json(overrides)));

RecurringTaskEntity _entity({DateTime? lastGeneratedOn}) => RecurringTaskEntity(
  id: 'r1',
  title: 'Academia',
  listId: 'l1',
  estimatedMinutes: 60,
  importance: ImportanceEnum.high,
  weekdays: {WeekdayEnum.friday, WeekdayEnum.monday},
  createdAt: DateTime.utc(2026, 10, 1, 3),
  lastGeneratedOn: lastGeneratedOn,
);

void main() {
  test('reads a full record', () {
    expect(
      _record().toEntity(),
      RecurringTaskEntity(
        id: 'r1',
        title: 'Academia',
        listId: 'l1',
        estimatedMinutes: 60,
        importance: ImportanceEnum.high,
        weekdays: {
          WeekdayEnum.monday,
          WeekdayEnum.wednesday,
          WeekdayEnum.friday,
        },
        createdAt: DateTime.utc(2026, 10, 1, 3).toLocal(),
        lastGeneratedOn: DateTime(2026, 10, 12),
      ),
    );
  });

  test('reads dates with T separator', () {
    final e = _record({
      'created_at': '2026-10-01T03:00:00.000Z',
      'last_generated_on': '2026-10-12T00:00:00.000Z',
    }).toEntity();
    expect(e.createdAt, DateTime.utc(2026, 10, 1, 3).toLocal());
    expect(e.lastGeneratedOn, DateTime(2026, 10, 12));
  });

  test('missing, null and empty weekdays mean no fixed day', () {
    final missing = _json()..remove('weekdays');
    expect(
      RecurringTaskModel.fromRecord(
        RecordModel.fromJson(missing),
      ).toEntity().weekdays,
      isEmpty,
    );
    expect(_record({'weekdays': null}).toEntity().weekdays, isEmpty);
    expect(_record({'weekdays': <String>[]}).toEntity().weekdays, isEmpty);
  });

  test('empty values fall back', () {
    final e = _record({'last_generated_on': '', 'created_at': ''}).toEntity();
    expect(e.lastGeneratedOn, isNull);
    expect(e.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    final missing = _json()..remove('estimated_minutes');
    expect(
      RecurringTaskModel.fromRecord(
        RecordModel.fromJson(missing),
      ).toEntity().estimatedMinutes,
      0,
    );
  });

  test('blank, missing or unknown importance throws on toEntity', () {
    for (final value in ['', 'urgent']) {
      final model = _record({'importance': value});
      expect(model.toEntity, throwsFormatException);
    }
    final missing = _json()..remove('importance');
    final model = RecurringTaskModel.fromRecord(RecordModel.fromJson(missing));
    expect(model.toEntity, throwsFormatException);
  });

  test('invalid weekday items throw on toEntity', () {
    for (final value in [
      ['monday', 'funday'],
      ['monday', ''],
      [1],
    ]) {
      expect(_record({'weekdays': value}).toEntity, throwsFormatException);
    }
  });

  test('weekdays that is not a list throws on fromRecord', () {
    expect(() => _record({'weekdays': 'monday'}), throwsFormatException);
  });

  test('toJson writes exactly the stored keys', () {
    final json = RecurringTaskModel.fromEntity(
      _entity(lastGeneratedOn: DateTime(2026, 10, 12)),
    ).toJson();
    expect(json, {
      'title': 'Academia',
      'list': 'l1',
      'estimated_minutes': 60,
      'importance': 'high',
      'weekdays': ['monday', 'friday'],
      'created_at': '2026-10-01 03:00:00.000Z',
      'last_generated_on': '2026-10-12 00:00:00.000Z',
    });
  });

  test('null lastGeneratedOn is written as null', () {
    final json = RecurringTaskModel.fromEntity(_entity()).toJson();
    expect(json.containsKey('last_generated_on'), isTrue);
    expect(json['last_generated_on'], isNull);
  });

  test('entity round-trips', () {
    for (final e in [
      _entity(),
      _entity(lastGeneratedOn: DateTime(2026, 10, 12)),
    ]) {
      expect(RecurringTaskModel.fromEntity(e).toEntity(), e);
    }
  });

  test('public constructor stores the external text', () {
    final model = RecurringTaskModel(
      id: 'r1',
      title: 'x',
      listId: 'l1',
      estimatedMinutes: 10,
      importance: ImportanceEnum.low,
      weekdays: const [WeekdayEnum.sunday],
    );
    expect(model.importance, 'low');
    expect(model.weekdays, ['sunday']);
  });
}
