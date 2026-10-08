import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  final now = DateTime(2026, 7, 20, 10, 30);

  ActiveTimerEntity timer({
    required DateTime startedAt,
    TimerStatusEnum? status,
  }) => status == null
      ? ActiveTimerEntity(
          targetId: 't1',
          targetType: TimerTargetTypeEnum.task,
          listId: 'l1',
          startedAt: startedAt,
        )
      : ActiveTimerEntity(
          targetId: 't1',
          targetType: TimerTargetTypeEnum.task,
          listId: 'l1',
          startedAt: startedAt,
          status: status,
        );

  group('ActiveTimerEntity', () {
    test('status padrão é running', () {
      final t = timer(startedAt: now);
      expect(t.isRunning, isTrue);
      expect(t.isPaused, isFalse);
    });

    test('rodando conta os minutos desde startedAt', () {
      final t = timer(startedAt: now.subtract(const Duration(minutes: 25)));
      expect(t.elapsedMinutes(now), 25);
    });

    test('pausado devolve 0 minutos', () {
      final t = timer(
        startedAt: now.subtract(const Duration(minutes: 25)),
        status: TimerStatusEnum.paused,
      );
      expect(t.isPaused, isTrue);
      expect(t.elapsedMinutes(now), 0);
    });

    test('startedAt no futuro devolve 0', () {
      final t = timer(startedAt: now.add(const Duration(minutes: 5)));
      expect(t.elapsedMinutes(now), 0);
    });

    test('status entra na igualdade', () {
      final running = timer(startedAt: now);
      final paused = timer(startedAt: now, status: TimerStatusEnum.paused);
      expect(running, isNot(equals(paused)));
    });
  });
}
