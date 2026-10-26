import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meu_tempo/core/data/pocketbase/record_watcher.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/list/data/datasources/task_list_remote_data_source.dart';
import 'package:meu_tempo/features/list/data/models/task_list_model.dart';

import '../../../../helpers/pocketbase_test_support.dart';

Map<String, dynamic> _rec(String id, String name, {bool isDefault = false}) => {
  'id': id,
  'collectionName': 'task_lists',
  'user': 'user-a',
  'name': name,
  'is_default': isDefault,
};

void main() {
  late List<http.Request> requests;
  late FakeRealtimeSubscriber fake;
  late Future<http.Response> Function(http.Request) handler;

  TaskListRemoteDataSourceImpl build({bool signedIn = true}) {
    requests = [];
    fake = FakeRealtimeSubscriber();
    Future<http.Response> wrapped(http.Request r) {
      requests.add(r);
      return handler(r);
    }

    final session = signedIn
        ? signedInSession(wrapped)
        : signedOutSession(wrapped);
    return TaskListRemoteDataSourceImpl(session, RecordWatcher(fake));
  }

  setUp(() {
    handler = (_) async => pbJson(pbPage([]));
  });

  group('getLists', () {
    test('requests sorted by name and keeps the response order', () async {
      handler = (_) async =>
          pbJson(pbPage([_rec('a1', 'Zeta'), _rec('b2', 'Alfa')]));
      final lists = await build().getLists();
      expect(lists.map((l) => l.name), ['Zeta', 'Alfa']);
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/api/collections/task_lists/records');
      expect(requests.single.url.queryParameters['sort'], 'name');
    });

    test('empty list', () async {
      expect(await build().getLists(), isEmpty);
    });

    test('no network → NetworkException', () async {
      handler = (_) async => throw const SocketException('down');
      await expectLater(build().getLists(), throwsA(isA<NetworkException>()));
    });

    test('500 → ServerException', () async {
      handler = (_) async => pbError(500);
      await expectLater(build().getLists(), throwsA(isA<ServerException>()));
    });
  });

  group('watchLists', () {
    test('emits initial and reloaded lists; cancel unsubscribes', () async {
      var call = 0;
      handler = (_) async {
        call++;
        return pbJson(
          pbPage(
            call == 1
                ? [_rec('a1', 'Um')]
                : [_rec('a1', 'Um'), _rec('b2', 'Dois')],
          ),
        );
      };
      final ds = build();
      final emitted = <List<TaskListModel>>[];
      final sub = ds.watchLists().listen(emitted.add);
      await pumpEventQueue();
      expect(emitted.single.length, 1);

      fake.emit('task_lists/*');
      await Future<void>.delayed(
        RecordWatcher.burstWindow + const Duration(milliseconds: 50),
      );
      expect(emitted.last.length, 2);

      await sub.cancel();
      await pumpEventQueue();
      expect(fake.unsubscribeCount, greaterThan(0));
    });
  });

  group('create', () {
    test('posts name, is_default and user', () async {
      handler = (_) async => pbJson(_rec('new1', 'Casa'));
      final created = await build().create(
        const TaskListModel(id: '', name: 'Casa'),
      );
      expect(created.id, 'new1');
      expect(requests.single.method, 'POST');
      expect(jsonDecode(requests.single.body), {
        'name': 'Casa',
        'is_default': false,
        'user': 'user-a',
      });
    });
  });

  group('rename', () {
    test('patches only the name', () async {
      handler = (_) async => pbJson(_rec('x1', 'Novo'));
      await build().rename('x1', 'Novo');
      expect(requests.single.method, 'PATCH');
      expect(
        requests.single.url.path,
        '/api/collections/task_lists/records/x1',
      );
      expect(jsonDecode(requests.single.body), {'name': 'Novo'});
    });

    test('404 → NotFoundException', () async {
      handler = (_) async => pbError(404);
      await expectLater(
        build().rename('x1', 'Novo'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('204 passes', () async {
      handler = (_) async => http.Response('', 204);
      await build().delete('x1');
      expect(requests.single.method, 'DELETE');
      expect(
        requests.single.url.path,
        '/api/collections/task_lists/records/x1',
      );
    });

    test('404 is ignored', () async {
      handler = (_) async => pbError(404);
      await build().delete('x1');
    });

    test('403 → PermissionException', () async {
      handler = (_) async => pbError(403);
      await expectLater(
        build().delete('x1'),
        throwsA(isA<PermissionException>()),
      );
    });
  });

  group('signed out', () {
    test('getLists, create and watchLists throw before any request', () async {
      final ds = build(signedIn: false);
      await expectLater(
        ds.getLists(),
        throwsA(isA<UnauthenticatedException>()),
      );
      await expectLater(
        ds.create(const TaskListModel(id: '', name: 'X')),
        throwsA(isA<UnauthenticatedException>()),
      );
      expect(ds.watchLists, throwsA(isA<UnauthenticatedException>()));
      expect(requests, isEmpty);
    });
  });
}
