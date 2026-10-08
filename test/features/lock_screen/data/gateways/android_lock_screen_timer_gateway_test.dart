import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/lock_screen/data/background/lock_screen_channel_constants.dart';
import 'package:meu_tempo/features/lock_screen/data/gateways/android_lock_screen_timer_gateway.dart';
import 'package:meu_tempo/features/lock_screen/data/gateways/lock_screen_timer_channel_constants.dart';
import 'package:meu_tempo/features/lock_screen/data/gateways/lock_screen_timer_channel_method_enum.dart';
import 'package:meu_tempo/features/lock_screen/data/models/lock_screen_timer_payload_model.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_permission_status_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_tap_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/lock_screen_failures.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel(
    LockScreenTimerChannelConstants.methodChannelName,
  );
  const tapChannel = EventChannel(
    LockScreenTimerChannelConstants.tapChannelName,
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

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
  final pausedTimer = LockScreenTimerEntity(
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    title: 'Tela de login',
    listName: 'Trabalho',
    status: TimerStatusEnum.paused,
    spentMinutes: 45,
    sessionStartedAt: DateTime(2026, 10, 7, 10, 5),
  );

  late AndroidLockScreenTimerGateway gateway;
  late List<MethodCall> calls;

  void mockMethod(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(methodChannel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(() {
    calls = [];
    gateway = AndroidLockScreenTimerGateway(
      clock: () => now,
      callTimeout: const Duration(milliseconds: 20),
    );
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockStreamHandler(tapChannel, null);
  });

  test('show manda o payload do passo 09', () async {
    mockMethod((_) async => null);

    final result = await gateway.show(timer);

    expect(result, const Right<Failure, Unit>(unit));
    expect(calls.single.method, LockScreenTimerChannelMethodEnum.show.apiValue);
    expect(
      calls.single.arguments,
      LockScreenTimerPayloadModel.fromEntity(timer, now: now).toMap(),
    );
  });

  test('pausado vai com status e ações do pausado', () async {
    mockMethod((_) async => null);

    await gateway.show(pausedTimer);

    final args = calls.single.arguments as Map;
    expect(
      args[LockScreenTimerPayloadKeys.status],
      TimerStatusEnum.paused.apiValue,
    );
  });

  test('clear chama clear', () async {
    mockMethod((_) async => null);

    final result = await gateway.clear();

    expect(result, const Right<Failure, Unit>(unit));
    expect(
      calls.single.method,
      LockScreenTimerChannelMethodEnum.clear.apiValue,
    );
  });

  test('erro do nativo vira LockScreenPlatformFailure', () async {
    mockMethod((_) async => throw PlatformException(code: 'fgs'));

    expect(
      await gateway.show(timer),
      const Left<Failure, Unit>(LockScreenPlatformFailure()),
    );
  });

  test('sem nativo vira LockScreenPlatformFailure', () async {
    expect(
      await gateway.clear(),
      const Left<Failure, Unit>(LockScreenPlatformFailure()),
    );
  });

  test('nativo que não responde estoura o limite', () async {
    mockMethod((_) => Completer<Object?>().future);

    expect(
      await gateway.clear(),
      const Left<Failure, Unit>(LockScreenPlatformFailure()),
    );
  });

  test('permissão: lê cada estado', () async {
    final expected = {
      'granted': LockScreenPermissionStatusEnum.granted,
      'denied': LockScreenPermissionStatusEnum.denied,
      'not_requested': LockScreenPermissionStatusEnum.notRequested,
      'outro': LockScreenPermissionStatusEnum.unsupported,
    };

    for (final entry in expected.entries) {
      mockMethod((_) async => entry.key);

      expect(
        await gateway.getPermissionStatus(),
        Right<Failure, LockScreenPermissionStatusEnum>(entry.value),
      );
    }
  });

  test('pedir permissão espera o usuário (sem limite)', () async {
    mockMethod((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return 'granted';
    });

    expect(
      await gateway.requestPermission(),
      const Right<Failure, LockScreenPermissionStatusEnum>(
        LockScreenPermissionStatusEnum.granted,
      ),
    );
    expect(
      calls.single.method,
      LockScreenTimerChannelMethodEnum.requestPermission.apiValue,
    );
  });

  test('abrir Ajustes chama o nativo', () async {
    mockMethod((_) async => null);

    final result = await gateway.openNotificationSettings();

    expect(result, const Right<Failure, Unit>(unit));
    expect(
      calls.single.method,
      LockScreenTimerChannelMethodEnum.openNotificationSettings.apiValue,
    );
  });

  test('toques viram LockScreenTapEntity', () async {
    messenger.setMockStreamHandler(
      tapChannel,
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          events.success({'targetType': 'task', 'targetId': 't1'});
        },
      ),
    );

    expect(
      gateway.watchTaps(),
      emits(
        const LockScreenTapEntity(
          targetId: 't1',
          targetType: TimerTargetTypeEnum.task,
        ),
      ),
    );
  });

  test('toque inválido e erro do canal são descartados', () async {
    messenger.setMockStreamHandler(
      tapChannel,
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          events.success({'targetType': 'x'});
          events.error(code: 'e');
          events.success({'targetType': 'appointment', 'targetId': 'a1'});
        },
      ),
    );

    expect(
      gateway.watchTaps(),
      emits(
        const LockScreenTapEntity(
          targetId: 'a1',
          targetType: TimerTargetTypeEnum.appointment,
        ),
      ),
    );
  });
}
