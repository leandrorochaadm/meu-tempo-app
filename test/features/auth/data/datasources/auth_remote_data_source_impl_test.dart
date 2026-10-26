import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_tempo/core/data/pocketbase/pocketbase_session.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pocketbase/pocketbase.dart';

String _jwt(DateTime exp) {
  String enc(Map<String, Object?> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${enc({'alg': 'HS256'})}.'
      '${enc({'exp': exp.millisecondsSinceEpoch ~/ 1000})}.x';
}

DateTime get _future => DateTime.now().add(const Duration(hours: 1));
DateTime get _past => DateTime.now().subtract(const Duration(hours: 1));

RecordModel _record() => RecordModel({
  'id': 'user-a',
  'collectionName': 'users',
  'email': 'a@b.com',
});

void main() {
  late List<http.Request> requests;
  late PocketBase client;

  AuthRemoteDataSourceImpl build(
    Future<http.Response> Function(http.Request) handler,
  ) {
    requests = [];
    client = PocketBase(
      'http://pb.test',
      authStore: AuthStore(),
      httpClientFactory: () => MockClient((request) {
        requests.add(request);
        return handler(request);
      }),
    );
    return AuthRemoteDataSourceImpl(PocketBaseSession(client));
  }

  http.Response ok() => http.Response(
    jsonEncode({
      'token': _jwt(_future),
      'record': {'id': 'user-a', 'collectionName': 'users', 'email': 'a@b.com'},
    }),
    200,
    headers: {'content-type': 'application/json'},
  );

  http.Response status(int code) => http.Response(
    jsonEncode({'status': code, 'message': 'x', 'data': {}}),
    code,
    headers: {'content-type': 'application/json'},
  );

  group('signInWithEmail', () {
    test(
      'should save session and emit user when credentials are valid',
      () async {
        final ds = build((_) async => ok());
        await ds.signInWithEmail('a@b.com', 'secret');

        expect(
          requests.single.url.path,
          '/api/collections/users/auth-with-password',
        );
        final body = jsonDecode(requests.single.body) as Map<String, Object?>;
        expect(body['identity'], 'a@b.com');
        expect(body['password'], 'secret');
        expect(ds.currentUser()?.uid, 'user-a');
        expect(ds.currentUser()?.email, 'a@b.com');
      },
    );

    test('should throw AuthException when server returns 400', () async {
      final ds = build((_) async => status(400));
      await expectLater(
        ds.signInWithEmail('a@b.com', 'bad'),
        throwsA(isA<AuthException>()),
      );
      expect(ds.currentUser(), isNull);
    });

    test('should throw NetworkException when there is no connection', () async {
      final ds = build((_) async => throw const SocketException('down'));
      await expectLater(
        ds.signInWithEmail('a@b.com', 'x'),
        throwsA(isA<NetworkException>()),
      );
    });

    for (final code in [429, 500]) {
      test('should throw ServerException when server returns $code', () async {
        final ds = build((_) async => status(code));
        await expectLater(
          ds.signInWithEmail('a@b.com', 'x'),
          throwsA(isA<ServerException>()),
        );
      });
    }

    test('should throw PermissionException when server returns 403', () async {
      final ds = build((_) async => status(403));
      await expectLater(
        ds.signInWithEmail('a@b.com', 'x'),
        throwsA(isA<PermissionException>()),
      );
    });
  });

  group('session', () {
    test(
      'should emit current user on subscribe when session is valid',
      () async {
        final ds = build((_) async => ok());
        client.authStore.save(_jwt(_future), _record());
        expect((await ds.authState().first)?.uid, 'user-a');
        expect(ds.currentUser()?.uid, 'user-a');
      },
    );

    test('should emit null on subscribe when token is expired', () async {
      final ds = build((_) async => ok());
      client.authStore.save(_jwt(_past), _record());
      expect(await ds.authState().first, isNull);
    });

    test(
      'should emit null and return null current user when signed out',
      () async {
        final ds = build((_) async => ok());
        expect(await ds.authState().first, isNull);
        expect(ds.currentUser(), isNull);
      },
    );

    test('should clear session and emit null on sign out', () async {
      final ds = build((_) async => ok());
      client.authStore.save(_jwt(_future), _record());
      final values = <Object?>[];
      final sub = ds.authState().listen(values.add);
      await Future<void>.delayed(Duration.zero);

      await ds.signOut();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(requests, isEmpty);
      expect(client.authStore.isValid, isFalse);
      expect(values.length, 2);
      expect(values.last, isNull);
    });
  });
}
