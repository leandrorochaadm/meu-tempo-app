import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_tempo/core/data/pocketbase/pocketbase_session.dart';
import 'package:meu_tempo/core/constants/pb_schema.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../helpers/pocketbase_test_support.dart';

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

  group('deleteCurrentUser', () {
    test('should delete own record and clear session', () async {
      final ds = build((_) async => http.Response('', 204));
      client.authStore.save(_jwt(_future), _record());

      await ds.deleteCurrentUser();

      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/api/collections/users/records/user-a');
      expect(client.authStore.isValid, isFalse);
    });

    test('should clear auth store when user is already deleted', () async {
      final ds = build((_) async => status(404));
      client.authStore.save(_jwt(_future), _record());

      await ds.deleteCurrentUser();

      expect(client.authStore.isValid, isFalse);
    });

    test('should keep session and throw when server fails', () async {
      final ds = build((_) async => status(500));
      client.authStore.save(_jwt(_future), _record());

      await expectLater(
        ds.deleteCurrentUser(),
        throwsA(isA<ServerException>()),
      );
      expect(client.authStore.isValid, isTrue);
    });

    test('should throw UnauthenticatedException without session', () async {
      final ds = build((_) async => http.Response('', 204));
      await expectLater(
        ds.deleteCurrentUser(),
        throwsA(isA<UnauthenticatedException>()),
      );
      expect(requests, isEmpty);
    });
  });

  group('signUp', () {
    http.Response created() => pbJson({
      'id': 'user-a',
      'collectionName': 'users',
      'email': 'ana@exemplo.com',
    });

    // REQ-001: successful sign-up makes 2 requests in order: create user, then sign in
    test('should create user then sign in', () async {
      final ds = build((request) async {
        if (request.url.path == '/api/collections/users/records') {
          return created();
        }
        return ok();
      });

      await ds.signUp(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      );

      expect(requests.length, 2);
      expect(requests[0].method, 'POST');
      expect(requests[0].url.path, '/api/collections/users/records');
      final body = jsonDecode(requests[0].body) as Map<String, Object?>;
      expect(body['email'], 'ana@exemplo.com');
      expect(body['password'], 'Abcd1234');
      expect(body['passwordConfirm'], 'Abcd1234');
      expect(body['name'], 'Ana');
      expect(requests[1].url.path, '/api/collections/users/auth-with-password');
      expect(client.authStore.isValid, isTrue);
    });

    // REQ-001: create fails offline: NetworkException and no sign-in request
    test(
      'should throw NetworkException and not sign in when create fails offline',
      () async {
        final ds = build((_) async => throw const SocketException('down'));

        await expectLater(
          ds.signUp(
            displayName: 'Ana',
            email: 'ana@exemplo.com',
            password: 'Abcd1234',
          ),
          throwsA(isA<NetworkException>()),
        );
        expect(requests.length, 1);
      },
    );

    // REQ-001: create fails with 500: ServerException and no sign-in request
    test('should throw ServerException when create fails on server', () async {
      final ds = build((_) async => pbError(500));

      await expectLater(
        ds.signUp(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
        throwsA(isA<ServerException>()),
      );
      expect(requests.length, 1);
    });

    // REQ-001: create fails with 400 validation_not_unique on email: ConflictException
    test('should throw ConflictException when email is taken', () async {
      final ds = build(
        (_) async => pbError(
          400,
          data: {
            'email': {
              'code': 'validation_not_unique',
              'message': 'The email is invalid or already in use.',
            },
          },
        ),
      );

      await expectLater(
        ds.signUp(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
        throwsA(isA<ConflictException>()),
      );
      expect(requests.length, 1);
    });

    // REQ-005: create answers pbNotUnique on email: EmailAlreadyInUseException, 1 request (no auth-with-password)
    test(
      'should throw EmailAlreadyInUseException when email is not unique',
      () async {
        final ds = build((_) async => pbNotUnique(PbFields.email));

        await expectLater(
          ds.signUp(
            displayName: 'Ana',
            email: 'ana@exemplo.com',
            password: 'Abcd1234',
          ),
          throwsA(isA<EmailAlreadyInUseException>()),
        );
        expect(requests.length, 1);
      },
    );

    // REQ-005: create answers not-unique on another field: ConflictException that is not EmailAlreadyInUseException
    test(
      'should keep ConflictException when another field is not unique',
      () async {
        final ds = build((_) async => pbNotUnique(PbFields.id));

        await expectLater(
          ds.signUp(
            displayName: 'Ana',
            email: 'ana@exemplo.com',
            password: 'Abcd1234',
          ),
          throwsA(
            isA<ConflictException>().having(
              (e) => e is EmailAlreadyInUseException,
              'is EmailAlreadyInUseException',
              isFalse,
            ),
          ),
        );
      },
    );

    // REQ-001: create succeeds but sign-in returns 400: mapped error (not AuthException), 2 requests, empty session
    test(
      'should map sign-in error after create through mapPocketBaseError',
      () async {
        final ds = build((request) async {
          if (request.url.path == '/api/collections/users/records') {
            return created();
          }
          return pbError(400);
        });

        await expectLater(
          ds.signUp(
            displayName: 'Ana',
            email: 'ana@exemplo.com',
            password: 'Abcd1234',
          ),
          throwsA(isNot(isA<AuthException>())),
        );
        expect(requests.length, 2);
        expect(client.authStore.isValid, isFalse);
      },
    );
  });

  group('updateDisplayName', () {
    http.Response updated() => pbJson({
      'id': 'user-a',
      'collectionName': 'users',
      'email': 'a@b.com',
      'name': 'Ana Lima',
    });

    // REQ-006: saves "Ana Lima": PATCH name on own record and auth store has the new name
    test('should update own name and refresh auth store record', () async {
      final ds = build((_) async => updated());
      client.authStore.save(_jwt(_future), _record());

      await ds.updateDisplayName('Ana Lima');

      expect(requests.single.method, 'PATCH');
      expect(requests.single.url.path, '/api/collections/users/records/user-a');
      final body = jsonDecode(requests.single.body) as Map<String, Object?>;
      expect(body[PbFields.name], 'Ana Lima');
      expect(ds.currentUser()?.displayName, 'Ana Lima');
    });

    // REQ-006: no session: UnauthenticatedException and no request
    test('should throw UnauthenticatedException without session', () async {
      final ds = build((_) async => updated());

      await expectLater(
        ds.updateDisplayName('Ana Lima'),
        throwsA(isA<UnauthenticatedException>()),
      );
      expect(requests, isEmpty);
    });

    // REQ-006: no connection: NetworkException
    test('should throw NetworkException when there is no connection', () async {
      final ds = build((_) async => throw const SocketException('down'));
      client.authStore.save(_jwt(_future), _record());

      await expectLater(
        ds.updateDisplayName('Ana Lima'),
        throwsA(isA<NetworkException>()),
      );
    });

    // REQ-006: server error 500: ServerException and the name stays
    test(
      'should throw ServerException and keep name when server fails',
      () async {
        final ds = build((_) async => status(500));
        client.authStore.save(_jwt(_future), _record());

        await expectLater(
          ds.updateDisplayName('Ana Lima'),
          throwsA(isA<ServerException>()),
        );
        expect(ds.currentUser()?.displayName, isNull);
      },
    );
  });

  group('changeEmail', () {
    http.Response changed() => pbJson({
      'token': _jwt(_future.add(const Duration(minutes: 5))),
      'record': {
        'id': 'user-a',
        'collectionName': 'users',
        'email': 'ana.lima@exemplo.com',
      },
    });

    Future<void> change(AuthRemoteDataSourceImpl ds) => ds.changeEmail(
      email: 'ana.lima@exemplo.com',
      currentPassword: 'abcd1234',
    );

    // REQ-007: change accepted: POST on the change-email route with email and oldPassword; auth store has the returned token and email
    test(
      'should post to the change-email route and save the returned session',
      () async {
        final ds = build((_) async => changed());
        client.authStore.save(_jwt(_future), _record());
        final oldToken = client.authStore.token;

        await change(ds);

        expect(requests.single.method, 'POST');
        expect(requests.single.url.path, PbRoutes.changeEmail);
        final body = jsonDecode(requests.single.body) as Map<String, Object?>;
        expect(body[PbFields.email], 'ana.lima@exemplo.com');
        expect(body[PbFields.oldPassword], 'abcd1234');
        expect(ds.currentUser()?.email, 'ana.lima@exemplo.com');
        expect(client.authStore.token, isNot(oldToken));
      },
    );

    // REQ-007: 400 oldPassword = validation_invalid_old_password: WrongCurrentPasswordException, auth store unchanged
    test(
      'should throw WrongCurrentPasswordException when the current password is wrong',
      () async {
        final ds = build(
          (_) async => pbError(
            400,
            data: {
              'oldPassword': {'code': 'validation_invalid_old_password'},
            },
          ),
        );
        client.authStore.save(_jwt(_future), _record());
        final oldToken = client.authStore.token;

        await expectLater(
          change(ds),
          throwsA(isA<WrongCurrentPasswordException>()),
        );
        expect(client.authStore.token, oldToken);
        expect(ds.currentUser()?.email, 'a@b.com');
      },
    );

    // REQ-007: 400 email = validation_not_unique: EmailAlreadyInUseException
    test(
      'should throw EmailAlreadyInUseException when the email is taken',
      () async {
        final ds = build((_) async => pbNotUnique('email'));
        client.authStore.save(_jwt(_future), _record());

        await expectLater(
          change(ds),
          throwsA(isA<EmailAlreadyInUseException>()),
        );
      },
    );

    // REQ-007: no connection (status 0) and 500: NetworkException and ServerException
    test('should map network and server errors', () async {
      final offline = build((_) async => throw const SocketException('down'));
      client.authStore.save(_jwt(_future), _record());
      await expectLater(change(offline), throwsA(isA<NetworkException>()));

      final broken = build((_) async => status(500));
      client.authStore.save(_jwt(_future), _record());
      await expectLater(change(broken), throwsA(isA<ServerException>()));
    });

    // REQ-007: no session: UnauthenticatedException and no request
    test(
      'should throw UnauthenticatedException without a request when signed out',
      () async {
        final ds = build((_) async => changed());

        await expectLater(change(ds), throwsA(isA<UnauthenticatedException>()));
        expect(requests, isEmpty);
      },
    );
  });

  group('changePassword', () {
    http.Response signedIn() => pbJson({
      'token': _jwt(_future.add(const Duration(minutes: 5))),
      'record': {'id': 'user-a', 'collectionName': 'users', 'email': 'a@b.com'},
    });

    bool isSignIn(http.Request r) => r.url.path.endsWith('auth-with-password');

    Future<void> change(AuthRemoteDataSourceImpl ds) =>
        ds.changePassword(currentPassword: 'abcd1234', newPassword: 'Wxyz5678');

    // REQ-008: change accepted: PATCH on the user record with password, passwordConfirm and oldPassword; then POST auth-with-password with the current e-mail and the new password; auth store has the new token
    test(
      'should update password then sign in again with the new password',
      () async {
        final newToken = _jwt(_future.add(const Duration(minutes: 5)));
        final ds = build(
          (request) async => isSignIn(request)
              ? pbJson({
                  'token': newToken,
                  'record': {
                    'id': 'user-a',
                    'collectionName': 'users',
                    'email': 'a@b.com',
                  },
                })
              : pbJson({
                  'id': 'user-a',
                  'collectionName': 'users',
                  'email': 'a@b.com',
                }),
        );
        client.authStore.save(_jwt(_future), _record());

        await change(ds);

        expect(requests, hasLength(2));
        expect(requests[0].method, 'PATCH');
        expect(
          requests[0].url.path,
          '/api/collections/${PbCollections.users}/records/user-a',
        );
        final update = jsonDecode(requests[0].body) as Map<String, Object?>;
        expect(update[PbFields.password], 'Wxyz5678');
        expect(update[PbFields.passwordConfirm], 'Wxyz5678');
        expect(update[PbFields.oldPassword], 'abcd1234');
        expect(requests[1].method, 'POST');
        expect(isSignIn(requests[1]), isTrue);
        final signIn = jsonDecode(requests[1].body) as Map<String, Object?>;
        expect(signIn['identity'], 'a@b.com');
        expect(signIn['password'], 'Wxyz5678');
        expect(client.authStore.token, newToken);
      },
    );

    // REQ-008: 400 oldPassword = validation_invalid_old_password: WrongCurrentPasswordException, 1 request only (no new sign in)
    test(
      'should throw WrongCurrentPasswordException when the current password is wrong',
      () async {
        final ds = build(
          (_) async => pbError(
            400,
            data: {
              'oldPassword': {'code': 'validation_invalid_old_password'},
            },
          ),
        );
        client.authStore.save(_jwt(_future), _record());

        await expectLater(
          change(ds),
          throwsA(isA<WrongCurrentPasswordException>()),
        );
        expect(requests, hasLength(1));
      },
    );

    // REQ-008: no session: UnauthenticatedException and no request
    test('should throw UnauthenticatedException without session', () async {
      final ds = build((_) async => signedIn());

      await expectLater(change(ds), throwsA(isA<UnauthenticatedException>()));
      expect(requests, isEmpty);
    });

    // REQ-008: no connection or 500 on the update: NetworkException and ServerException, no new sign in
    test('should map network and server errors', () async {
      final offline = build((_) async => throw const SocketException('down'));
      client.authStore.save(_jwt(_future), _record());
      await expectLater(change(offline), throwsA(isA<NetworkException>()));
      expect(requests.where(isSignIn), isEmpty);

      final broken = build((_) async => status(500));
      client.authStore.save(_jwt(_future), _record());
      await expectLater(change(broken), throwsA(isA<ServerException>()));
      expect(requests.where(isSignIn), isEmpty);
    });

    // REQ-008: update accepted but auth-with-password fails (500): ServerException
    test('should throw when signing in again fails after the change', () async {
      final ds = build(
        (request) async => isSignIn(request)
            ? status(500)
            : pbJson({
                'id': 'user-a',
                'collectionName': 'users',
                'email': 'a@b.com',
              }),
      );
      client.authStore.save(_jwt(_future), _record());

      await expectLater(change(ds), throwsA(isA<ServerException>()));
    });
  });

  group('signOutOtherDevices', () {
    // REQ-009: sign out other devices: POST on the route and the new token is saved
    test('should post to the route and save the new token', () async {
      final newToken = _jwt(_future.add(const Duration(minutes: 5)));
      final ds = build(
        (_) async => pbJson({
          'token': newToken,
          'record': {
            'id': 'user-a',
            'collectionName': 'users',
            'email': 'a@b.com',
          },
        }),
      );
      client.authStore.save(_jwt(_future), _record());

      await ds.signOutOtherDevices();

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, PbRoutes.signOutOtherDevices);
      expect(client.authStore.token, newToken);
    });

    // REQ-009: expired session (401): PermissionException
    test(
      'should throw PermissionException when the token is no longer valid',
      () async {
        final ds = build((_) async => status(401));
        client.authStore.save(_jwt(_future), _record());

        await expectLater(
          ds.signOutOtherDevices(),
          throwsA(isA<PermissionException>()),
        );
      },
    );

    // REQ-009: no session: UnauthenticatedException and no request
    test(
      'should throw UnauthenticatedException without a request when signed out',
      () async {
        final ds = build((_) async => status(401));

        await expectLater(
          ds.signOutOtherDevices(),
          throwsA(isA<UnauthenticatedException>()),
        );
        expect(requests, isEmpty);
      },
    );
  });
}
