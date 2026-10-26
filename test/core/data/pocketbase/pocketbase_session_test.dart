import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_tempo/core/data/pocketbase/pocketbase_session.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:pocketbase/pocketbase.dart';

String _jwt({required bool expired}) {
  final exp =
      DateTime.now()
          .add(Duration(hours: expired ? -1 : 1))
          .millisecondsSinceEpoch ~/
      1000;
  String enc(Map<String, Object?> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${enc({'alg': 'HS256'})}.${enc({'exp': exp})}.x';
}

RecordModel _record() =>
    RecordModel({'id': 'user-a', 'collectionName': 'users'});

void main() {
  late List<http.Request> requests;

  PocketBaseSession build(
    Future<http.Response> Function(http.Request) handler, {
    bool signedIn = true,
    bool expired = false,
    bool withRecord = true,
  }) {
    requests = [];
    final client = PocketBase(
      'http://pb.test',
      authStore: AuthStore(),
      httpClientFactory: () => MockClient((request) {
        requests.add(request);
        return handler(request);
      }),
    );
    if (signedIn) {
      client.authStore.save(
        _jwt(expired: expired),
        withRecord ? _record() : null,
      );
    }
    return PocketBaseSession(client);
  }

  Future<http.Response> Function(http.Request) respond(int code) =>
      (_) async => http.Response('{}', code);

  Future<http.Response> ok(http.Request _) async => http.Response(
    jsonEncode({
      'token': _jwt(expired: false),
      'record': {'id': 'user-a', 'collectionName': 'users'},
    }),
    200,
    headers: {'content-type': 'application/json'},
  );

  group('isSignedIn / userId', () {
    test('no session', () {
      final session = build(respond(200), signedIn: false);
      expect(session.isSignedIn, isFalse);
      expect(() => session.userId, throwsA(isA<UnauthenticatedException>()));
    });

    test('valid token and record', () {
      final session = build(respond(200));
      expect(session.isSignedIn, isTrue);
      expect(session.userId, 'user-a');
    });

    test('expired token', () {
      final session = build(respond(200), expired: true);
      expect(session.isSignedIn, isFalse);
      expect(() => session.userId, throwsA(isA<UnauthenticatedException>()));
    });

    test('valid token without record', () {
      final session = build(respond(200), withRecord: false);
      expect(session.isSignedIn, isFalse);
    });
  });

  group('refreshSession', () {
    test('without session makes no request', () async {
      final session = build(ok, signedIn: false);
      await session.refreshSession();
      expect(requests, isEmpty);
    });

    test('200 stores the new token', () async {
      final session = build(ok);
      final old = session.client.authStore.token;
      await Future<void>.delayed(const Duration(seconds: 1));
      await session.refreshSession();
      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/collections/users/auth-refresh');
      expect(session.client.authStore.token, isNotEmpty);
      expect(session.isSignedIn, isTrue);
      expect(old, isNotEmpty);
    });

    for (final code in [401, 403, 404]) {
      test('$code clears the session', () async {
        final session = build(respond(code));
        await session.refreshSession();
        expect(session.isSignedIn, isFalse);
      });
    }

    for (final code in [500, 429]) {
      test('$code keeps the session', () async {
        final session = build(respond(code));
        await session.refreshSession();
        expect(session.isSignedIn, isTrue);
      });
    }

    test('network failure keeps the session', () async {
      final session = build((_) async => throw const SocketException('down'));
      await session.refreshSession();
      expect(session.isSignedIn, isTrue);
    });

    test('timeout keeps the session and finishes', () async {
      final session = build((_) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return http.Response('{}', 200);
      });
      await session.refreshSession(timeout: const Duration(milliseconds: 50));
      expect(session.isSignedIn, isTrue);
    });
  });
}
