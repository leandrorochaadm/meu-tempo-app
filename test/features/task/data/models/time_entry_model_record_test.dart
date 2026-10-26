import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/pb_schema.dart';
import 'package:meu_tempo/features/task/data/models/time_entry_model.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:pocketbase/pocketbase.dart';

RecordModel _record([Map<String, dynamic> overrides = const {}]) =>
    RecordModel.fromJson({
      'id': 'abc123def456ghi',
      'collectionId': 'pbc_1',
      'collectionName': 'time_entries',
      'user': 'user-a',
      'target_id': 't1',
      'target_type': 'task',
      'list_id': 'l1',
      'origin': 'manual',
      'minutes': 30,
      'occurred_at': '2026-10-24 13:30:00.000Z',
      ...overrides,
    });

TimeEntryModel _model({DateTime? occurredAt}) => TimeEntryModel(
  id: 'e1',
  targetId: 't1',
  targetType: TimerTargetTypeEnum.task,
  listId: 'l1',
  minutes: 30,
  origin: TimeEntryOriginEnum.manual,
  occurredAt: occurredAt,
);

void main() {
  test('fromRecord reads the raw PocketBase payload', () {
    final e = TimeEntryModel.fromRecord(_record()).toEntity();
    expect(e.id, 'abc123def456ghi');
    expect(e.targetType, TimerTargetTypeEnum.task);
    expect(e.origin, TimeEntryOriginEnum.manual);
    expect(e.minutes, 30);
    expect(e.occurredAt, DateTime.utc(2026, 10, 24, 13, 30).toLocal());
  });

  test('appointment and timer map to the matching enums', () {
    final e = TimeEntryModel.fromRecord(
      _record({'target_type': 'appointment', 'origin': 'timer'}),
    ).toEntity();
    expect(e.targetType, TimerTargetTypeEnum.appointment);
    expect(e.origin, TimeEntryOriginEnum.timer);
  });

  test('date with T separator → same instant', () {
    final e = TimeEntryModel.fromRecord(
      _record({'occurred_at': '2026-10-24T13:30:00.000Z'}),
    ).toEntity();
    expect(e.occurredAt, DateTime.utc(2026, 10, 24, 13, 30).toLocal());
  });

  test('empty occurred_at → epoch fallback', () {
    final e = TimeEntryModel.fromRecord(
      _record({'occurred_at': ''}),
    ).toEntity();
    expect(e.occurredAt, DateTime.fromMillisecondsSinceEpoch(0));
  });

  for (final overrides in <Map<String, dynamic>>[
    {'target_type': ''},
    {'target_type': 'folha'},
    {'origin': ''},
    {'origin': 'auto'},
  ]) {
    test('invalid enum text $overrides → FormatException on toEntity', () {
      final model = TimeEntryModel.fromRecord(_record(overrides));
      expect(model.toEntity, throwsFormatException);
    });
  }

  test('empty target_id and list_id pass as empty strings', () {
    final e = TimeEntryModel.fromRecord(
      _record({'target_id': '', 'list_id': ''}),
    ).toEntity();
    expect(e.targetId, '');
    expect(e.listId, '');
  });

  test('toJson writes exactly the PocketBase keys', () {
    final json = _model(
      occurredAt: DateTime.utc(2026, 10, 24, 13, 30),
    ).toJson();
    expect(json.keys.toSet(), {
      PbFields.targetId,
      PbFields.targetType,
      PbFields.listId,
      PbFields.minutes,
      PbFields.origin,
      PbFields.occurredAt,
    });
    expect(json[PbFields.targetType], 'task');
    expect(json[PbFields.origin], 'manual');
    expect(json[PbFields.occurredAt], '2026-10-24 13:30:00.000Z');
  });

  test('toJson with null occurredAt keeps the key as null', () {
    final json = _model().toJson();
    expect(json.containsKey(PbFields.occurredAt), isTrue);
    expect(json[PbFields.occurredAt], isNull);
  });

  test('fromEntity → toEntity preserves the entity', () {
    final entity = _model(occurredAt: DateTime(2026, 10, 24, 10)).toEntity();
    expect(TimeEntryModel.fromEntity(entity).toEntity(), entity);
  });
}
