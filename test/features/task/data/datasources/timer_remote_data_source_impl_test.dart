import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meu_tempo/core/data/pocketbase/record_watcher.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/task/data/datasources/timer_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/active_timer_model.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

import '../../../../helpers/pocketbase_test_support.dart';

const _path = '/api/collections/active_timers/records';

const _modelKeys = {
  'target_id',
  'target_type',
  'list_id',
  'started_at',
  'status',
};

ActiveTimerModel _model({TimerStatusEnum status = TimerStatusEnum.paused}) =>
    ActiveTimerModel.fromEntity(
      ActiveTimerEntity(
        targetId: 't9',
        targetType: TimerTargetTypeEnum.task,
        listId: 'l1',
        startedAt: DateTime.utc(2026, 7, 20, 13, 30),
        status: status,
      ),
    );

Map<String, dynamic> _rec({
  String status = 'running',
  bool withStatus = true,
}) => {
  'id': 'tmr1',
  'collectionName': 'active_timers',
  'user': 'user-a',
  'target_id': 't1',
  'target_type': 'task',
  'list_id': 'l1',
  if (withStatus) 'status': status,
  'started_at': '2026-07-20 13:30:00.000Z',
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

bool _isBatch(http.Request r) => r.url.path == '/api/batch';
bool _isGet(http.Request r) => r.method == 'GET';

void main() {
  late List<http.Request> requests;
  late FakeRealtimeSubscriber fake;
  late Future<http.Response> Function(http.Request) handler;

  TimerRemoteDataSourceImpl build({bool signedIn = true}) {
    requests = [];
    fake = FakeRealtimeSubscriber();
    Future<http.Response> wrapped(http.Request r) {
      requests.add(r);
      return handler(r);
    }

    final session = signedIn
        ? signedInSession(wrapped)
        : signedOutSession(wrapped);
    return TimerRemoteDataSourceImpl(session, RecordWatcher(fake));
  }

  /// GET returns [items]; other methods return [write].
  void respond(
    List<Map<String, dynamic>> items, {
    http.Response Function(http.Request)? write,
  }) {
    handler = (r) async {
      if (_isGet(r)) return pbJson(pbPage(items, perPage: 1));
      return write?.call(r) ?? pbJson(<String, dynamic>{}, status: 200);
    };
  }

  setUp(() {
    respond([]);
  });

  group('getActive', () {
    test('asks for one record without the total', () async {
      await build().getActive();
      final r = requests.single;
      expect(r.method, 'GET');
      expect(r.url.path, _path);
      expect(r.url.queryParameters['page'], '1');
      expect(r.url.queryParameters['perPage'], '1');
      expect(r.url.queryParameters['skipTotal'], 'true');
    });

    test('returns null without record and the model with one', () async {
      expect(await build().getActive(), isNull);
      respond([_rec()]);
      expect((await build().getActive())!.targetId, 't1');
    });

    test('record without status is read as running', () async {
      respond([_rec(withStatus: false)]);
      final model = await build().getActive();
      expect(model!.toEntity().status, TimerStatusEnum.running);
    });

    test('maps no network to NetworkException', () async {
      handler = (_) async => throw const SocketException('down');
      await expectLater(build().getActive(), throwsA(isA<NetworkException>()));
    });
  });

  group('watchActive', () {
    test('emits null, reloads on event and cancel unsubscribes', () async {
      var call = 0;
      handler = (_) async {
        call++;
        return pbJson(pbPage([if (call > 1) _rec()], perPage: 1));
      };
      final emitted = <ActiveTimerModel?>[];
      final sub = build().watchActive().listen(emitted.add);
      await pumpEventQueue();
      expect(emitted.single, isNull);

      fake.emit('active_timers/*');
      await Future<void>.delayed(
        RecordWatcher.burstWindow + const Duration(milliseconds: 50),
      );
      expect(emitted.last!.targetId, 't1');

      await sub.cancel();
      await pumpEventQueue();
      expect(fake.unsubscribeCount, greaterThan(0));
    });
  });

  group('setActive', () {
    test('creates with the five keys and the user when none exists', () async {
      await build().setActive(_model());
      final post = requests.singleWhere((r) => r.method == 'POST');
      expect(post.url.path, _path);
      final body = jsonDecode(post.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), {..._modelKeys, 'user'});
      expect(body['status'], 'paused');
      expect(body['user'], 'user-a');
      expect(body.containsKey('id'), isFalse);
    });

    test('updates the existing record without user', () async {
      respond([_rec()]);
      await build().setActive(_model());
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
      final patch = requests.singleWhere((r) => r.method == 'PATCH');
      expect(patch.url.path, '$_path/tmr1');
      final body = jsonDecode(patch.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), _modelKeys);
    });

    test('on conflict reads again and updates', () async {
      var gets = 0;
      handler = (r) async {
        if (_isGet(r)) {
          gets++;
          return pbJson(pbPage([if (gets > 1) _rec()], perPage: 1));
        }
        if (r.method == 'POST') return pbNotUnique('user');
        return pbJson(<String, dynamic>{});
      };
      await build().setActive(_model());
      final patch = requests.singleWhere((r) => r.method == 'PATCH');
      expect(patch.url.path, '$_path/tmr1');
      expect(
        (jsonDecode(patch.body) as Map<String, dynamic>).keys.toSet(),
        _modelKeys,
      );
    });

    test(
      'on conflict with an empty second read throws ConflictException',
      () async {
        respond([], write: (_) => pbNotUnique('user'));
        await expectLater(
          build().setActive(_model()),
          throwsA(isA<ConflictException>()),
        );
      },
    );

    test('update answering 404 throws NotFoundException', () async {
      respond([_rec()], write: (_) => pbError(404));
      await expectLater(
        build().setActive(_model()),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('claimActive', () {
    test('returns the paused timer and deletes the record', () async {
      respond([_rec(status: 'paused')]);
      final model = await build().claimActive();
      expect(model!.toEntity().status, TimerStatusEnum.paused);
      final delete = requests.singleWhere((r) => r.method == 'DELETE');
      expect(delete.url.path, '$_path/tmr1');
    });

    test('returns null and deletes nothing without record', () async {
      expect(await build().claimActive(), isNull);
      expect(requests.where((r) => r.method == 'DELETE'), isEmpty);
    });

    test('returns null when the delete answers 404', () async {
      respond([_rec()], write: (_) => pbError(404));
      expect(await build().claimActive(), isNull);
    });

    test('maps 500 to ServerException', () async {
      respond([_rec()], write: (_) => pbError(500));
      await expectLater(build().claimActive(), throwsA(isA<ServerException>()));
    });
  });

  group('replaceActiveIf', () {
    test('batches delete then create and returns true', () async {
      handler = (r) async =>
          _isBatch(r) ? _batchOk(2) : pbJson(pbPage([_rec()], perPage: 1));
      final ok = await build().replaceActiveIf(
        matches: (_) => true,
        replacement: _model(),
      );
      expect(ok, isTrue);
      final reqs = batchRequests(requests.singleWhere(_isBatch));
      expect(reqs.length, 2);
      expect(reqs[0]['method'], 'DELETE');
      expect(reqs[0]['url'], '$_path/tmr1');
      expect(reqs[1]['method'], 'POST');
      expect(reqs[1]['url'], _path);
      final body = reqs[1]['body'] as Map<String, dynamic>;
      expect(body.keys.toSet(), {..._modelKeys, 'user'});
      expect(body['status'], 'paused');
      expect(body['user'], 'user-a');
    });

    test('does not write when the predicate refuses', () async {
      respond([_rec()]);
      final ok = await build().replaceActiveIf(
        matches: (_) => false,
        replacement: _model(),
      );
      expect(ok, isFalse);
      expect(requests.where(_isBatch), isEmpty);
    });

    test('without record passes null and batches only the create', () async {
      handler = (r) async =>
          _isBatch(r) ? _batchOk(1) : pbJson(pbPage([], perPage: 1));
      ActiveTimerModel? seen = _model();
      final ok = await build().replaceActiveIf(
        matches: (current) {
          seen = current;
          return true;
        },
        replacement: _model(),
      );
      expect(seen, isNull);
      expect(ok, isTrue);
      final reqs = batchRequests(requests.singleWhere(_isBatch));
      expect(reqs.map((r) => r['method']), ['POST']);
    });

    test('without record and a refusing predicate writes nothing', () async {
      final ok = await build().replaceActiveIf(
        matches: (_) => false,
        replacement: _model(),
      );
      expect(ok, isFalse);
      expect(requests.where(_isBatch), isEmpty);
    });

    test('nested 404 on the delete returns false', () async {
      handler = (r) async => _isBatch(r)
          ? _batchFail(0, pbError(404))
          : pbJson(pbPage([_rec()], perPage: 1));
      final ok = await build().replaceActiveIf(
        matches: (_) => true,
        replacement: _model(),
      );
      expect(ok, isFalse);
    });

    test('nested not-unique on the create returns false', () async {
      handler = (r) async => _isBatch(r)
          ? _batchFail(1, pbNotUnique('user'))
          : pbJson(pbPage([_rec()], perPage: 1));
      final ok = await build().replaceActiveIf(
        matches: (_) => true,
        replacement: _model(),
      );
      expect(ok, isFalse);
    });

    test('maps 500 to ServerException', () async {
      handler = (r) async =>
          _isBatch(r) ? pbError(500) : pbJson(pbPage([_rec()], perPage: 1));
      await expectLater(
        build().replaceActiveIf(matches: (_) => true, replacement: _model()),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('clearActiveIf', () {
    test('deletes when the predicate accepts', () async {
      respond([_rec()]);
      final ok = await build().clearActiveIf(matches: (_) => true);
      expect(ok, isTrue);
      final delete = requests.singleWhere((r) => r.method == 'DELETE');
      expect(delete.url.path, '$_path/tmr1');
    });

    test('does not delete when the predicate refuses', () async {
      respond([_rec()]);
      final ok = await build().clearActiveIf(matches: (_) => false);
      expect(ok, isFalse);
      expect(requests.where((r) => r.method == 'DELETE'), isEmpty);
    });

    test('without record passes null and sends no delete', () async {
      ActiveTimerModel? seen = _model();
      final ok = await build().clearActiveIf(
        matches: (current) {
          seen = current;
          return true;
        },
      );
      expect(seen, isNull);
      expect(ok, isTrue);
      expect(requests.where((r) => r.method == 'DELETE'), isEmpty);
    });

    test('without record and a refusing predicate returns false', () async {
      expect(await build().clearActiveIf(matches: (_) => false), isFalse);
    });

    test('returns false when the delete answers 404', () async {
      respond([_rec()], write: (_) => pbError(404));
      expect(await build().clearActiveIf(matches: (_) => true), isFalse);
    });
  });

  group('clear', () {
    test('deletes the record', () async {
      respond([_rec()]);
      await build().clear();
      expect(
        requests.singleWhere((r) => r.method == 'DELETE').url.path,
        '$_path/tmr1',
      );
    });

    test('sends no delete without record', () async {
      await build().clear();
      expect(requests.where((r) => r.method == 'DELETE'), isEmpty);
    });

    test('ignores 404', () async {
      respond([_rec()], write: (_) => pbError(404));
      await build().clear();
    });

    test('maps 403 to PermissionException', () async {
      respond([_rec()], write: (_) => pbError(403));
      await expectLater(build().clear(), throwsA(isA<PermissionException>()));
    });
  });

  group('signed out', () {
    final calls = <String, Future<Object?> Function(TimerRemoteDataSourceImpl)>{
      'watchActive': (ds) async => ds.watchActive(),
      'getActive': (ds) => ds.getActive(),
      'setActive': (ds) => ds.setActive(_model()),
      'claimActive': (ds) => ds.claimActive(),
      'replaceActiveIf': (ds) =>
          ds.replaceActiveIf(matches: (_) => true, replacement: _model()),
      'clearActiveIf': (ds) => ds.clearActiveIf(matches: (_) => true),
      'clear': (ds) => ds.clear(),
    };

    for (final entry in calls.entries) {
      test('${entry.key} throws UnauthenticatedException', () async {
        final ds = build(signedIn: false);
        await expectLater(
          entry.value(ds),
          throwsA(isA<UnauthenticatedException>()),
        );
        expect(requests, isEmpty);
      });
    }
  });
}
