import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/overrun_alert/data/gateways/in_app_overrun_alert_scheduler.dart';
import 'package:meu_tempo/features/overrun_alert/data/gateways/native_overrun_alert_scheduler.dart';
import 'package:meu_tempo/features/overrun_alert/data/overrun_alert_scheduler_module.dart';

class _Module extends OverrunAlertSchedulerModule {}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('android uses native scheduler', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(_Module().overrunAlertScheduler, isA<NativeOverrunAlertScheduler>());
  });

  test('iOS uses native scheduler', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(_Module().overrunAlertScheduler, isA<NativeOverrunAlertScheduler>());
  });

  test('other platforms use in-app scheduler', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    expect(_Module().overrunAlertScheduler, isA<InAppOverrunAlertScheduler>());
  });
}
