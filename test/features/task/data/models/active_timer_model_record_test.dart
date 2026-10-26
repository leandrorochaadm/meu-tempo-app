import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/pb_schema.dart';
import 'package:meu_tempo/features/task/data/models/active_timer_model.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:pocketbase/pocketbase.dart';

RecordModel _record(Map<String, dynamic> overrides) => RecordModel.fromJson({
  'id': 'tmr1',
  'collectionId': 'pbc_8',
  'collectionName': 'active_timers',
  'user': 'user-a',
  'target_id': 't1',
  'target_type': 'appointment',
  'list_id': 'l1',
  'status': 'paused',
  'started_at': '2026-07-20 13:30:00.000Z',
  ...overrides,
});

ActiveTimerEntity _entity({
  TimerStatusEnum status = TimerStatusEnum.paused,
  TimerTargetTypeEnum type = TimerTargetTypeEnum.appointment,
}) => ActiveTimerEntity(
  targetId: 't1',
  targetType: type,
  listId: 'l1',
  startedAt: DateTime.utc(2026, 7, 20, 13, 30).toLocal(),
  status: status,
);

void main() {
  group('fromRecord', () {
    test('reads every field', () {
      final entity = ActiveTimerModel.fromRecord(_record({})).toEntity();
      expect(
        entity,
        ActiveTimerEntity(
          targetId: 't1',
          targetType: TimerTargetTypeEnum.appointment,
          listId: 'l1',
          startedAt: DateTime.utc(2026, 7, 20, 13, 30).toLocal(),
          status: TimerStatusEnum.paused,
        ),
      );
    });

    test('accepts started_at with T', () {
      final entity = ActiveTimerModel.fromRecord(
        _record({'started_at': '2026-07-20T13:30:00.000Z'}),
      ).toEntity();
      expect(entity.startedAt, DateTime.utc(2026, 7, 20, 13, 30).toLocal());
    });

    test('missing, empty or unknown status becomes running', () {
      for (final status in <Object?>['', 'stopped']) {
        final model = ActiveTimerModel.fromRecord(_record({'status': status}));
        expect(model.toEntity().status, TimerStatusEnum.running);
      }
      final json = _record({}).data..remove('status');
      expect(
        ActiveTimerModel.fromJson(json).toEntity().status,
        TimerStatusEnum.running,
      );
    });

    test('missing, empty or unknown target_type becomes task', () {
      for (final type in <Object?>['', 'meeting']) {
        final model = ActiveTimerModel.fromRecord(
          _record({'target_type': type}),
        );
        expect(model.toEntity().targetType, TimerTargetTypeEnum.task);
      }
      final json = _record({}).data..remove('target_type');
      expect(
        ActiveTimerModel.fromJson(json).toEntity().targetType,
        TimerTargetTypeEnum.task,
      );
    });

    test('missing or empty list_id becomes empty text', () {
      expect(
        ActiveTimerModel.fromRecord(_record({'list_id': ''})).toEntity().listId,
        '',
      );
      final json = _record({}).data..remove('list_id');
      expect(ActiveTimerModel.fromJson(json).toEntity().listId, '');
    });

    test('empty started_at becomes the epoch', () {
      final entity = ActiveTimerModel.fromRecord(
        _record({'started_at': ''}),
      ).toEntity();
      expect(entity.startedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('toJson', () {
    test('writes exactly the five fields with the api values', () {
      final json = ActiveTimerModel.fromEntity(_entity()).toJson();
      expect(json.keys.toSet(), {
        PbFields.targetId,
        PbFields.targetType,
        PbFields.listId,
        PbFields.startedAt,
        PbFields.status,
      });
      expect(json[PbFields.status], 'paused');
      expect(json[PbFields.targetType], 'appointment');
      expect(json[PbFields.startedAt], '2026-07-20 13:30:00.000Z');
    });

    test('round trip keeps the entity', () {
      for (final status in TimerStatusEnum.values) {
        for (final type in TimerTargetTypeEnum.values) {
          final entity = _entity(status: status, type: type);
          final json = ActiveTimerModel.fromEntity(entity).toJson();
          expect(ActiveTimerModel.fromJson(json).toEntity(), entity);
        }
      }
    });
  });
}
