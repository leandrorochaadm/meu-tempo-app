import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meu_tempo/core/data/pocketbase/record_watcher.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/task/data/datasources/task_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/task_model.dart';

import '../../../../helpers/pocketbase_test_support.dart';

const _path = '/api/collections/tasks/records';

const _modelKeys = {
  'title',
  'list',
  'parent',
  'created_at',
  'estimated_minutes',
  'due_date',
  'importance',
  'is_done',
  'has_children',
  'spent_minutes',
  'recurring_task_id',
};

TaskModel _model(String id, {String? parentId}) => TaskModel(
  id: id,
  title: 'Tarefa $id',
  listId: 'l1',
  createdAt: DateTime.utc(2026, 10, 15, 11),
  parentId: parentId,
);

Map<String, dynamic> _rec(String id, {String? parent}) => {
  'id': id,
  'collectionName': 'tasks',
  'user': 'user-a',
  'title': 'Tarefa $id',
  'list': 'l1',
  'parent': parent ?? '',
  'created_at': '2026-10-15 11:00:00.000Z',
  'is_done': false,
  'has_children': false,
  'spent_minutes': 0,
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

http.Response _batchFail(int index, http.Response inner) {
  final body = jsonDecode(inner.body);
  return pbError(
    400,
    data: {
      'requests': {
        '$index': {
          'code': 'batch_request_failed',
          'message': 'Batch request failed.',
          'response': body,
        },
      },
    },
  );
}

String _summary(Map<String, dynamic> r) => '${r['method']} ${r['url']}';

void main() {
  late List<http.Request> requests;
  late FakeRealtimeSubscriber fake;
  late Future<http.Response> Function(http.Request) handler;

  TaskRemoteDataSourceImpl build({bool signedIn = true}) {
    requests = [];
    fake = FakeRealtimeSubscriber();
    Future<http.Response> wrapped(http.Request r) {
      requests.add(r);
      return handler(r);
    }

    final session = signedIn
        ? signedInSession(wrapped)
        : signedOutSession(wrapped);
    return TaskRemoteDataSourceImpl(session, RecordWatcher(fake));
  }

  setUp(() {
    handler = (_) async => pbJson(pbPage([]));
  });

  group('watchTasks', () {
    test('pending only, newest first, keeps the server order', () async {
      handler = (_) async => pbJson(pbPage([_rec('b'), _rec('a')]));
      final list = await build().watchTasks(includeDone: false).first;
      expect(list.map((m) => m.id), ['b', 'a']);
      final r = requests.single;
      expect(r.method, 'GET');
      expect(r.url.path, _path);
      expect(r.url.queryParameters['filter'], 'is_done = false');
      expect(r.url.queryParameters['sort'], '-created_at');
    });

    test('includeDone has no filter; no items → empty', () async {
      final list = await build().watchTasks(includeDone: true).first;
      expect(list, isEmpty);
      expect(requests.single.url.queryParameters.containsKey('filter'), false);
      expect(requests.single.url.queryParameters['sort'], '-created_at');
    });

    test('reloads on realtime event and cancel unsubscribes', () async {
      var call = 0;
      handler = (_) async {
        call++;
        return pbJson(pbPage([_rec('a'), if (call > 1) _rec('b')]));
      };
      final emitted = <List<TaskModel>>[];
      final sub = build().watchTasks(includeDone: true).listen(emitted.add);
      await pumpEventQueue();
      expect(emitted.single.length, 1);

      fake.emit('tasks/*');
      await Future<void>.delayed(
        RecordWatcher.burstWindow + const Duration(milliseconds: 50),
      );
      expect(emitted.last.length, 2);

      await sub.cancel();
      await pumpEventQueue();
      expect(fake.unsubscribeCount, greaterThan(0));
    });
  });

  test('getTasks returns all without filter', () async {
    handler = (_) async => pbJson(pbPage([_rec('a'), _rec('b')]));
    final list = await build().getTasks();
    expect(list.map((m) => m.id), ['a', 'b']);
    expect(requests.single.url.queryParameters.containsKey('filter'), false);
  });

  test('create posts the 11 keys plus user, without id', () async {
    handler = (_) async => pbJson(_rec('new1'));
    final created = await build().create(_model('x'));
    final r = requests.single;
    expect(r.method, 'POST');
    expect(r.url.path, _path);
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    expect(body.keys.toSet(), {..._modelKeys, 'user'});
    expect(body['user'], 'user-a');
    expect(created.id, 'new1');
  });

  group('createChild', () {
    test('one batch: create child then mark parent, then getOne', () async {
      handler = (r) async {
        if (r.url.path == '/api/batch') return _batchOk(2);
        final id = r.url.pathSegments.last;
        return pbJson(_rec(id, parent: 'mae'));
      };
      final created = await build().createChild(
        _model('x', parentId: 'mae'),
        parentId: 'mae',
      );
      expect(requests, hasLength(2));
      final reqs = batchRequests(requests.first);
      expect(reqs, hasLength(2));
      expect(reqs[0]['method'], 'POST');
      expect(reqs[0]['url'], _path);
      final body = reqs[0]['body'] as Map<String, dynamic>;
      expect(body['id'], matches(RegExp(r'^[a-z0-9]{15}$')));
      expect(body['parent'], 'mae');
      expect(body['user'], 'user-a');
      expect(reqs[1]['method'], 'PATCH');
      expect(reqs[1]['url'], '$_path/mae');
      expect(reqs[1]['body'], {'has_children': true});
      expect(requests.last.method, 'GET');
      expect(requests.last.url.path, '$_path/${body['id']}');
      expect(created.id, body['id']);
      expect(created.parentId, 'mae');
    });

    test('deleted parent → NotFoundException and no GET', () async {
      handler = (_) async => _batchFail(1, pbError(404));
      await expectLater(
        build().createChild(_model('x'), parentId: 'mae'),
        throwsA(isA<NotFoundException>()),
      );
      expect(requests, hasLength(1));
    });

    test('no network → NetworkException; 500 → ServerException', () async {
      handler = (_) async => throw const SocketException('down');
      await expectLater(
        build().createChild(_model('x'), parentId: 'mae'),
        throwsA(isA<NetworkException>()),
      );
      handler = (_) async => pbError(500);
      await expectLater(
        build().createChild(_model('x'), parentId: 'mae'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('moveTask', () {
    test('child, new parent and emptied parent in order', () async {
      handler = (_) async => _batchOk(3);
      await build().moveTask(
        [_model('filha', parentId: 'maeNova')],
        newParentId: 'maeNova',
        emptiedParentId: 'maeAntiga',
      );
      final reqs = batchRequests(requests.single);
      expect(reqs.map(_summary), [
        'PATCH $_path/filha',
        'PATCH $_path/maeNova',
        'PATCH $_path/maeAntiga',
      ]);
      final body = reqs[0]['body'] as Map<String, dynamic>;
      expect(body.keys.toSet(), _modelKeys);
      expect(body['parent'], 'maeNova');
      expect(reqs[1]['body'], {'has_children': true});
      expect(reqs[2]['body'], {'has_children': false});
    });

    test('without emptied parent has no request for it', () async {
      handler = (_) async => _batchOk(2);
      await build().moveTask([_model('filha')], newParentId: 'maeNova');
      expect(batchRequests(requests.single), hasLength(2));
    });

    test('to the root sends parent null', () async {
      handler = (_) async => _batchOk(2);
      await build().moveTask([_model('filha')], emptiedParentId: 'mae');
      final reqs = batchRequests(requests.single);
      expect((reqs[0]['body'] as Map)['parent'], isNull);
      expect((reqs[0]['body'] as Map).containsKey('parent'), isTrue);
      expect(reqs[1]['body'], {'has_children': false});
    });

    test('nothing to write sends no request', () async {
      await build().moveTask([]);
      expect(requests, isEmpty);
    });
  });

  group('updateAll', () {
    test('one batch with a PATCH per task, without user', () async {
      handler = (_) async => _batchOk(2);
      await build().updateAll([_model('a'), _model('b')]);
      final reqs = batchRequests(requests.single);
      expect(reqs.map(_summary), ['PATCH $_path/a', 'PATCH $_path/b']);
      for (final r in reqs) {
        expect((r['body'] as Map).keys.toSet(), _modelKeys);
      }
    });

    test('empty list sends nothing', () async {
      await build().updateAll([]);
      expect(requests, isEmpty);
    });
  });

  group('deleteSubtree', () {
    test('deletes in reverse order then marks the parent', () async {
      handler = (_) async => _batchOk(3);
      await build().deleteSubtree(['filha', 'neta'], emptiedParentId: 'mae');
      final reqs = batchRequests(requests.single);
      expect(reqs.map(_summary), [
        'DELETE $_path/neta',
        'DELETE $_path/filha',
        'PATCH $_path/mae',
      ]);
      expect(reqs[2]['body'], {'has_children': false});
    });

    test('without emptied parent only deletes; empty sends nothing', () async {
      handler = (_) async => _batchOk(2);
      final ds = build();
      await ds.deleteSubtree(['filha', 'neta']);
      expect(batchRequests(requests.single), hasLength(2));
      requests.clear();
      await ds.deleteSubtree([]);
      expect(requests, isEmpty);
    });
  });

  group('restoreSubtree', () {
    final neta = _model('neta', parentId: 'filha');
    final filha = _model('filha', parentId: 'mae');

    test('creates parents first with original ids, then the parent', () async {
      handler = (_) async => _batchOk(3);
      await build().restoreSubtree([neta, filha], parentId: 'mae');
      final reqs = batchRequests(requests.single);
      expect(reqs.map(_summary), [
        'POST $_path',
        'POST $_path',
        'PATCH $_path/mae',
      ]);
      final first = reqs[0]['body'] as Map<String, dynamic>;
      final second = reqs[1]['body'] as Map<String, dynamic>;
      expect(first['id'], 'filha');
      expect(second['id'], 'neta');
      expect(first['user'], 'user-a');
      expect(second['user'], 'user-a');
      expect(reqs[2]['body'], {'has_children': true});
    });

    test('root restore has only the POSTs', () async {
      handler = (_) async => _batchOk(2);
      await build().restoreSubtree([neta, filha]);
      expect(batchRequests(requests.single), hasLength(2));
    });

    test('duplicate id → retries once as updates, without user', () async {
      var call = 0;
      handler = (_) async {
        call++;
        return call == 1 ? _batchFail(0, pbNotUnique('id')) : _batchOk(3);
      };
      await build().restoreSubtree([neta, filha], parentId: 'mae');
      expect(requests, hasLength(2));
      final reqs = batchRequests(requests.last);
      expect(reqs.map(_summary), [
        'PATCH $_path/filha',
        'PATCH $_path/neta',
        'PATCH $_path/mae',
      ]);
      expect((reqs[0]['body'] as Map).containsKey('user'), isFalse);
    });

    test('second batch with 404 → NotFoundException', () async {
      var call = 0;
      handler = (_) async {
        call++;
        return call == 1
            ? _batchFail(0, pbNotUnique('id'))
            : _batchFail(1, pbError(404));
      };
      await expectLater(
        build().restoreSubtree([neta, filha], parentId: 'mae'),
        throwsA(isA<NotFoundException>()),
      );
      expect(requests, hasLength(2));
    });
  });

  group('addSpentMinutes', () {
    test('patches with the increment modifier', () async {
      handler = (_) async => pbJson(_rec('t1'));
      final ds = build();
      await ds.addSpentMinutes('t1', 5);
      expect(requests.single.method, 'PATCH');
      expect(requests.single.url.path, '$_path/t1');
      expect(jsonDecode(requests.single.body), {'spent_minutes+': 5});
      await ds.addSpentMinutes('t1', -3);
      expect(jsonDecode(requests.last.body), {'spent_minutes+': -3});
    });

    test('404 → NotFoundException', () async {
      handler = (_) async => pbError(404);
      await expectLater(
        build().addSpentMinutes('t1', 5),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('setDone', () {
    test('patches only is_done', () async {
      handler = (_) async => pbJson(_rec('t1'));
      await build().setDone('t1', true);
      expect(requests.single.url.path, '$_path/t1');
      expect(jsonDecode(requests.single.body), {'is_done': true});
    });

    test('404 → NotFoundException', () async {
      handler = (_) async => pbError(404);
      await expectLater(
        build().setDone('t1', true),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('update', () {
    test('patches the 11 keys without user', () async {
      handler = (_) async => pbJson(_rec('t1'));
      await build().update(_model('t1'));
      expect(requests.single.method, 'PATCH');
      expect(requests.single.url.path, '$_path/t1');
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), _modelKeys);
    });

    test('404 → NotFoundException', () async {
      handler = (_) async => pbError(404);
      await expectLater(
        build().update(_model('t1')),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('204 passes, 404 is ignored, 403 → PermissionException', () async {
      handler = (_) async => http.Response('', 204);
      await build().delete('t1');
      expect(requests.single.method, 'DELETE');
      handler = (_) async => pbError(404);
      await build().delete('t1');
      handler = (_) async => pbError(403);
      await expectLater(
        build().delete('t1'),
        throwsA(isA<PermissionException>()),
      );
    });
  });

  test('signed out → UnauthenticatedException and no request', () async {
    final ds = build(signedIn: false);
    final calls = <String, dynamic Function()>{
      'watchTasks': () => ds.watchTasks(includeDone: true),
      'getTasks': ds.getTasks,
      'create': () => ds.create(_model('a')),
      'createChild': () => ds.createChild(_model('a'), parentId: 'm'),
      'moveTask': () => ds.moveTask([_model('a')]),
      'updateAll': () => ds.updateAll([_model('a')]),
      'deleteSubtree': () => ds.deleteSubtree(['a']),
      'restoreSubtree': () => ds.restoreSubtree([_model('a')]),
      'addSpentMinutes': () => ds.addSpentMinutes('a', 1),
      'setDone': () => ds.setDone('a', true),
      'update': () => ds.update(_model('a')),
      'delete': () => ds.delete('a'),
    };
    for (final entry in calls.entries) {
      await expectLater(
        () async => await entry.value(),
        throwsA(isA<UnauthenticatedException>()),
        reason: entry.key,
      );
    }
    expect(requests, isEmpty);
  });
}
