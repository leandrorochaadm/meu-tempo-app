import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/lock_screen/data/background/lock_screen_action_channel_handler.dart';
import 'package:meu_tempo/features/lock_screen/data/background/lock_screen_channel_constants.dart';
import 'package:meu_tempo/features/lock_screen/data/background/lock_screen_channel_method_enum.dart';
import 'package:meu_tempo/features/lock_screen/data/models/lock_screen_action_reply_model.dart';
import 'package:meu_tempo/features/lock_screen/data/models/lock_screen_timer_payload_model.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_action_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/handle_lock_screen_action_use_case.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/process_lock_screen_action_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:mocktail/mocktail.dart';

class _MockProcess extends Mock implements ProcessLockScreenActionUseCase {}

typedef _Result = Either<Failure, LockScreenTimerEntity?>;

void main() {
  late _MockProcess process;
  late LockScreenActionChannelHandler handler;

  final now = DateTime(2026, 10, 7, 10, 5);
  final timer = LockScreenTimerEntity(
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    title: 'Tela de login',
    listName: 'Trabalho',
    status: TimerStatusEnum.running,
    spentMinutes: 40,
    sessionStartedAt: DateTime(2026, 10, 7, 10),
  );
  final pauseParams = HandleLockScreenActionParams(
    action: LockScreenActionEnum.pause,
    targetId: 't1',
    now: now,
  );
  const pausePayload = {'action': 'pause', 'targetId': 't1'};
  const confirmPayload = {'action': 'stop_confirmed', 'targetId': 't1'};
  final unchangedMap = const LockScreenActionReplyModel.unchanged().toMap();

  LockScreenActionChannelHandler build({Duration? timeout}) =>
      LockScreenActionChannelHandler(
        process,
        clock: () => now,
        timeout: timeout ?? LockScreenChannelConstants.actionTimeout,
      );

  setUpAll(() => registerFallbackValue(pauseParams));

  setUp(() {
    process = _MockProcess();
    when(
      () => process(any()),
    ).thenAnswer((_) async => Right<Failure, LockScreenTimerEntity?>(timer));
    handler = build();
  });

  test('payload válido chama o UseCase com ação, alvo e instante', () async {
    await handler.handleAction(pausePayload);

    verify(() => process(pauseParams)).called(1);
  });

  test('cronômetro na resposta vira show', () async {
    final result = await handler.handleAction(pausePayload);

    expect(
      result,
      LockScreenActionReplyModel.show(
        LockScreenTimerPayloadModel.fromEntity(timer, now: now),
      ).toMap(),
    );
  });

  test('sem cronômetro vira clear', () async {
    when(() => process(any())).thenAnswer(
      (_) async => const Right<Failure, LockScreenTimerEntity?>(null),
    );

    final result = await handler.handleAction(confirmPayload);

    expect(result, const LockScreenActionReplyModel.clear().toMap());
  });

  test('falha vira unchanged', () async {
    for (final failure in <Failure>[
      const NetworkFailure(),
      const UnauthenticatedFailure(),
    ]) {
      when(
        () => process(any()),
      ).thenAnswer((_) async => Left<Failure, LockScreenTimerEntity?>(failure));

      expect(await handler.handleAction(pausePayload), unchangedMap);
    }
  });

  test('payload inválido vira unchanged sem chamar o UseCase', () async {
    final invalid = <Object?>[
      {'action': 'stop', 'targetId': 't1'},
      null,
      {'action': 'pause'},
    ];

    for (final raw in invalid) {
      expect(await handler.handleAction(raw), unchangedMap);
    }
    verifyNever(() => process(any()));
  });

  test('exceção do UseCase vira unchanged', () async {
    when(() => process(any())).thenThrow(StateError('x'));

    expect(await handler.handleAction(pausePayload), unchangedMap);
  });

  test('passar do limite de tempo vira unchanged', () async {
    when(() => process(any())).thenAnswer((_) => Completer<_Result>().future);
    handler = build(timeout: const Duration(milliseconds: 10));

    expect(await handler.handleAction(pausePayload), unchangedMap);
  });

  test('toques seguidos são processados na ordem', () async {
    final first = Completer<_Result>();
    when(() => process(pauseParams)).thenAnswer((_) => first.future);
    final confirmParams = HandleLockScreenActionParams(
      action: LockScreenActionEnum.stopConfirmed,
      targetId: 't1',
      now: now,
    );
    when(() => process(confirmParams)).thenAnswer(
      (_) async => const Right<Failure, LockScreenTimerEntity?>(null),
    );

    final firstReply = handler.handleAction(pausePayload);
    final secondReply = handler.handleAction(confirmPayload);
    await Future<void>.delayed(Duration.zero);
    verify(() => process(pauseParams)).called(1);
    verifyNever(() => process(confirmParams));

    first.complete(Right<Failure, LockScreenTimerEntity?>(timer));

    expect((await firstReply)[LockScreenReplyKeys.reply], isNotNull);
    expect(await secondReply, const LockScreenActionReplyModel.clear().toMap());
    verify(() => process(confirmParams)).called(1);
  });

  test('toque seguinte espera a ação que passou do limite de tempo', () async {
    final first = Completer<_Result>();
    when(() => process(pauseParams)).thenAnswer((_) => first.future);
    final confirmParams = HandleLockScreenActionParams(
      action: LockScreenActionEnum.stopConfirmed,
      targetId: 't1',
      now: now,
    );
    when(() => process(confirmParams)).thenAnswer(
      (_) async => const Right<Failure, LockScreenTimerEntity?>(null),
    );
    handler = build(timeout: const Duration(milliseconds: 10));

    expect(await handler.handleAction(pausePayload), unchangedMap);
    final secondReply = handler.handleAction(confirmPayload);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    verifyNever(() => process(confirmParams));

    first.complete(Right<Failure, LockScreenTimerEntity?>(timer));
    await secondReply;

    verify(() => process(confirmParams)).called(1);
  });

  test('onMethodCall: handleAction devolve a resposta', () async {
    final result = await handler.onMethodCall(
      MethodCall(
        LockScreenChannelMethodEnum.handleAction.apiValue,
        pausePayload,
      ),
    );

    expect(
      result,
      LockScreenActionReplyModel.show(
        LockScreenTimerPayloadModel.fromEntity(timer, now: now),
      ).toMap(),
    );
  });

  test('onMethodCall: método desconhecido lança MissingPluginException', () {
    expect(
      handler.onMethodCall(const MethodCall('other')),
      throwsA(isA<MissingPluginException>()),
    );
    expect(
      handler.onMethodCall(
        MethodCall(LockScreenChannelMethodEnum.backgroundReady.apiValue),
      ),
      throwsA(isA<MissingPluginException>()),
    );
  });
}
