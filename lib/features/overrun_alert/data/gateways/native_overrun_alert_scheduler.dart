import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fpdart/fpdart.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/overrun_alert_entity.dart';
import '../../domain/entities/overrun_alert_plan_entity.dart';
import '../../domain/gateways/overrun_alert_scheduler.dart';
import '../../domain/overrun_alert_failures.dart';
import 'overrun_alert_notification_constants.dart';

/// Overrun alerts as system notifications scheduled ahead (Android and
/// iPhone), so they arrive with the app fully closed. No rule here: every time
/// comes from the plan (`nextAlertAt` / `alertAfter`). Never throws.
class NativeOverrunAlertScheduler implements OverrunAlertScheduler {
  NativeOverrunAlertScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function() now = DateTime.now,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _now = now;

  static const _body = 'Se já terminou, pause ou pare o cronômetro.';

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _now;

  Future<void>? _initialization;
  OverrunAlertPlanEntity? _plan;

  @override
  Future<Either<Failure, Unit>> schedule(OverrunAlertPlanEntity plan) async {
    if (plan == _plan) return const Right(unit); // same plan in this process
    _plan = null;
    try {
      await _ensureInitialized();
      // iPhone: the system dialog only shows the first time; afterwards it
      // answers right away. Android: null (POST_NOTIFICATIONS is asked at the
      // first start).
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true);
      await _cancelSeries();
      final now = _now();
      final details = _details(plan);
      final title = _title(plan);
      var at = plan.nextAlertAt(now);
      for (
        var i = 0;
        i < OverrunAlertNotificationConstants.scheduledAheadCount;
        i++
      ) {
        final id = OverrunAlertNotificationConstants.firstNotificationId + i;
        if (at.isAfter(now)) {
          await _plugin.zonedSchedule(
            id: id,
            title: title,
            body: _body,
            scheduledDate: tz.TZDateTime.from(at, tz.UTC),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } else {
          // Exactly now (`nextAlertAt` uses >=): the system does not schedule
          // in the past, so it shows right away.
          await _plugin.show(
            id: id,
            title: title,
            body: _body,
            notificationDetails: details,
          );
        }
        at = plan.alertAfter(at);
      }
      _plan = plan;
      return const Right(unit);
    } catch (error, stack) {
      _logFailure('schedule', error, stack);
      return const Left(OverrunAlertPlatformFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> cancel() async {
    _plan = null;
    try {
      await _ensureInitialized();
      await _cancelSeries();
      return const Right(unit);
    } catch (error, stack) {
      _logFailure('cancel', error, stack);
      return const Left(OverrunAlertPlatformFailure());
    }
  }

  /// On the phone the alert goes out through the system, even with the app
  /// open: nothing to show in the screen (the banner stays on the web).
  @override
  Stream<OverrunAlertEntity> watchAlerts() => const Stream.empty();

  /// Cancels pending and delivered alerts, only on the series ids. Never
  /// the bulk cancel: it must not touch the timer notification.
  Future<void> _cancelSeries() async {
    for (
      var i = 0;
      i < OverrunAlertNotificationConstants.scheduledAheadCount;
      i++
    ) {
      await _plugin.cancel(
        id: OverrunAlertNotificationConstants.firstNotificationId + i,
      );
    }
  }

  /// Once per process (the app and the background engine have their own).
  /// Failed → reset so the next call tries again.
  Future<void> _ensureInitialized() => _initialization ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(
            OverrunAlertNotificationConstants.androidSmallIcon,
          ),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      )
      .then<void>(
        (_) {},
        onError: (Object error, StackTrace stack) {
          _initialization = null;
          Error.throwWithStackTrace(error, stack);
        },
      );

  String _title(OverrunAlertPlanEntity plan) =>
      '“${plan.title}” passou do tempo estimado.';

  NotificationDetails _details(OverrunAlertPlanEntity plan) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          OverrunAlertNotificationConstants.androidChannelId,
          'Tempo estourado',
          channelDescription: 'Avisa quando a tarefa passa do tempo estimado',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          // Each alert leaves when the next arrives: only one in the shade.
          timeoutAfter: plan.repeatInterval.inMilliseconds,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          threadIdentifier:
              OverrunAlertNotificationConstants.darwinThreadIdentifier,
        ),
      );

  void _logFailure(String action, Object error, StackTrace stack) =>
      AppLogger.logWarning(
        'Overrun alert $action failed: ${error.runtimeType}\n$stack',
        name: OverrunAlertNotificationConstants.logName,
      );
}
