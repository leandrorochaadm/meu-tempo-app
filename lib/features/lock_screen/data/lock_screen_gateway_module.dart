import 'package:injectable/injectable.dart';

import '../domain/gateways/lock_screen_timer_gateway.dart';
import 'gateways/noop_lock_screen_timer_gateway.dart';

/// Single place that picks the lock screen timer implementation. Today: empty
/// on every platform. The Android and iPhone steps swap the body for
/// `kIsWeb ? const NoopLockScreenTimerGateway() : <native>`.
@module
abstract class LockScreenGatewayModule {
  @lazySingleton
  LockScreenTimerGateway get lockScreenTimerGateway =>
      const NoopLockScreenTimerGateway();
}
