import 'dart:async';

import 'package:flutter/services.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/usecases/process_lock_screen_action_use_case.dart';
import '../models/lock_screen_action_reply_model.dart';
import '../models/lock_screen_action_request_model.dart';
import '../models/lock_screen_timer_payload_model.dart';
import 'lock_screen_channel_constants.dart';
import 'lock_screen_channel_method_enum.dart';

/// Channel adapter (no business rule): converts the native payload, calls the
/// [ProcessLockScreenActionUseCase] with a time limit and translates the
/// `Either` into a reply. Logs the outcome (action, reply, failure type —
/// never title nor list name).
class LockScreenActionChannelHandler {
  LockScreenActionChannelHandler(
    this._processAction, {
    DateTime Function() clock = DateTime.now,
    Duration timeout = LockScreenChannelConstants.actionTimeout,
  }) : _clock = clock,
       _timeout = timeout;

  final ProcessLockScreenActionUseCase _processAction;
  final DateTime Function() _clock;
  final Duration _timeout;
  Future<void> _tail = Future<void>.value();
  Future<void> _actionInFlight = Future<void>.value();

  /// `MethodChannel` handler. Only `handleAction` comes from the native side;
  /// anything else becomes a `MissingPluginException`.
  Future<Object?> onMethodCall(MethodCall call) async {
    switch (LockScreenChannelMethodEnum.fromApi(call.method)) {
      case LockScreenChannelMethodEnum.handleAction:
        return handleAction(call.arguments);
      case LockScreenChannelMethodEnum.backgroundReady:
      case LockScreenChannelMethodEnum.backgroundFailed:
      case null:
        throw MissingPluginException(call.method);
    }
  }

  /// One tap at a time, in the order the native side sent them. The queue
  /// waits for the real action to finish — not only the reply, which may come
  /// earlier by timeout — so "pause" and "confirm" never run together.
  Future<Map<String, Object?>> handleAction(Object? arguments) {
    final next = _tail.then((_) => _process(arguments));
    _tail = next.then<void>(
      (_) => _actionInFlight,
      onError: (Object _) => _actionInFlight,
    );
    return next;
  }

  Future<Map<String, Object?>> _process(Object? arguments) async {
    final request = LockScreenActionRequestModel.fromMap(arguments);
    if (request == null) {
      AppLogger.logWarning('Lock screen action ignored: invalid payload');
      return const LockScreenActionReplyModel.unchanged().toMap();
    }
    try {
      final action = _processAction(request.toParams(_clock()));
      _actionInFlight = action.then<void>((_) {}, onError: (Object _) {});
      final result = await action.timeout(_timeout);
      final reply = result.fold(
        (failure) {
          // Logged no-op (e.g. no session): only action and failure type.
          AppLogger.logWarning(
            'Lock screen action ${request.action.apiValue} not applied: '
            '${failure.runtimeType}',
          );
          return const LockScreenActionReplyModel.unchanged();
        },
        (timer) => timer == null
            ? const LockScreenActionReplyModel.clear()
            : LockScreenActionReplyModel.show(
                LockScreenTimerPayloadModel.fromEntity(timer, now: _clock()),
              ),
      );
      AppLogger.logInfo(
        'Lock screen action ${request.action.apiValue} -> '
        '${reply.reply.apiValue}',
      );
      return reply.toMap();
    } on TimeoutException {
      AppLogger.logWarning('Lock screen action timed out');
      return const LockScreenActionReplyModel.unchanged().toMap();
    } catch (error, stack) {
      AppLogger.logError(
        'Lock screen action failed',
        error: error,
        stackTrace: stack,
      );
      return const LockScreenActionReplyModel.unchanged().toMap();
    }
  }
}
