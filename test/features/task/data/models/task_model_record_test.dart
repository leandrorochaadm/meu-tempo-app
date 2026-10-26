import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/data/models/task_model.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:pocketbase/pocketbase.dart';

Map<String, dynamic> _json([Map<String, dynamic> overrides = const {}]) => {
  'id': 'abc123def456ghi',
  'collectionId': 'pbc_1',
  'collectionName': 'tasks',
  'user': 'user-a',
  'title': 'Regar plantas',
  'list': 'l1',
  'parent': 'p1',
  'created_at': '2026-10-15 11:00:00.000Z',
  'estimated_minutes': 30,
  'due_date': '2026-10-24 00:00:00.000Z',
  'importance': 'high',
  'is_done': true,
  'has_children': false,
  'spent_minutes': 12,
  'recurring_task_id': 'r1',
  ...overrides,
};

TaskEntity _read([Map<String, dynamic> overrides = const {}]) =>
    TaskModel.fromRecord(RecordModel.fromJson(_json(overrides))).toEntity();

void main() {
  test('reads a full record', () {
    final e = _read();
    expect(e.id, 'abc123def456ghi');
    expect(e.listId, 'l1');
    expect(e.parentId, 'p1');
    expect(e.createdAt, DateTime.utc(2026, 10, 15, 11).toLocal());
    expect(e.estimatedMinutes, 30);
    expect(e.dueDate, DateTime(2026, 10, 24));
    expect(e.importance, ImportanceEnum.high);
    expect(e.isDone, isTrue);
    expect(e.spentMinutes, 12);
    expect(e.recurringTaskId, 'r1');
  });

  test('blank relations read as null', () {
    final e = _read({'parent': '', 'recurring_task_id': ''});
    expect(e.parentId, isNull);
    expect(e.recurringTaskId, isNull);
  });

  test('handles empty and numeric values', () {
    expect(_read({'estimated_minutes': null}).estimatedMinutes, isNull);
    expect(_read({'estimated_minutes': 30.0}).estimatedMinutes, 30);
    expect(_read({'due_date': ''}).dueDate, isNull);
    expect(
      _read({'created_at': ''}).createdAt,
      DateTime.fromMillisecondsSinceEpoch(0),
    );
  });

  test('missing flags use defaults', () {
    final record = _json()
      ..remove('is_done')
      ..remove('has_children')
      ..remove('spent_minutes');
    final e = TaskModel.fromRecord(RecordModel.fromJson(record)).toEntity();
    expect(e.isDone, isFalse);
    expect(e.hasChildren, isFalse);
    expect(e.spentMinutes, 0);
  });

  test('accepts dates with T separator', () {
    final e = _read({
      'created_at': '2026-10-15T11:00:00.000Z',
      'due_date': '2026-10-24T00:00:00.000Z',
    });
    expect(e.createdAt, DateTime.utc(2026, 10, 15, 11).toLocal());
    expect(e.dueDate, DateTime(2026, 10, 24));
  });

  test('importance: blank or missing is null, unknown throws on toEntity', () {
    expect(_read({'importance': ''}).importance, isNull);
    final record = _json()..remove('importance');
    expect(
      TaskModel.fromRecord(RecordModel.fromJson(record)).toEntity().importance,
      isNull,
    );
    final model = TaskModel.fromRecord(
      RecordModel.fromJson(_json({'importance': 'urgent'})),
    );
    expect(model.toEntity, throwsFormatException);
  });

  test('toJson writes the 11 keys', () {
    final json = TaskModel.fromEntity(
      TaskEntity(
        id: 't1',
        title: 'Regar plantas',
        listId: 'l1',
        createdAt: DateTime.utc(2026, 10, 15, 11),
        parentId: 'p1',
        estimatedMinutes: 30,
        dueDate: DateTime(2026, 10, 24),
        importance: ImportanceEnum.max,
        recurringTaskId: 'r1',
      ),
    ).toJson();
    expect(json.keys.toSet(), {
      'title',
      'list',
      'parent',
      'created_at',
      'estimated_minutes',
      'due_date',
      'importance',
      'is_done',
      'has_children',
      'spent_minutes',
      'recurring_task_id',
    });
    expect(json['created_at'], '2026-10-15 11:00:00.000Z');
    expect(json['due_date'], '2026-10-24 00:00:00.000Z');
    expect(json['importance'], 'max');
    expect(json['recurring_task_id'], 'r1');
  });

  test('plain root task writes null keys', () {
    final json = TaskModel.fromEntity(
      TaskEntity(
        id: 't1',
        title: 'x',
        listId: 'l1',
        createdAt: DateTime.utc(2026, 10, 15),
      ),
    ).toJson();
    for (final key in [
      'parent',
      'due_date',
      'importance',
      'estimated_minutes',
      'recurring_task_id',
    ]) {
      expect(json.containsKey(key), isTrue, reason: key);
      expect(json[key], isNull, reason: key);
    }
  });

  test('fromEntity(e).toEntity() == e', () {
    final e = TaskEntity(
      id: 't1',
      title: 'x',
      listId: 'l1',
      createdAt: DateTime.utc(2026, 10, 15),
      importance: ImportanceEnum.low,
      estimatedMinutes: 10,
    );
    expect(TaskModel.fromEntity(e).toEntity(), e);
  });
}
