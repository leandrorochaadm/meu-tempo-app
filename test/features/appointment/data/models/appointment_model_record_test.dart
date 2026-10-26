import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/pb_schema.dart';
import 'package:meu_tempo/features/appointment/data/models/appointment_model.dart';
import 'package:meu_tempo/features/appointment/domain/entities/appointment_entity.dart';
import 'package:pocketbase/pocketbase.dart';

RecordModel _record(Map<String, dynamic> overrides) => RecordModel.fromJson({
  'id': 'abc123def456ghi',
  'collectionId': 'pbc_1',
  'collectionName': 'appointments',
  'user': 'user-a',
  'title': 'Dentista',
  'list_id': 'pessoal',
  'date': '2026-10-07 00:00:00.000Z',
  'start_minute': 900,
  'duration_minutes': 60,
  'spent_minutes': 15,
  'is_done': true,
  ...overrides,
});

void main() {
  test('fromRecord reads the raw PocketBase payload', () {
    final e = AppointmentModel.fromRecord(_record({})).toEntity();
    expect(e.id, 'abc123def456ghi');
    expect(e.date, DateTime(2026, 10, 7));
    expect(e.listId, 'pessoal');
    expect(e.startMinute, 900);
    expect(e.durationMinutes, 60);
    expect(e.spentMinutes, 15);
    expect(e.isDone, isTrue);
  });

  test('date with T separator → same day', () {
    final e = AppointmentModel.fromRecord(
      _record({'date': '2026-10-07T00:00:00.000Z'}),
    ).toEntity();
    expect(e.date, DateTime(2026, 10, 7));
  });

  test('missing is_done → false and missing spent_minutes → 0', () {
    final record = _record({})
      ..data.remove(PbFields.isDone)
      ..data.remove(PbFields.spentMinutes);
    final e = AppointmentModel.fromRecord(record).toEntity();
    expect(e.isDone, isFalse);
    expect(e.spentMinutes, 0);
  });

  test('empty date → epoch fallback', () {
    final e = AppointmentModel.fromRecord(_record({'date': ''})).toEntity();
    expect(e.date, DateTime.fromMillisecondsSinceEpoch(0));
  });

  test('toJson writes exactly the PocketBase keys', () {
    final json = AppointmentModel(
      id: 'x',
      title: 'T',
      listId: 'l',
      date: DateTime(2026, 10, 7),
      startMinute: 10,
      durationMinutes: 20,
    ).toJson();
    expect(json.keys.toSet(), {
      PbFields.title,
      PbFields.listId,
      PbFields.date,
      PbFields.startMinute,
      PbFields.durationMinutes,
      PbFields.spentMinutes,
      PbFields.isDone,
    });
    expect(json[PbFields.date], '2026-10-07 00:00:00.000Z');
  });

  test('toJson with null date keeps the key as null', () {
    final json = const AppointmentModel(
      id: 'x',
      title: 'T',
      listId: 'l',
      date: null,
      startMinute: 10,
      durationMinutes: 20,
    ).toJson();
    expect(json.containsKey(PbFields.date), isTrue);
    expect(json[PbFields.date], isNull);
  });

  test('fromEntity → toEntity preserves the entity', () {
    final entity = AppointmentEntity(
      id: 'a1',
      title: 'T',
      listId: 'l',
      date: DateTime(2026, 10, 7),
      startMinute: 10,
      durationMinutes: 20,
      spentMinutes: 5,
      isDone: true,
    );
    expect(AppointmentModel.fromEntity(entity).toEntity(), entity);
  });
}
