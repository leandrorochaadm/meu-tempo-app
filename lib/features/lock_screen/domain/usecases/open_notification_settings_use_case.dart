import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../gateways/lock_screen_timer_gateway.dart';

/// Opens the phone settings on the app notifications screen (banner button).
@lazySingleton
class OpenNotificationSettingsUseCase implements UseCase<Unit, NoParams> {
  const OpenNotificationSettingsUseCase(this._gateway);

  final LockScreenTimerGateway _gateway;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _gateway.openNotificationSettings();
}
