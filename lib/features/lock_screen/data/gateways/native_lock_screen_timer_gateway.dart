import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/lock_screen_permission_status_enum.dart';
import '../../domain/entities/lock_screen_tap_entity.dart';
import '../../domain/entities/lock_screen_timer_entity.dart';
import '../../domain/gateways/lock_screen_timer_gateway.dart';
import '../../domain/lock_screen_failures.dart';
import '../models/lock_screen_tap_payload_model.dart';
import '../models/lock_screen_timer_payload_model.dart';
import 'lock_screen_timer_channel_constants.dart';
import 'lock_screen_timer_channel_method_enum.dart';

/// Android (foreground service) and iPhone (Live Activity) speak the same
/// channel protocol; only converts and relays. Any channel failure becomes
/// [LockScreenPlatformFailure].
class NativeLockScreenTimerGateway implements LockScreenTimerGateway {
  NativeLockScreenTimerGateway({
    MethodChannel methodChannel = const MethodChannel(
      LockScreenTimerChannelConstants.methodChannelName,
    ),
    EventChannel tapChannel = const EventChannel(
      LockScreenTimerChannelConstants.tapChannelName,
    ),
    DateTime Function() clock = DateTime.now,
    Duration callTimeout = LockScreenTimerChannelConstants.callTimeout,
  }) : _methodChannel = methodChannel,
       _tapChannel = tapChannel,
       _clock = clock,
       _callTimeout = callTimeout;

  static const _logName = 'NativeLockScreenTimerGateway';

  final MethodChannel _methodChannel;
  final EventChannel _tapChannel;
  final DateTime Function() _clock;
  final Duration _callTimeout;

  @override
  Future<Either<Failure, Unit>> show(LockScreenTimerEntity timer) => _invoke(
    LockScreenTimerChannelMethodEnum.show,
    arguments: LockScreenTimerPayloadModel.fromEntity(
      timer,
      now: _clock(),
    ).toMap(),
    convert: (_) => unit,
  );

  @override
  Future<Either<Failure, Unit>> clear() =>
      _invoke(LockScreenTimerChannelMethodEnum.clear, convert: (_) => unit);

  @override
  Future<Either<Failure, LockScreenPermissionStatusEnum>>
  getPermissionStatus() => _invoke(
    LockScreenTimerChannelMethodEnum.getPermissionStatus,
    convert: _toStatus,
  );

  @override
  Future<Either<Failure, LockScreenPermissionStatusEnum>> requestPermission() =>
      _invoke(
        LockScreenTimerChannelMethodEnum.requestPermission,
        withTimeout: false,
        convert: _toStatus,
      );

  @override
  Future<Either<Failure, Unit>> openNotificationSettings() => _invoke(
    LockScreenTimerChannelMethodEnum.openNotificationSettings,
    convert: (_) => unit,
  );

  @override
  Stream<LockScreenTapEntity> watchTaps() => _tapChannel
      .receiveBroadcastStream()
      .handleError((Object error) {
        AppLogger.logWarning(
          'tap stream error: ${error.runtimeType}',
          name: _logName,
        );
      })
      .map(LockScreenTapPayloadModel.fromMap)
      .where((tap) {
        if (tap == null) {
          AppLogger.logWarning('invalid tap discarded', name: _logName);
        }
        return tap != null;
      })
      .map((tap) => tap!.toEntity());

  static LockScreenPermissionStatusEnum _toStatus(Object? raw) =>
      LockScreenPermissionStatusEnum.fromApi(raw is String ? raw : null);

  Future<Either<Failure, T>> _invoke<T>(
    LockScreenTimerChannelMethodEnum method, {
    Object? arguments,
    bool withTimeout = true,
    required T Function(Object? raw) convert,
  }) async {
    try {
      var call = _methodChannel.invokeMethod<Object?>(
        method.apiValue,
        arguments,
      );
      if (withTimeout) call = call.timeout(_callTimeout);
      return Right(convert(await call));
    } on PlatformException catch (error) {
      return _fail(method, error);
    } on MissingPluginException catch (error) {
      return _fail(method, error);
    } on TimeoutException catch (error) {
      return _fail(method, error);
    }
  }

  Either<Failure, T> _fail<T>(
    LockScreenTimerChannelMethodEnum method,
    Object error,
  ) {
    AppLogger.logWarning(
      '${method.apiValue} failed: ${error.runtimeType}',
      name: _logName,
    );
    return const Left(LockScreenPlatformFailure());
  }
}
