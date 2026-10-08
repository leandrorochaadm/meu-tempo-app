import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../domain/gateways/overrun_alert_scheduler.dart';
import 'gateways/in_app_overrun_alert_scheduler.dart';
import 'gateways/native_overrun_alert_scheduler.dart';

/// Single place that picks the overrun alert implementation: system
/// notifications on Android and iPhone, inside the app on the web.
@module
abstract class OverrunAlertSchedulerModule {
  @lazySingleton
  OverrunAlertScheduler get overrunAlertScheduler {
    if (kIsWeb) return InAppOverrunAlertScheduler(); // web: only with app open
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS => NativeOverrunAlertScheduler(),
      _ => InAppOverrunAlertScheduler(),
    };
  }
}
