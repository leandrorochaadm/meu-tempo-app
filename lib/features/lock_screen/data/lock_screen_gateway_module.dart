import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../domain/gateways/lock_screen_timer_gateway.dart';
import 'gateways/native_lock_screen_timer_gateway.dart';
import 'gateways/noop_lock_screen_timer_gateway.dart';

/// Single place that picks the lock screen timer implementation by platform:
/// Android (service) and iPhone (Live Activity) → native; web and others →
/// empty (no lock screen).
@module
abstract class LockScreenGatewayModule {
  @lazySingleton
  LockScreenTimerGateway get lockScreenTimerGateway {
    if (kIsWeb) return const NoopLockScreenTimerGateway();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS => NativeLockScreenTimerGateway(),
      _ => const NoopLockScreenTimerGateway(),
    };
  }
}
