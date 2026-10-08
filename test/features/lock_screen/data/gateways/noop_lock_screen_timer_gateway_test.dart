import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/lock_screen/data/gateways/noop_lock_screen_timer_gateway.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_permission_status_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  const gateway = NoopLockScreenTimerGateway();

  test('show e clear não fazem nada e dão certo', () async {
    final timer = LockScreenTimerEntity(
      targetId: 't1',
      targetType: TimerTargetTypeEnum.task,
      title: 'Tela de login',
      listName: 'Trabalho',
      status: TimerStatusEnum.running,
      spentMinutes: 0,
      sessionStartedAt: DateTime(2026, 10, 7, 10),
    );

    expect(await gateway.show(timer), const Right<Failure, Unit>(unit));
    expect(await gateway.clear(), const Right<Failure, Unit>(unit));
  });

  test('permissão é unsupported', () async {
    expect(
      await gateway.getPermissionStatus(),
      const Right<Failure, LockScreenPermissionStatusEnum>(
        LockScreenPermissionStatusEnum.unsupported,
      ),
    );
  });

  test('abrir Ajustes dá certo sem fazer nada', () async {
    expect(
      await gateway.openNotificationSettings(),
      const Right<Failure, Unit>(unit),
    );
  });

  test('fluxo de toques termina vazio', () {
    expect(gateway.watchTaps(), emitsDone);
  });
}
