import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meu_tempo/core/data/pocketbase/record_watcher.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/config/data/datasources/config_remote_data_source.dart';
import 'package:meu_tempo/features/config/data/models/day_config_model.dart';

import '../../../../helpers/pocketbase_test_support.dart';

Map<String, dynamic> _cfg({int minutes = 300, bool onboarded = false}) => {
  'id': 'cfg1',
  'collectionName': 'day_configs',
  'user': 'user-a',
  'available_minutes_per_day': minutes,
  'onboarded': onboarded,
};

void main() {
  late List<http.Request> requests;
  late FakeRealtimeSubscriber fake;
  late Future<http.Response> Function(http.Request) handler;

  ConfigRemoteDataSourceImpl build({bool signedIn = true}) {
    requests = [];
    fake = FakeRealtimeSubscriber();
    Future<http.Response> wrapped(http.Request r) {
      requests.add(r);
      return handler(r);
    }

    final session = signedIn
        ? signedInSession(wrapped)
        : signedOutSession(wrapped);
    return ConfigRemoteDataSourceImpl(session, RecordWatcher(fake));
  }

  Iterable<http.Request> byMethod(String m) =>
      requests.where((r) => r.method == m);

  setUp(() {
    handler = (_) async => pbJson(pbPage([]));
  });

  group('getConfig', () {
    test('no record → defaults', () async {
      final config = await build().getConfig();
      expect(config.availableMinutesPerDay, 480);
      expect(config.onboarded, isFalse);
    });

    test(
      'with record → its values, requested with perPage=1 and skipTotal',
      () async {
        handler = (_) async => pbJson(pbPage([_cfg()], perPage: 1));
        final config = await build().getConfig();
        expect(config.availableMinutesPerDay, 300);
        final query = requests.single.url.queryParameters;
        expect(query['perPage'], '1');
        expect(query['skipTotal'], 'true');
      },
    );
  });

  test('watchConfig emits default, then the new record', () async {
    var hasRecord = false;
    handler = (_) async => pbJson(pbPage(hasRecord ? [_cfg()] : []));
    final ds = build();
    final emitted = <DayConfigModel>[];
    final sub = ds.watchConfig().listen(emitted.add);
    await pumpEventQueue();
    expect(emitted.single.availableMinutesPerDay, 480);

    hasRecord = true;
    fake.emit('day_configs/*');
    await Future<void>.delayed(
      RecordWatcher.burstWindow + const Duration(milliseconds: 50),
    );
    expect(emitted.last.availableMinutesPerDay, 300);
    await sub.cancel();
  });

  group('_upsert', () {
    test('setAvailableMinutes with record → one PATCH, no POST', () async {
      handler = (r) async => r.method == 'GET'
          ? pbJson(pbPage([_cfg()]))
          : pbJson(_cfg(minutes: 300));
      await build().setAvailableMinutes(300);
      expect(byMethod('POST'), isEmpty);
      final patch = byMethod('PATCH').single;
      expect(patch.url.path, '/api/collections/day_configs/records/cfg1');
      expect(jsonDecode(patch.body), {'available_minutes_per_day': 300});
    });

    test(
      'markOnboarded without record → one POST with the full record',
      () async {
        handler = (r) async => r.method == 'GET'
            ? pbJson(pbPage([]))
            : pbJson(_cfg(onboarded: true));
        await build().markOnboarded();
        expect(jsonDecode(byMethod('POST').single.body), {
          'available_minutes_per_day': 480,
          'onboarded': true,
          'user': 'user-a',
        });
      },
    );

    test('conflict → rereads once and patches', () async {
      var gets = 0;
      handler = (r) async {
        if (r.method == 'GET') {
          gets++;
          return pbJson(pbPage(gets == 1 ? [] : [_cfg()]));
        }
        if (r.method == 'POST') return pbNotUnique('user');
        return pbJson(_cfg(onboarded: true));
      };
      await build().markOnboarded();
      final patch = byMethod('PATCH').single;
      expect(patch.url.path, '/api/collections/day_configs/records/cfg1');
      expect(jsonDecode(patch.body), {'onboarded': true});
    });

    test('conflict and still empty → ConflictException', () async {
      handler = (r) async =>
          r.method == 'POST' ? pbNotUnique('user') : pbJson(pbPage([]));
      await expectLater(
        build().markOnboarded(),
        throwsA(isA<ConflictException>()),
      );
    });

    test('PATCH 404 → NotFoundException', () async {
      handler = (r) async =>
          r.method == 'GET' ? pbJson(pbPage([_cfg()])) : pbError(404);
      await expectLater(
        build().setAvailableMinutes(300),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('no network → NetworkException', () async {
      handler = (_) async => throw const SocketException('down');
      await expectLater(
        build().setAvailableMinutes(300),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  test('signed out throws before any request', () async {
    final ds = build(signedIn: false);
    await expectLater(ds.getConfig(), throwsA(isA<UnauthenticatedException>()));
    await expectLater(
      ds.markOnboarded(),
      throwsA(isA<UnauthenticatedException>()),
    );
    expect(ds.watchConfig, throwsA(isA<UnauthenticatedException>()));
    expect(requests, isEmpty);
  });
}
