import 'package:injectable/injectable.dart';

import '../domain/gateways/overrun_alert_scheduler.dart';
import 'gateways/in_app_overrun_alert_scheduler.dart';

/// Single place that picks the overrun alert implementation. Today: inside the
/// app, on every platform.
@module
abstract class OverrunAlertSchedulerModule {
  @lazySingleton
  OverrunAlertScheduler get overrunAlertScheduler =>
      InAppOverrunAlertScheduler();
}
