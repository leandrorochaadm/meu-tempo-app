import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meu_tempo/core/data/pocketbase/record_watcher.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/task/data/datasources/recurring_task_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/recurring_task_model.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';

import '../../../../helpers/pocketbase_test_support.dart';

const _path = '/api/collections/recurring_tasks/records';
const _claimsPath = '/api/collections/recurring_task_claims/records';

const _modelKeys = {
  'title',
  'list',
  'estimated_minutes',
  'importance',
  'weekdays',
  'created_at',
  'last_generated_on',
};

RecurringTaskModel _model(
  String id, {
  String title = 'Academia',
  DateTime? lastGeneratedOn,
}) => RecurringTaskModel(
  id: id,
  title: title,
  listId: 'l1',
  estimatedMinutes: 60,
  importance: ImportanceEnum.high,
  weekdays: const [WeekdayEnum.monday],
  createdAt: DateTime.utc(2026, 10, 1, 3),
  lastGeneratedOn: lastGeneratedOn,
);

Map<String, dynamic> _rec(String id, {String? lastGeneratedOn}) => {
  'id': id,
  'collectionName': 'recurring_tasks',
  'user': 'user-a',
  'title': 'Modelo $id',
  'list': 'l1',
  'estimated_minutes': 60,
  'importance': 'high',
  'weekdays': ['monday'],
  'created_at': '2026-10-01 03:00:00.000Z',
  'last_generated_on': lastGeneratedOn ?? '',
};

/// Reads the requests of a `POST /api/batch` (JSON or multipart payload).
List<Map<String, dynamic>> batchRequests(http.Request r) {
  expect(r.method, 'POST');
  expect(r.url.path, '/api/batch');
  final Object? decoded;
  if (r.headers['content-type']?.startsWith('multipart/') ?? false) {
    final match = RegExp(
      r'name="@jsonPayload"\r\n\r\n(.*?)\r\n--',
      dotAll: true,
    ).firstMatch(r.body);
    decoded = jsonDecode(match!.group(1)!);
  } else {
    decoded = jsonDecode(r.body);
  }
  final requests = (decoded! as Map<String, dynamic>)['requests'] as List;
  return requests.cast<Map<String, dynamic>>();
}

http.Response _batchOk(int n) => pbJson([
  for (var i = 0; i < n; i++) {'status': 200, 'body': <String, dynamic>{}},
]);

http.Response _batchFail(int index, http.Response inner) => pbError(
  400,
  data: {
    'requests': {
      '$index': {
        'code': 'batch_request_failed',
        'message': 'Batch request failed.',
        'response': jsonDecode(inner.body),
      },
    },
  },
);

String _summary(Map<String, dynamic> r) => '${r['method']} ${r['url']}';

bool _isBatch(http.Request r) => r.url.path == '/api/batch';

