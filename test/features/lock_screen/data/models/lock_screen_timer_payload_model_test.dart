import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/lock_screen/data/background/lock_screen_channel_constants.dart';
import 'package:meu_tempo/features/lock_screen/data/models/lock_screen_timer_payload_model.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_action_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/lock_screen_rules.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  final now = DateTime(2026, 10, 7, 10, 5);

  LockScreenTimerEntity timer({
    TimerStatusEnum status = TimerStatusEnum.running,
    TimerTargetTypeEnum type = TimerTargetTypeEnum.task,
  }) => LockScreenTimerEntity(
    targetId: 't1',
    targetType: type,
    title: 'Tela de login',
    listName: 'Trabalho',
    status: status,
    spentMinutes: 40,
    sessionStartedAt: DateTime(2026, 10, 7, 10),
  );

  test('rodando: base do relógio inclui o tempo já gasto', () {
    final model = LockScreenTimerPayloadModel.fromEntity(timer(), now: now);

    expect(
      model.clockBaseEpochMillis,
      DateTime(2026, 10, 7, 9, 20).millisecondsSinceEpoch,
    );
    expect(model.elapsedMillis, const Duration(minutes: 45).inMilliseconds);
    expect(model.actions, [
      LockScreenActionEnum.pause.apiValue,
      LockScreenActionEnum.stopConfirmed.apiValue,
    ]);
  });

  test('pausado: tempo fixo e botão continuar', () {
    final model = LockScreenTimerPayloadModel.fromEntity(
      timer(status: TimerStatusEnum.paused),
      now: now,
    );

    expect(model.elapsedMillis, const Duration(minutes: 40).inMilliseconds);
    expect(model.actions.first, LockScreenActionEnum.resume.apiValue);
    expect(model.status, TimerStatusEnum.paused.apiValue);
  });

  test('compromisso leva o tipo do alvo', () {
    final model = LockScreenTimerPayloadModel.fromEntity(
      timer(type: TimerTargetTypeEnum.appointment),
      now: now,
    );

    expect(model.targetType, TimerTargetTypeEnum.appointment.apiValue);
  });

  test('janela de confirmação vem da regra de domínio', () {
    final model = LockScreenTimerPayloadModel.fromEntity(timer(), now: now);

    expect(
      model.stopConfirmationWindowMillis,
      LockScreenRules.stopConfirmationWindow.inMilliseconds,
    );
  });

  test('toMap usa as chaves do protocolo', () {
    final map = LockScreenTimerPayloadModel.fromEntity(
      timer(),
      now: now,
    ).toMap();

    expect(map.keys.toSet(), {
      LockScreenTimerPayloadKeys.targetId,
      LockScreenTimerPayloadKeys.targetType,
      LockScreenTimerPayloadKeys.title,
      LockScreenTimerPayloadKeys.listName,
      LockScreenTimerPayloadKeys.status,
      LockScreenTimerPayloadKeys.clockBaseEpochMillis,
      LockScreenTimerPayloadKeys.elapsedMillis,
      LockScreenTimerPayloadKeys.actions,
      LockScreenTimerPayloadKeys.stopConfirmationWindowMillis,
    });
  });
}
