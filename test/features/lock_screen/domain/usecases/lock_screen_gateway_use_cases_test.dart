import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_permission_status_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_tap_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/lock_screen_failures.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/get_lock_screen_permission_status_use_case.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/open_notification_settings_use_case.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/watch_lock_screen_taps_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

import '../../fake_lock_screen_timer_gateway.dart';

const taskTap = LockScreenTapEntity(
  targetId: 't1',
  targetType: TimerTargetTypeEnum.task,
);
const appointmentTap = LockScreenTapEntity(
  targetId: 'a1',
  targetType: TimerTargetTypeEnum.appointment,
);

void main() {
  late FakeLockScreenTimerGateway gateway;

  setUp(() => gateway = FakeLockScreenTimerGateway());
  tearDown(() => gateway.dispose());

  test(
    'GetLockScreenPermissionStatusUseCase returns what the phone reports',
    () async {
      gateway.permissionResult = const Right(
        LockScreenPermissionStatusEnum.denied,
      );

      final result = await GetLockScreenPermissionStatusUseCase(gateway)(
        const NoParams(),
      );

      expect(result, const Right(LockScreenPermissionStatusEnum.denied));
      expect(gateway.permissionChecks, 1);
    },
  );

  test(
    'GetLockScreenPermissionStatusUseCase passes the failure along',
    () async {
      gateway.permissionResult = const Left(LockScreenPlatformFailure());

      final result = await GetLockScreenPermissionStatusUseCase(gateway)(
        const NoParams(),
      );

      expect(result, const Left(LockScreenPlatformFailure()));
    },
  );

  test('OpenNotificationSettingsUseCase opens the settings', () async {
    final result = await OpenNotificationSettingsUseCase(gateway)(
      const NoParams(),
    );

    expect(result, const Right(unit));
    expect(gateway.openSettingsCalls, 1);
  });

  test('OpenNotificationSettingsUseCase passes the failure along', () async {
    gateway.openSettingsResult = const Left(LockScreenPlatformFailure());

    final result = await OpenNotificationSettingsUseCase(gateway)(
      const NoParams(),
    );

    expect(result, const Left(LockScreenPlatformFailure()));
  });

  test('WatchLockScreenTapsUseCase relays the taps', () async {
    final useCase = WatchLockScreenTapsUseCase(gateway);
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([taskTap, appointmentTap]),
    );

    gateway.taps
      ..add(taskTap)
      ..add(appointmentTap);

    await expectation;
  });
}
