import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/lock_screen_tap_entity.dart';
import '../gateways/lock_screen_timer_gateway.dart';

/// Taps on the lock screen timer outside the buttons — each one asks to open
/// the app on the task or appointment (rule "tap on the timer").
@lazySingleton
class WatchLockScreenTapsUseCase
    implements StreamUseCase<LockScreenTapEntity, NoParams> {
  const WatchLockScreenTapsUseCase(this._gateway);

  final LockScreenTimerGateway _gateway;

  @override
  Stream<LockScreenTapEntity> call(NoParams params) => _gateway.watchTaps();
}
