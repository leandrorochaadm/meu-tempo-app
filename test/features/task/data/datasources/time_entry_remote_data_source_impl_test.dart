import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meu_tempo/core/data/pocketbase/record_watcher.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/task/data/datasources/time_entry_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/time_entry_model.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

import '../../../../helpers/pocketbase_test_support.dart';

const _path = '/api/collections/time_entries/records';

TimeEntryModel _model({int minutes = 30}) => TimeEntryModel(
  id: 'e1',
  targetId: 't1',
  targetType: TimerTargetTypeEnum.task,
  listId: 'l1',
  minutes: minutes,
  origin: TimeEntryOriginEnum.manual,
  occurredAt: DateTime.utc(2026, 10, 24, 13, 30),
);

Map<String, dynamic> _rec(String id, String at) => {
  'id': id,
  'collectionName': 'time_entries',
  'user': 'user-a',
  'target_id': 't1',
  'target_type': 'task',
  'list_id': 'l1',
  'origin': 'manual',
  'minutes': 30,
  'occurred_at': at,
};

void main() {
  late List<http.Request> requests;
  late FakeRealtimeSubscriber fake;
  late Future<http.Response> Function(http.Request) handler;

  TimeEntryRemoteDataSourceImpl build({bool signedIn = true}) {
    requests = [];
    fake = FakeRealtimeSubscriber();
    Future<http.Response> wrapped(http.Request r) {
      requests.add(r);
      return handler(r);
    }

    final session = signedIn
        ? signedInSession(wrapped)
        : signedOutSession(wrapped);
    return TimeEntryRemoteDataSourceImpl(session, RecordWatcher(fake));
  }

  setUp(() {
    handler = (_) async => pbJson(pbPage([]));
  });

  group('watchBetween', () {
    test('filters by UTC range and sorts by occurred_at', () async {
      handler = (_) async => pbJson(
        pbPage([
          _rec('b2', '2026-10-24 05:00:00.000Z'),
          _rec('a1', '2026-10-24 04:00:00.000Z'),
        ]),
      );
      final list = await build()
          .watchBetween(
            DateTime.utc(2026, 10, 24, 3),
            DateTime.utc(2026, 10, 25, 3),
          )
          .first;
      expect(list.map((m) => m.id), ['b2', 'a1']);
      final r = requests.single;
      expect(r.method, 'GET');
      expect(r.url.path, _path);
      expect(
        r.url.queryParameters['filter'],
        'occurred_at >= "2026-10-24 03:00:00.000Z" && '
        'occurred_at < "2026-10-25 03:00:00.000Z"',
      );
      expect(r.url.queryParameters['sort'], 'occurred_at');
    });

    test('fraction of a second is kept in the filter', () async {
      await build()
          .watchBetween(
            DateTime.utc(2026, 10, 24, 3, 0, 0, 5),
            DateTime.utc(2026, 10, 25, 3),
          )
          .first;
      expect(
        requests.single.url.queryParameters['filter'],
        contains('"2026-10-24 03:00:00.005Z"'),
      );
    });

    test('no items → empty list', () async {
      final list = await build()
          .watchBetween(DateTime.utc(2026, 10, 24), DateTime.utc(2026, 10, 25))
          .first;
      expect(list, isEmpty);
    });
  });

  group('watchByTarget', () {
    test('filters by target and keeps the server order', () async {
      final a = _rec('new', '2026-10-24 05:00:00.000Z');
      final b = _rec('mid', '2026-10-23 05:00:00.000Z');
      final c = _rec('old', '2026-10-22 05:00:00.000Z');
      handler = (_) async => pbJson(pbPage([a, b, c]));
      final ds = build();
      final list = await ds.watchByTarget('t1').first;
      expect(list.map((m) => m.id), ['new', 'mid', 'old']);
      expect(requests.single.url.queryParameters['filter'], 'target_id = "t1"');
      expect(requests.single.url.queryParameters['sort'], '-occurred_at');

      handler = (_) async => pbJson(pbPage([c, a]));
      final again = await ds.watchByTarget('t1').first;
      expect(again.map((m) => m.id), ['old', 'new']);
    });

    test('quote in the id is escaped by pb.filter', () async {
      await build().watchByTarget('t"1').first;
      expect(
        requests.single.url.queryParameters['filter'],
        r'target_id = "t\"1"',
      );
    });

    test('reloads on realtime event and cancel unsubscribes', () async {
      var call = 0;
      handler = (_) async {
        call++;
        return pbJson(
          pbPage([
            _rec('a1', '2026-10-24 05:00:00.000Z'),
            if (call > 1) _rec('b2', '2026-10-23 05:00:00.000Z'),
          ]),
        );
      };
      final ds = build();
      final emitted = <List<TimeEntryModel>>[];
      final sub = ds.watchByTarget('t1').listen(emitted.add);
      await pumpEventQueue();
      expect(emitted.single.length, 1);

      fake.emit('time_entries/*');
      await Future<void>.delayed(
        RecordWatcher.burstWindow + const Duration(milliseconds: 50),
      );
      expect(emitted.last.length, 2);

      await sub.cancel();
      await pumpEventQueue();
      expect(fake.unsubscribeCount, greaterThan(0));
    });
  });

  test('add posts exactly the 7 keys including user', () async {
    handler = (_) async => pbJson(_rec('new1', '2026-10-24 13:30:00.000Z'));
    await build().add(_model());
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, _path);
    expect(jsonDecode(requests.single.body), {
      'target_id': 't1',
      'target_type': 'task',
      'list_id': 'l1',
      'minutes': 30,
      'origin': 'manual',
      'occurred_at': '2026-10-24 13:30:00.000Z',
      'user': 'user-a',
    });
  });

  group('update', () {
    test('patches the 6 keys without user', () async {
      handler = (_) async => pbJson(_rec('e1', '2026-10-24 13:30:00.000Z'));
      await build().update(_model(minutes: 55));
      expect(requests.single.method, 'PATCH');
      expect(requests.single.url.path, '$_path/e1');
      expect(jsonDecode(requests.single.body), {
        'target_id': 't1',
        'target_type': 'task',
        'list_id': 'l1',
        'minutes': 55,
        'origin': 'manual',
        'occurred_at': '2026-10-24 13:30:00.000Z',
      });
    });

    test('404 → NotFoundException', () async {
      handler = (_) async => pbError(404);
      await expectLater(
        build().update(_model()),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('204 passes', () async {
      handler = (_) async => http.Response('', 204);
      await build().delete('e1');
      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '$_path/e1');
    });

    test('404 is ignored', () async {
      handler = (_) async => pbError(404);
      await build().delete('e1');
    });

    test('403 → PermissionException', () async {
      handler = (_) async => pbError(403);
      await expectLater(
        build().delete('e1'),
        throwsA(isA<PermissionException>()),
      );
    });
  });

  group('errors', () {
    test('no network on add → NetworkException', () async {
      handler = (_) async => throw const SocketException('down');
      await expectLater(
        build().add(_model()),
        throwsA(isA<NetworkException>()),
      );
    });

    test('500 on add → ServerException', () async {
      handler = (_) async => pbError(500);
      await expectLater(build().add(_model()), throwsA(isA<ServerException>()));
    });
  });

  test('signed out → UnauthenticatedException and no request', () async {
    final ds = build(signedIn: false);
    final start = DateTime.utc(2026, 10, 24);
    expect(
      () => ds.watchBetween(start, start),
      throwsA(isA<UnauthenticatedException>()),
    );
    expect(
      () => ds.watchByTarget('t1'),
      throwsA(isA<UnauthenticatedException>()),
    );
    for (final call in <Future<void> Function()>[
      () => ds.add(_model()),
      () => ds.update(_model()),
      () => ds.delete('e1'),
    ]) {
      await expectLater(call(), throwsA(isA<UnauthenticatedException>()));
    }
    expect(requests, isEmpty);
  });
}
