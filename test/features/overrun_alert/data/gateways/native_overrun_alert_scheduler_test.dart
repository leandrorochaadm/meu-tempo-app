import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/overrun_alert/data/gateways/native_overrun_alert_scheduler.dart';
import 'package:meu_tempo/features/overrun_alert/domain/entities/overrun_alert_plan_entity.dart';
import 'package:meu_tempo/features/overrun_alert/domain/overrun_alert_failures.dart';
import 'package:meu_tempo/features/overrun_alert/domain/overrun_alert_rules.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockIosPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;
  var now = DateTime(2026, 10, 7, 10);

  final plan = OverrunAlertPlanEntity(
    targetId: 't1',
    title: 'Tela de login',
    firstAlertAt: DateTime(2026, 10, 7, 10, 30),
    repeatInterval: OverrunAlertRules.overrunRepeatInterval,
  );
  final otherPlan = OverrunAlertPlanEntity(
    targetId: 't2',
    title: 'Outra',
    firstAlertAt: DateTime(2026, 10, 7, 11),
    repeatInterval: OverrunAlertRules.overrunRepeatInterval,
  );

  NativeOverrunAlertScheduler build() =>
      NativeOverrunAlertScheduler(plugin: plugin, now: () => now);

  void stubZoned() {
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    ).thenAnswer((_) async {});
  }

  VerificationResult verifyZoned() => verify(
    () => plugin.zonedSchedule(
      id: any(named: 'id'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      scheduledDate: any(named: 'scheduledDate'),
      notificationDetails: any(named: 'notificationDetails'),
      androidScheduleMode: any(named: 'androidScheduleMode'),
    ),
  );

  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(tz.TZDateTime.utc(2026));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  setUp(() {
    now = DateTime(2026, 10, 7, 10);
    plugin = _MockPlugin();
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
        onDidReceiveBackgroundNotificationResponse: any(
          named: 'onDidReceiveBackgroundNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(null);
    stubZoned();
  });

  VerificationResult verifyInitialize() => verify(
    () => plugin.initialize(
      settings: any(named: 'settings'),
      onDidReceiveNotificationResponse: any(
        named: 'onDidReceiveNotificationResponse',
      ),
      onDidReceiveBackgroundNotificationResponse: any(
        named: 'onDidReceiveBackgroundNotificationResponse',
      ),
    ),
  );

  test('should initialize once', () async {
    final scheduler = build();

    await scheduler.schedule(plan);
    await scheduler.schedule(otherPlan);

    verifyInitialize().called(1);
  });

  test('should schedule the series ahead from the domain times', () async {
    final result = await build().schedule(plan);

    expect(result, const Right<Failure, Unit>(unit));
    final captured = verify(
      () => plugin.zonedSchedule(
        id: captureAny(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: captureAny(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: captureAny(named: 'androidScheduleMode'),
      ),
    ).captured;
    expect(captured.length, 48 * 3);
    final ids = [for (var i = 0; i < 48; i++) captured[i * 3] as int];
    final dates = [
      for (var i = 0; i < 48; i++) captured[i * 3 + 1] as tz.TZDateTime,
    ];
    expect(ids, [for (var i = 0; i < 48; i++) 5100 + i]);
    expect(dates.first, tz.TZDateTime.from(plan.nextAlertAt(now), tz.UTC));
    expect(dates[1], tz.TZDateTime.from(DateTime(2026, 10, 7, 11, 30), tz.UTC));
    expect(
      dates.last,
      tz.TZDateTime.from(
        DateTime(2026, 10, 7, 10, 30).add(const Duration(hours: 47)),
        tz.UTC,
      ),
    );
    expect(captured[2], AndroidScheduleMode.inexactAllowWhileIdle);
  });

  test('should use title and channel', () async {
    await build().schedule(plan);

    final captured = verify(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: captureAny(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: captureAny(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    ).captured;
    expect(
      captured.whereType<String>().first,
      '“Tela de login” passou do tempo estimado.',
    );
    final android = captured.whereType<NotificationDetails>().first.android!;
    expect(android.channelId, 'overrun_alert');
    expect(android.importance, Importance.high);
    expect(android.timeoutAfter, 3600000);
  });

  test('should cancel the previous series before scheduling', () async {
    await build().schedule(plan);

    verifyInOrder([
      () => plugin.cancel(id: 5100),
      () => plugin.cancel(id: 5147),
      () => plugin.zonedSchedule(
        id: 5100,
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    ]);
  });

  test('should not reschedule the same plan', () async {
    final scheduler = build();
    await scheduler.schedule(plan);
    clearInteractions(plugin);

    final result = await scheduler.schedule(plan);

    expect(result, const Right<Failure, Unit>(unit));
    verifyNoMoreInteractions(plugin);
  });

  test('should start from the next alert when opened late', () async {
    now = DateTime(2026, 10, 7, 12, 10);

    await build().schedule(plan);

    final captured = verify(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: captureAny(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    ).captured;
    expect(
      captured.first,
      tz.TZDateTime.from(DateTime(2026, 10, 7, 12, 30), tz.UTC),
    );
    verifyNever(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
      ),
    );
  });

  test('should show immediately when an alert is due now', () async {
    now = DateTime(2026, 10, 7, 10, 30);

    await build().schedule(plan);

    verify(
      () => plugin.show(
        id: 5100,
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
      ),
    ).called(1);
    final captured = verify(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: captureAny(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    ).captured;
    expect(captured.length, 47);
    expect(
      captured.first,
      tz.TZDateTime.from(DateTime(2026, 10, 7, 11, 30), tz.UTC),
    );
  });

  test('should request iPhone permission before scheduling', () async {
    final ios = _MockIosPlugin();
    when(
      () => ios.requestPermissions(
        alert: any(named: 'alert'),
        badge: any(named: 'badge'),
        sound: any(named: 'sound'),
        provisional: any(named: 'provisional'),
        critical: any(named: 'critical'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(ios);

    await build().schedule(plan);

    verify(
      () => ios.requestPermissions(
        alert: true,
        badge: any(named: 'badge'),
        sound: true,
        provisional: any(named: 'provisional'),
        critical: any(named: 'critical'),
      ),
    ).called(1);
  });

  test('should work without iPhone implementation', () async {
    final result = await build().schedule(plan);

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('should cancel only the series ids', () async {
    final result = await build().cancel();

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => plugin.cancel(id: any(named: 'id'))).called(48);
    verifyNever(() => plugin.cancelAll());
  });

  test('should return failure and retry when the platform fails', () async {
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    ).thenThrow(PlatformException(code: 'x'));
    final scheduler = build();

    final first = await scheduler.schedule(plan);
    expect(first, const Left<Failure, Unit>(OverrunAlertPlatformFailure()));
    clearInteractions(plugin);
    stubZoned();

    final second = await scheduler.schedule(plan);

    expect(second, const Right<Failure, Unit>(unit));
    verifyZoned().called(48);
  });

  test('should retry initialization after it fails', () async {
    var calls = 0;
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
        onDidReceiveBackgroundNotificationResponse: any(
          named: 'onDidReceiveBackgroundNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw PlatformException(code: 'x');
      return true;
    });
    final scheduler = build();

    final first = await scheduler.schedule(plan);
    final second = await scheduler.schedule(plan);

    expect(first, const Left<Failure, Unit>(OverrunAlertPlatformFailure()));
    expect(second, const Right<Failure, Unit>(unit));
    expect(calls, 2);
  });

  test('should not emit in-app alerts', () {
    expect(build().watchAlerts(), emitsDone);
  });
}