void main() {
  late List<http.Request> requests;
  late FakeRealtimeSubscriber fake;
  late Future<http.Response> Function(http.Request) handler;

  RecurringTaskRemoteDataSourceImpl build({bool signedIn = true}) {
    requests = [];
    fake = FakeRealtimeSubscriber();
    Future<http.Response> wrapped(http.Request r) {
      requests.add(r);
      return handler(r);
    }

    final session = signedIn
        ? signedInSession(wrapped)
        : signedOutSession(wrapped);
    return RecurringTaskRemoteDataSourceImpl(session, RecordWatcher(fake));
  }

  setUp(() {
    handler = (_) async => pbJson(pbPage([]));
  });

  group('watchAll', () {
    test('sorts by title and keeps the server order', () async {
      handler = (_) async => pbJson(pbPage([_rec('b'), _rec('a')]));
      final list = await build().watchAll().first;
      expect(list.map((m) => m.id), ['b', 'a']);
      final r = requests.single;
      expect(r.method, 'GET');
      expect(r.url.path, _path);
      expect(r.url.queryParameters['sort'], 'title');
    });

    test('reloads on realtime event and cancel unsubscribes', () async {
      var call = 0;
      handler = (_) async {
        call++;
        return pbJson(pbPage([_rec('a'), if (call > 1) _rec('b')]));
      };
      final emitted = <List<RecurringTaskModel>>[];
      final sub = build().watchAll().listen(emitted.add);
      await pumpEventQueue();
      expect(emitted.single.length, 1);

      fake.emit('recurring_tasks/*');
      await Future<void>.delayed(
        RecordWatcher.burstWindow + const Duration(milliseconds: 50),
      );
      expect(emitted.last.length, 2);

      await sub.cancel();
      await pumpEventQueue();
      expect(fake.unsubscribeCount, greaterThan(0));
    });
  });

  group('getAll', () {
    test('sorts by title; no items → empty', () async {
      expect(await build().getAll(), isEmpty);
      expect(requests.single.url.path, _path);
      expect(requests.single.url.queryParameters['sort'], 'title');
    });
  });

  group('create', () {
    test('posts the keys plus user and returns the stored id', () async {
      handler = (_) async => pbJson(_rec('novo'));
      final created = await build().create(_model(''));
      final r = requests.single;
      expect(r.method, 'POST');
      expect(r.url.path, _path);
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), {..._modelKeys, 'user'});
      expect(body['user'], 'user-a');
      expect(created.id, 'novo');
    });
  });

  group('update', () {
    test('patches without last_generated_on and user', () async {
      handler = (_) async => pbJson(_rec('r1'));
      await build().update(_model('r1', title: 'Novo'));
      final r = requests.single;
      expect(r.method, 'PATCH');
      expect(r.url.path, '$_path/r1');
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), _modelKeys.difference({'last_generated_on'}));
      expect(body['title'], 'Novo');
    });

    test('404 → NotFoundException', () async {
      handler = (_) async => pbError(404);
      await expectLater(
        build().update(_model('r1')),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('204 passes, 404 is ignored, 403 → PermissionException', () async {
      handler = (_) async => http.Response('', 204);
      await build().delete('r1');
      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '$_path/r1');

      handler = (_) async => pbError(404);
      await build().delete('r1');

      handler = (_) async => pbError(403);
      await expectLater(
        build().delete('r1'),
        throwsA(isA<PermissionException>()),
      );
    });
  });

  group('restore', () {
    test('posts with the same id and user', () async {
      handler = (_) async => pbJson(_rec('r1'));
      await build().restore(
        _model('r1', lastGeneratedOn: DateTime(2026, 10, 12)),
      );
      final r = requests.single;
      expect(r.method, 'POST');
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body['id'], 'r1');
      expect(body['user'], 'user-a');
      expect(body['last_generated_on'], '2026-10-12 00:00:00.000Z');
    });

    test('repeated id → one PATCH with all keys and no user', () async {
      handler = (r) async =>
          r.method == 'POST' ? pbNotUnique('id') : pbJson(_rec('r1'));
      await build().restore(
        _model('r1', lastGeneratedOn: DateTime(2026, 10, 12)),
      );
      expect(requests.map((r) => r.method), ['POST', 'PATCH']);
      expect(requests.last.url.path, '$_path/r1');
      final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), _modelKeys);
    });

    test('PATCH 404 after conflict → NotFoundException', () async {
      handler = (r) async =>
          r.method == 'POST' ? pbNotUnique('id') : pbError(404);
      await expectLater(
        build().restore(_model('r1')),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('moveToList / deleteByList', () {
    test('moveToList: one batch with a PATCH per model', () async {
      handler = (r) async =>
          _isBatch(r) ? _batchOk(2) : pbJson(pbPage([_rec('a'), _rec('b')]));
      await build().moveToList('l1', 'l3');
      expect(requests.first.method, 'GET');
      expect(requests.first.url.queryParameters['filter'], 'list = "l1"');
      final reqs = batchRequests(requests.last);
      expect(reqs.map(_summary), ['PATCH $_path/a', 'PATCH $_path/b']);
      for (final r in reqs) {
        expect(r['body'], {'list': 'l3'});
      }
    });

    test('deleteByList: one batch with a DELETE per model', () async {
      handler = (r) async =>
          _isBatch(r) ? _batchOk(2) : pbJson(pbPage([_rec('a'), _rec('b')]));
      await build().deleteByList('l1');
      expect(requests.first.url.queryParameters['filter'], 'list = "l1"');
      expect(batchRequests(requests.last).map(_summary), [
        'DELETE $_path/a',
        'DELETE $_path/b',
      ]);
    });

    test('empty list sends no batch', () async {
      await build().moveToList('l1', 'l3');
      await build().deleteByList('l1');
      expect(requests.where(_isBatch), isEmpty);
    });
  });

  group('claimGeneration', () {
    final day = DateTime(2026, 10, 12, 8);
    bool notYet(RecurringTaskModel m) => !m.toEntity().wasGeneratedOn(day);

    test('first claim of the day writes the model and the marker', () async {
      handler = (r) async => _isBatch(r) ? _batchOk(2) : pbJson(_rec('r1'));
      final ok = await build().claimGeneration('r1', day, canClaim: notYet);
      expect(ok, isTrue);
      expect(requests.first.method, 'GET');
      expect(requests.first.url.path, '$_path/r1');
      final reqs = batchRequests(requests.last);
      expect(reqs.map(_summary), ['PATCH $_path/r1', 'POST $_claimsPath']);
      expect(reqs[0]['body'], {
        'last_generated_on': '2026-10-12 00:00:00.000Z',
      });
      expect(reqs[1]['body'], {
        'id': 'r1-2026-10-12',
        'recurring_task': 'r1',
        'user': 'user-a',
      });
    });

    test('same day → false and no batch; next day → true', () async {
      handler = (r) async => _isBatch(r)
          ? _batchOk(2)
          : pbJson(_rec('r1', lastGeneratedOn: '2026-10-12 00:00:00.000Z'));
      final same = await build().claimGeneration(
        'r1',
        DateTime(2026, 10, 12, 20),
        canClaim: notYet,
      );
      expect(same, isFalse);
      expect(requests.where(_isBatch), isEmpty);

      final next = DateTime(2026, 10, 13);
      final ok = await build().claimGeneration(
        'r1',
        next,
        canClaim: (m) => !m.toEntity().wasGeneratedOn(next),
      );
      expect(ok, isTrue);
      final reqs = batchRequests(requests.last);
      expect(reqs[0]['body'], {
        'last_generated_on': '2026-10-13 00:00:00.000Z',
      });
      expect((reqs[1]['body'] as Map)['id'], 'r1-2026-10-13');
    });

    test('repeated marker → false', () async {
      handler = (r) async =>
          _isBatch(r) ? _batchFail(1, pbNotUnique('id')) : pbJson(_rec('r1'));
      expect(
        await build().claimGeneration('r1', day, canClaim: notYet),
        isFalse,
      );
    });

    test('canClaim false → false and no batch', () async {
      handler = (_) async => pbJson(_rec('r1'));
      expect(
        await build().claimGeneration('r1', day, canClaim: (_) => false),
        isFalse,
      );
      expect(requests.where(_isBatch), isEmpty);
    });

    test('missing model → false, canClaim not called, no batch', () async {
      handler = (_) async => pbError(404);
      var called = false;
      final ok = await build().claimGeneration(
        'missing',
        day,
        canClaim: (_) => called = true,
      );
      expect(ok, isFalse);
      expect(called, isFalse);
      expect(requests.where(_isBatch), isEmpty);
    });

    test('model deleted after the read → false', () async {
      handler = (r) async =>
          _isBatch(r) ? _batchFail(0, pbError(404)) : pbJson(_rec('r1'));
      expect(
        await build().claimGeneration('r1', day, canClaim: notYet),
        isFalse,
      );
    });

    test('500 → ServerException; no network → NetworkException', () async {
      handler = (r) async => _isBatch(r) ? pbError(500) : pbJson(_rec('r1'));
      await expectLater(
        build().claimGeneration('r1', day, canClaim: notYet),
        throwsA(isA<ServerException>()),
      );
      handler = (_) async => throw const SocketException('down');
      await expectLater(
        build().claimGeneration('r1', day, canClaim: notYet),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  test('signed out: every method throws and sends nothing', () async {
    final ds = build(signedIn: false);
    final calls = <Future<Object?> Function()>[
      () async => ds.watchAll(),
      ds.getAll,
      () => ds.create(_model('x')),
      () => ds.update(_model('x')),
      () => ds.delete('x'),
      () => ds.restore(_model('x')),
      () => ds.moveToList('a', 'b'),
      () => ds.deleteByList('a'),
      () => ds.claimGeneration(
        'x',
        DateTime(2026, 10, 12),
        canClaim: (_) => true,
      ),
    ];
    for (final call in calls) {
      await expectLater(call(), throwsA(isA<UnauthenticatedException>()));
    }
    expect(requests, isEmpty);
  });
}
