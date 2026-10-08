import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/data/active_timer_fields.dart';
import 'package:meu_tempo/features/task/data/models/active_timer_model.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  final startedAt = DateTime(2026, 7, 20, 10, 30);

  Map<String, dynamic> rawDoc({String? status}) => {
    ActiveTimerFields.targetId: 't1',
    ActiveTimerFields.startedAt: Timestamp.fromDate(startedAt),
    ActiveTimerFields.targetType: TimerTargetTypeEnum.task.name,
    ActiveTimerFields.listId: 'l1',
    ActiveTimerFields.status: ?status,
  };

  ActiveTimerEntity entity(TimerStatusEnum status) => ActiveTimerEntity(
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    listId: 'l1',
    startedAt: startedAt,
    status: status,
  );

  group('ActiveTimerModel', () {
    test('doc antigo sem status vira entity running', () {
      final model = ActiveTimerModel.fromJson(rawDoc());
      expect(model.toEntity().status, TimerStatusEnum.running);
    });

    test('lê status paused', () {
      final model = ActiveTimerModel.fromJson(
        rawDoc(status: TimerStatusEnum.paused.apiValue),
      );
      expect(model.toEntity().status, TimerStatusEnum.paused);
    });

    test('grava o apiValue do status', () {
      final json = ActiveTimerModel.fromEntity(
        entity(TimerStatusEnum.paused),
      ).toJson();
      expect(json[ActiveTimerFields.status], TimerStatusEnum.paused.apiValue);
    });

    test('ida e volta preserva a entity', () {
      for (final status in TimerStatusEnum.values) {
        final e = entity(status);
        final back = ActiveTimerModel.fromJson(
          ActiveTimerModel.fromEntity(e).toJson(),
        ).toEntity();
        expect(back, e);
      }
    });
  });
}
