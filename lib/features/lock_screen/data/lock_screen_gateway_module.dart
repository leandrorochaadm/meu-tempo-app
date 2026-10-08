import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../domain/gateways/lock_screen_timer_gateway.dart';
import 'gateways/android_lock_screen_timer_gateway.dart';
import 'gateways/noop_lock_screen_timer_gateway.dart';

/// Single place that picks the lock screen timer implementation by platform:
/// Android → native service; web → empty (no lock screen); iPhone → empty
/// until the iPhone step.
@module
abstract class LockScreenGatewayModule {
  @lazySingleton
  LockScreenTimerGateway get lockScreenTimerGateway {
    if (kIsWeb) return const NoopLockScreenTimerGateway();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidLockScreenTimerGateway(),
      _ => const NoopLockScreenTimerGateway(), // iPhone: step 11
    };
  }
}
