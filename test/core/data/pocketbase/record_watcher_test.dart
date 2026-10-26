import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/data/pocketbase/realtime_subscriber.dart';
import 'package:meu_tempo/core/data/pocketbase/record_watcher.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:pocketbase/pocketbase.dart';

class FakeRealtimeSubscriber implements RealtimeSubscriber {
  final Map<String, List<void Function()>> handlers = {};
  final List<String> cancelled = [];
  Completer<void>? gate;
  Object? failure;

  void fire(String topic) {
    for (final handler in List.of(handlers[topic] ?? const [])) {
      handler();
    }
  }

  @override
  Future<RealtimeUnsubscribe> subscribe(
    String topic,
    void Function() onEvent,
  ) async {
    if (gate != null) await gate!.future;
    if (failure != null) throw failure!;
    handlers.putIfAbsent(topic, () => []).add(onEvent);
    return () async {
      cancelled.add(topic);
      handlers[topic]?.remove(onEvent);
    };
  }
}

const _all = 'tasks/*';
const _connect = 'PB_CONNECT';
const _burst = RecordWatcher.burstWindow;

void main() {
  late FakeRealtimeSubscriber subscriber;
  late RecordWatcher watcher;

  setUp(() {
    subscriber = FakeRealtimeSubscriber();
    watcher = RecordWatcher(subscriber);
  });

  void run(void Function(FakeAsync async) body) => fakeAsync(body);

  test('emits the initial load once', () {
    run((async) {
      var loads = 0;
      final values = <int>[];
      watcher
          .watch(collection: 'tasks', load: () async => ++loads)
          .listen(values.add);
      async.flushMicrotasks();
      expect(loads, 1);
      expect(values, [1]);
    });
  });

  test('reloads after an event, past the burst window', () {
    run((async) {
      var loads = 0;
      final values = <int>[];
      watcher
          .watch(collection: 'tasks', load: () async => ++loads)
          .listen(values.add);
      async.flushMicrotasks();
      subscriber.fire(_all);
      async.elapse(_burst);
      async.flushMicrotasks();
      expect(values, [1, 2]);
    });
  });

  test('burst of 50 events reloads once', () {
    run((async) {
      var loads = 0;
      watcher
          .watch(collection: 'tasks', load: () async => ++loads)
          .listen((_) {});
      async.flushMicrotasks();
      for (var i = 0; i < 50; i++) {
        subscriber.fire(_all);
      }
      async.elapse(_burst * 2);
      async.flushMicrotasks();
      expect(loads, 2);
    });
  });

  test('event during a slow load adds exactly one load, never parallel', () {
    run((async) {
      var running = 0;
      var maxRunning = 0;
      var loads = 0;
      watcher
          .watch(
            collection: 'tasks',
            load: () async {
              loads++;
              running++;
              if (running > maxRunning) maxRunning = running;
              await Future<void>.delayed(const Duration(seconds: 1));
              running--;
              return loads;
            },
          )
          .listen((_) {});
      async.flushMicrotasks();
      subscriber.fire(_all);
      subscriber.fire(_all);
      async.elapse(const Duration(seconds: 5));
      expect(loads, 2);
      expect(maxRunning, 1);
    });
  });

  test('PB_CONNECT reloads', () {
    run((async) {
      var loads = 0;
      watcher
          .watch(collection: 'tasks', load: () async => ++loads)
          .listen((_) {});
      async.flushMicrotasks();
      subscriber.fire(_connect);
      async.elapse(_burst);
      async.flushMicrotasks();
      expect(loads, 2);
    });
  });

  test('ClientException 404 becomes NotFoundException and stream goes on', () {
    run((async) {
      var calls = 0;
      final values = <int>[];
      final errors = <Object>[];
      watcher
          .watch(
            collection: 'tasks',
            load: () async {
              if (++calls == 1) throw ClientException(statusCode: 404);
              return calls;
            },
          )
          .listen(values.add, onError: errors.add);
      async.flushMicrotasks();
      expect(errors.single, isA<NotFoundException>());
      subscriber.fire(_all);
      async.elapse(_burst);
      async.flushMicrotasks();
      expect(values, [2]);
    });
  });

  test(
    'AppException passes through and StateError becomes ServerException',
    () {
      run((async) {
        final errors = <Object>[];
        var calls = 0;
        watcher
            .watch<int>(
              collection: 'tasks',
              load: () async {
                if (++calls == 1) throw const UnauthenticatedException();
                throw StateError('boom');
              },
            )
            .listen((_) {}, onError: errors.add);
        async.flushMicrotasks();
        subscriber.fire(_all);
        async.elapse(_burst);
        async.flushMicrotasks();
        expect(errors[0], isA<UnauthenticatedException>());
        expect(errors[1], isA<ServerException>());
      });
    },
  );

  test(
    'failing subscribe emits NetworkException and keeps the initial value',
    () {
      run((async) {
        subscriber.failure = ClientException(statusCode: 0);
        final values = <int>[];
        final errors = <Object>[];
        watcher
            .watch(collection: 'tasks', load: () async => 7)
            .listen(values.add, onError: errors.add);
        async.flushMicrotasks();
        expect(values, [7]);
        expect(errors.first, isA<NetworkException>());
      });
    },
  );

  test('cancel unsubscribes both topics and stops emitting', () {
    run((async) {
      var loads = 0;
      final values = <int>[];
      final completer = Completer<int>();
      final sub = watcher
          .watch(
            collection: 'tasks',
            load: () {
              loads++;
              return loads == 2 ? completer.future : Future.value(loads);
            },
          )
          .listen(values.add);
      async.flushMicrotasks();
      subscriber.fire(_all);
      async.elapse(_burst);
      async.flushMicrotasks();
      expect(loads, 2);
      sub.cancel();
      async.flushMicrotasks();
      completer.complete(99);
      async.flushMicrotasks();
      expect(subscriber.cancelled, containsAll([_all, _connect]));
      expect(values, [1]);
      subscriber.fire(_all);
      async.elapse(_burst);
      expect(loads, 2);
    });
  });

  test('subscribe finishing after cancel is cancelled on return', () {
    run((async) {
      subscriber.gate = Completer<void>();
      final sub = watcher
          .watch(collection: 'tasks', load: () async => 1)
          .listen((_) {});
      async.flushMicrotasks();
      sub.cancel();
      async.flushMicrotasks();
      subscriber.gate!.complete();
      async.flushMicrotasks();
      expect(subscriber.cancelled, containsAll([_all, _connect]));
    });
  });

  test('two watches are independent', () {
    run((async) {
      var loads = 0;
      Stream<int> open() =>
          watcher.watch(collection: 'tasks', load: () async => ++loads);
      open().listen((_) {});
      open().listen((_) {});
      async.flushMicrotasks();
      expect(loads, 2);
      expect(subscriber.handlers[_all], hasLength(2));
    });
  });
}
