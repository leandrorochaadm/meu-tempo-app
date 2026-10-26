import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../error/exceptions.dart';
import '../../error/pocketbase_error_mapper.dart';
import '../../logging/app_logger.dart';
import 'realtime_subscriber.dart';

/// Turns the PocketBase realtime into a [Stream] with the same contract as
/// a snapshot stream: emits the current state on listen and again after
/// every change.
///
/// [watch] runs the full query ([load], with the server filter and order) and
/// reloads on each event. The server only delivers events for records the
/// owner rule lets the user see. The stream is cold: each `listen` opens its
/// own subscriptions and does its own `load`.
@lazySingleton
class RecordWatcher {
  RecordWatcher(this._subscriber);

  /// Events closer than this become a single reload.
  static const Duration burstWindow = Duration(milliseconds: 100);

  final RealtimeSubscriber _subscriber;

  Stream<T> watch<T>({
    required String collection,
    required Future<T> Function() load,
  }) {
    late final StreamController<T> controller;
    final unsubscribes = <RealtimeUnsubscribe>[];
    Timer? burstTimer;
    var cancelled = false;
    var loading = false;
    var pending = false;

    void emitError(Object error, StackTrace stackTrace) {
      if (cancelled) return;
      if (error is AppException) {
        controller.addError(error, stackTrace);
      } else if (error is ClientException) {
        controller.addError(mapPocketBaseError(error), stackTrace);
      } else {
        AppLogger.logError(
          'Unexpected error while watching $collection',
          error: error,
          stackTrace: stackTrace,
        );
        controller.addError(const ServerException(), stackTrace);
      }
    }

    Future<void> runLoad() async {
      if (cancelled) return;
      if (loading) {
        pending = true;
        return;
      }
      loading = true;
      try {
        do {
          pending = false;
          try {
            final value = await load();
            if (!cancelled) controller.add(value);
          } catch (error, stackTrace) {
            emitError(error, stackTrace);
          }
        } while (pending && !cancelled);
      } finally {
        loading = false;
      }
    }

    void onEvent() {
      if (cancelled) return;
      if (loading) {
        pending = true;
        return;
      }
      burstTimer?.cancel();
      burstTimer = Timer(burstWindow, () {
        burstTimer = null;
        unawaited(runLoad());
      });
    }

    Future<void> cancelOne(RealtimeUnsubscribe unsubscribe) async {
      try {
        await unsubscribe();
      } catch (error) {
        AppLogger.logWarning('Could not cancel subscription: $error');
      }
    }

    Future<void> subscribeTo(String topic) async {
      try {
        final unsubscribe = await _subscriber.subscribe(topic, onEvent);
        if (cancelled) {
          await cancelOne(unsubscribe);
        } else {
          unsubscribes.add(unsubscribe);
        }
      } catch (error, stackTrace) {
        emitError(error, stackTrace);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        unawaited(runLoad());
        unawaited(subscribeTo(RealtimeTopics.allRecords(collection)));
        unawaited(subscribeTo(RealtimeTopics.connect));
      },
      onCancel: () async {
        cancelled = true;
        burstTimer?.cancel();
        burstTimer = null;
        final toCancel = List.of(unsubscribes);
        unsubscribes.clear();
        await Future.wait(toCancel.map(cancelOne));
      },
    );
    return controller.stream;
  }
}
