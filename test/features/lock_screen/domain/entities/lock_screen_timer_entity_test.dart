import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_action_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

LockScreenTimerEntity timer({
  TimerStatusEnum status = TimerStatusEnum.running,
  int spent = 40,
  DateTime? startedAt,
}) =>
    LockScreenTimerEntity(
      targetId: 't1',
      targetType: TimerTargetTypeEnum.task,
      title: 'Tela de login',
      listName: 'Trabalho',
      status: status,
      spentMinutes: spent,
      sessionStartedAt: startedAt ?? DateTime(2026, 10, 7, 10),
    );

void main() {
  test('rodando: relógio inclui o tempo já gasto', () {
    expect(
      timer().elapsedAt(DateTime(2026, 10, 7, 10, 5)),
      const Duration(minutes: 45),
    );
  });

  test('rodando: clockBase é o início da sessão menos o já gasto', () {
    expect(timer().clockBase, DateTime(2026, 10, 7, 9, 20));
  });

  test('pausado: relógio parado no tempo já gasto', () {
    expect(
      timer(status: TimerStatusEnum.paused).elapsedAt(DateTime(2026, 10, 7, 12)),
      const Duration(minutes: 40),
    );
  });

  test('agora antes do início não conta sessão negativa', () {
    expect(
      timer().elapsedAt(DateTime(2026, 10, 7, 9)),
      const Duration(minutes: 40),
    );
  });

  test('rodando mostra pausar e parar', () {
    expect(timer().availableActions, [
      LockScreenActionEnum.pause,
      LockScreenActionEnum.stopConfirmed,
    ]);
  });

  test('pausado mostra continuar e parar', () {
    expect(timer(status: TimerStatusEnum.paused).availableActions, [
      LockScreenActionEnum.resume,
      LockScreenActionEnum.stopConfirmed,
    ]);
  });

  test('isRunning/isPaused seguem o status', () {
    expect(timer().isRunning, isTrue);
    expect(timer().isPaused, isFalse);
    expect(timer(status: TimerStatusEnum.paused).isPaused, isTrue);
    expect(timer(status: TimerStatusEnum.paused).isRunning, isFalse);
  });

  test('igualdade por valor (status e spentMinutes entram)', () {
    expect(timer(), equals(timer()));
    expect(timer(spent: 40), isNot(equals(timer(spent: 65))));
    expect(
      timer(),
      isNot(equals(timer(status: TimerStatusEnum.paused))),
    );
  });
}
