import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/bootstrap/app_services_bootstrap.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/usecases/process_lock_screen_action_use_case.dart';
import 'lock_screen_action_channel_handler.dart';
import 'lock_screen_channel_constants.dart';
import 'lock_screen_channel_method_enum.dart';

/// Runs on a `FlutterEngine` created by the native side when a lock screen
/// timer button is tapped (even with the app closed). Called by
/// `lockScreenActionMain` (`lib/main.dart`).
Future<void> runLockScreenActionEntrypoint() async {
  const channel = MethodChannel(LockScreenChannelConstants.channelName);
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      try {
        await initializeAppServices();
        final handler = LockScreenActionChannelHandler(
          getIt<ProcessLockScreenActionUseCase>(),
        );
        channel.setMethodCallHandler(handler.onMethodCall);
      } catch (error, stack) {
        AppLogger.logError(
          'Lock screen background did not start',
          error: error,
          stackTrace: stack,
        );
        await _notify(channel, LockScreenChannelMethodEnum.backgroundFailed);
        return;
      }
      await _notify(channel, LockScreenChannelMethodEnum.backgroundReady);
    },
    (error, stack) {
      AppLogger.logError(
        'Uncaught error in lock screen background',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

/// Tells the native side; without it (e.g. channel not wired) only logs.
Future<void> _notify(
  MethodChannel channel,
  LockScreenChannelMethodEnum method,
) async {
  try {
    await channel.invokeMethod<void>(method.apiValue);
  } on MissingPluginException catch (error, stack) {
    AppLogger.logWarning(
      'Native side did not hear ${method.apiValue}: $error\n$stack',
    );
  }
}
