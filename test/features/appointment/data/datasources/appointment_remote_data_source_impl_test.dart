import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meu_tempo/core/data/pocketbase/record_watcher.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/appointment/data/datasources/appointment_remote_data_source.dart';
import 'package:meu_tempo/features/appointment/data/models/appointment_model.dart';

import '../../../../helpers/pocketbase_test_support.dart';

const _path = '/api/collections/appointments/records';

const _model = AppointmentModel(
  id: '',
  title: 'T',
  listId: 'l',
  date: null,
  startMinute: 0,
  durationMinutes: 10,
);

Map<String, dynamic> _rec(String id) => {
  'id': id,
  'collectionName': 'appointments',
  'user': 'user-a',
  'title': 'Dentista',
  'list_id': 'pessoal',
  'date': '2026-10-24 00:00:00.000Z',
  'start_minute': 900,
  'duration_minutes': 60,
  'spent_minutes': 0,
  'is_done': false,
};

void main() {
  late List<http.Request> requests;
  late FakeRealtimeSubscriber fake;
  late Future<http.Response> Function(http.Request) handler;

  AppointmentRemoteDataSourceImpl build({bool signedIn = true}) {
    requests = [];
    fake = FakeRealtimeSubscriber();
    Future<http.Response> wrapped(http.Request r) {
      requests.add(r);
      return handler(r);
    }

    final session = signedIn
        ? signedInSession(wrapped)
        : signedOutSession(wrapped);
    return AppointmentRemoteDataSourceImpl(session, RecordWatcher(fake));
  }

  setUp(() {
    handler = (_) async => pbJson(pbPage([]));
  });

  group('watchForDay', () {
    test('filters by the day and sorts by date,start_minute', () async {
      handler = (_) async => pbJson(pbPage([_rec('b2'), _rec('a1')]));
      final list = await build().watchForDay(DateTime(2026, 10, 24)).first;
      expect(list.map((m) => m.id), ['b2', 'a1']);
      final r = requests.single;
      expect(r.method, 'GET');
      expect(r.url.path, _path);
      expect(
        r.url.queryParameters['filter'],
        contains('date = "2026-10-24 00:00:00.000Z"'),
      );
      expect(r.url.queryParameters['sort'], 'date,start_minute');
    });

    test('year-end days do not shift through UTC', () async {
      final ds = build();
      await ds.watchForDay(DateTime(2026, 12, 31)).first;
      await ds.watchForDay(DateTime(2027, 1, 1)).first;
      expect(
        requests[0].url.queryParameters['filter'],
        contains('2026-12-31 00:00:00.000Z'),
      );
      expect(
        requests[1].url.queryParameters['filter'],
        contains('2027-01-01 00:00:00.000Z'),
      );
    });

    test('no items → empty list', () async {
      expect(await build().watchForDay(DateTime(2026, 10, 24)).first, isEmpty);
    });
  });

  group('watchAll', () {
    test(
      'sorts by date, no filter, reloads on event, cancel unsubscribes',
      () async {
        var call = 0;
        handler = (_) async {
          call++;
          return pbJson(
            pbPage(call == 1 ? [_rec('a1')] : [_rec('a1'), _rec('b2')]),
          );
        };
        final ds = build();
        final emitted = <List<AppointmentModel>>[];
        final sub = ds.watchAll().listen(emitted.add);
        await pumpEventQueue();
        expect(emitted.single.length, 1);
        expect(requests.first.url.queryParameters['sort'], 'date');
        expect(
          requests.first.url.queryParameters.containsKey('filter'),
          isFalse,
        );

        fake.emit('appointments/*');
        await Future<void>.delayed(
          RecordWatcher.burstWindow + const Duration(milliseconds: 50),
        );
        expect(emitted.last.length, 2);

        await sub.cancel();
        await pumpEventQueue();
        expect(fake.unsubscribeCount, greaterThan(0));
      },
    );
  });

  test('create posts the body with user and returns the new id', () async {
    handler = (_) async => pbJson(_rec('new1'));
    final created = await build().create(
      AppointmentModel(
        id: '',
        title: 'Dentista',
        listId: 'pessoal',
        date: DateTime(2026, 10, 24),
        startMinute: 900,
        durationMinutes: 60,
      ),
    );
    expect(created.id, 'new1');
    expect(requests.single.method, 'POST');
    expect(jsonDecode(requests.single.body), {
      'title': 'Dentista',
      'list_id': 'pessoal',
      'date': '2026-10-24 00:00:00.000Z',
      'start_minute': 900,
      'duration_minutes': 60,
      'spent_minutes': 0,
      'is_done': false,
      'user': 'user-a',
    });
  });

  group('addSpentMinutes', () {
    test('sends the increment modifier, including negatives', () async {
      handler = (_) async => pbJson(_rec('a1'));
      final ds = build();
      await ds.addSpentMinutes('a1', 15);
      await ds.addSpentMinutes('a1', -5);
      expect(requests[0].method, 'PATCH');
      expect(requests[0].url.path, '$_path/a1');
      expect(jsonDecode(requests[0].body), {'spent_minutes+': 15});
      expect(jsonDecode(requests[1].body), {'spent_minutes+': -5});
    });

    test('404 → NotFoundException', () async {
      handler = (_) async => pbError(404);
      await expectLater(
        build().addSpentMinutes('a1', 1),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('setDone', () {
    test('patches only is_done', () async {
      handler = (_) async => pbJson(_rec('a1'));
      final ds = build();
      await ds.setDone('a1', true);
      await ds.setDone('a1', false);
      expect(requests[0].url.path, '$_path/a1');
      expect(jsonDecode(requests[0].body), {'is_done': true});
      expect(jsonDecode(requests[1].body), {'is_done': false});
    });

    test('404 → NotFoundException', () async {
      handler = (_) async => pbError(404);
      await expectLater(
        build().setDone('a1', true),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('204 passes', () async {
      handler = (_) async => http.Response('', 204);
      await build().delete('a1');
      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '$_path/a1');
    });

    test('404 is ignored', () async {
      handler = (_) async => pbError(404);
      await build().delete('a1');
    });

    test('403 → PermissionException', () async {
      handler = (_) async => pbError(403);
      await expectLater(
        build().delete('a1'),
        throwsA(isA<PermissionException>()),
      );
    });
  });

  group('errors', () {
    test('no network on create → NetworkException', () async {
      handler = (_) async => throw const SocketException('down');
      await expectLater(
        build().create(_model),
        throwsA(isA<NetworkException>()),
      );
    });

    test('500 on create → ServerException', () async {
      handler = (_) async => pbError(500);
      await expectLater(
        build().create(_model),
        throwsA(isA<ServerException>()),
      );
    });
  });

  test('signed out → UnauthenticatedException and no request', () async {
    final ds = build(signedIn: false);
    expect(
      () => ds.watchForDay(DateTime(2026, 10, 24)),
      throwsA(isA<UnauthenticatedException>()),
    );
    expect(ds.watchAll, throwsA(isA<UnauthenticatedException>()));
    for (final call in <Future<void> Function()>[
      () => ds.create(_model),
      () => ds.setDone('a1', true),
      () => ds.addSpentMinutes('a1', 1),
      () => ds.delete('a1'),
    ]) {
      await expectLater(call(), throwsA(isA<UnauthenticatedException>()));
    }
    expect(requests, isEmpty);
  });
}
