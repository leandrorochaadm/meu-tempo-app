import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/overrun_alert_entity.dart';
import '../gateways/overrun_alert_scheduler.dart';

/// Alerts the app must show inside the open screen.
@lazySingleton
class WatchOverrunAlertsUseCase
    implements StreamUseCase<OverrunAlertEntity, NoParams> {
  const WatchOverrunAlertsUseCase(this._scheduler);

  final OverrunAlertScheduler _scheduler;

  @override
  Stream<OverrunAlertEntity> call(NoParams params) => _scheduler.watchAlerts();
}
