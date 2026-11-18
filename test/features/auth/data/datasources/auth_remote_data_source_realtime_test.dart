import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meu_tempo/core/constants/pb_schema.dart';
import 'package:meu_tempo/core/data/pocketbase/pocketbase_session.dart';
import 'package:meu_tempo/core/data/pocketbase/realtime_subscriber.dart';
import 'package:meu_tempo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:meu_tempo/features/auth/data/models/user_model.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../helpers/pocketbase_test_support.dart';

const _refreshPath = '/api/collections/users/auth-refresh';
const _authPath = '/api/collections/users/auth-with-password';
const _userTopic = 'users/user-a';

class _ThrowingRealtimeSubscriber implements RealtimeSubscriber {
  int attempts = 0;

  @override
  Future<RealtimeUnsubscribe> subscribe(
    String topic,
    void Function() onEvent,
  ) async {
    attempts++;
    throw const SocketException('down');
  }
}

DateTime get _oldExpiry => DateTime.now().add(const Duration(days: 1));
DateTime get _newExpiry => DateTime.now().add(const Duration(days: 2));

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

http.Response _authBody(String token) => pbJson({
  'token': token,
  'record': {'id': 'user-a', 'collectionName': 'users', 'email': 'a@b.com'},
});

void main() {
  late List<http.Request> requests;
  late FakeRealtimeSubscriber realtime;
  late String oldToken;
  late String newToken;
  late PocketBaseSession session;

  int count(String path) => requests.where((r) => r.url.path == path).length;

  PocketBaseSession buildSession(
    Future<http.Response> Function(http.Request) handler, {
    bool signedIn = true,
  }) {
    requests = [];
    final session = signedOutSession((request) {
      requests.add(request);
      return handler(request);
    });
    if (signedIn) {
      session.client.authStore.save(
        oldToken,
        RecordModel.fromJson({
          'id': 'user-a',
          'collectionName': 'users',
          'email': 'a@b.com',
        }),
      );
    }
    return session;
  }

  AuthRemoteDataSourceImpl build(
    Future<http.Response> Function(http.Request) handler, {
    bool signedIn = true,
  }) {
    realtime = FakeRealtimeSubscriber();
    session = buildSession(handler, signedIn: signedIn);
    return AuthRemoteDataSourceImpl(session, realtime);
  }

  Future<http.Response> Function(http.Request) refreshes(int status) =>
      (request) async => status == 200 ? _authBody(newToken) : pbError(status);

  /// Collects what [AuthRemoteDataSourceImpl.authState] emits.
  StreamSubscription<UserModel?> collect(
    AuthRemoteDataSourceImpl ds,
    List<UserModel?> out, {
    List<Object>? errors,
  }) => ds.authState().listen(out.add, onError: errors?.add);

  setUp(() {
    oldToken = fakeJwt(expiresAt: _oldExpiry);
    newToken = fakeJwt(expiresAt: _newExpiry);
  });

  // REQ-009: another open device receives the users/<id> event and the server refuses the token (401): session cleared, authState emits null
  test('should emit null when server refuses token after user event', () async {
    final ds = build(refreshes(401));
    final emitted = <UserModel?>[];
    final sub = collect(ds, emitted);
    await _settle();

    realtime.emit(_userTopic);
    await _settle();

    expect(count(_refreshPath), 1);
    expect(emitted.first?.uid, 'user-a');
    expect(emitted.last, isNull);
    expect(ds.currentUser(), isNull);
    await sub.cancel();
  });

  // Event with a still valid token (e.g. name change): 1 refresh with 200, session kept
  test('should keep session when refresh succeeds after user event', () async {
    final ds = build(refreshes(200));
    final emitted = <UserModel?>[];
    final sub = collect(ds, emitted);
    await _settle();

    realtime.emit(_userTopic);
    await _settle();

    expect(count(_refreshPath), 1);
    expect(ds.currentUser()?.uid, 'user-a');
    expect(emitted.where((u) => u == null), isEmpty);
    await sub.cancel();
  });

  // Event arrives with no internet or a 5xx: session kept
  test(
    'should keep session when refresh fails by network after user event',
    () async {
      final ds = build((_) async => throw const SocketException('down'));
      final emitted = <UserModel?>[];
      final sub = collect(ds, emitted);
      await _settle();
      realtime.emit(_userTopic);
      await _settle();
      expect(ds.currentUser()?.uid, 'user-a');

      final ds5xx = build(refreshes(500));
      final emitted5xx = <UserModel?>[];
      final sub5xx = collect(ds5xx, emitted5xx);
      await _settle();
      realtime.emit(_userTopic);
      await _settle();

      expect(count(_refreshPath), 1);
      expect(ds5xx.currentUser()?.uid, 'user-a');
      expect(emitted5xx.where((u) => u == null), isEmpty);
      await sub.cancel();
      await sub5xx.cancel();
    },
  );

  // Channel reconnection (PB_CONNECT) after coming back from background: 1 refresh; 401 sends the device out
  test('should refresh session on realtime reconnect', () async {
    final ds = build(refreshes(401));
    final emitted = <UserModel?>[];
    final sub = collect(ds, emitted);
    await _settle();

    realtime.emit(RealtimeTopics.connect);
    await _settle();

    expect(count(_refreshPath), 1);
    expect(emitted.last, isNull);
    await sub.cancel();
  });

  // Burst of events: only 1 refresh while one is running
  test('should send one refresh for a burst of events', () async {
    final gate = Completer<http.Response>();
    final ds = build((_) => gate.future);
    final sub = collect(ds, []);
    await _settle();

    for (var i = 0; i < 5; i++) {
      realtime.emit(_userTopic);
    }
    realtime.emit(RealtimeTopics.connect);
    await _settle();

    expect(count(_refreshPath), 1);
    gate.complete(_authBody(newToken));
    await _settle();
    expect(count(_refreshPath), 1);
    await sub.cancel();
  });

  // No session when subscribing; after sign in the user topic is subscribed
  test('should subscribe only after sign in', () async {
    final ds = build(refreshes(200), signedIn: false);
    final sub = collect(ds, []);
    await _settle();

    realtime.emit(_userTopic);
    realtime.emit(RealtimeTopics.connect);
    await _settle();
    expect(requests, isEmpty);

    session.client.authStore.save(
      oldToken,
      RecordModel.fromJson({'id': 'user-a', 'collectionName': 'users'}),
    );
    await _settle();
    realtime.emit(_userTopic);
    await _settle();

    expect(count(_refreshPath), 1);
    await sub.cancel();
  });

  // REQ-009: password change on this device: event arrives while the update is running (old token already invalid): deferred, 1 refresh with the new token, session kept
  test(
    'should not drop this device when user event arrives during own password change',
    () async {
      final gate = Completer<http.Response>();
      final ds = build((request) async {
        if (request.method == 'PATCH') return gate.future;
        if (request.url.path == _authPath) return _authBody(newToken);
        if (request.url.path == _refreshPath) {
          return request.headers['Authorization'] == newToken
              ? _authBody(newToken)
              : pbError(401);
        }
        return pbError(404);
      });
      final emitted = <UserModel?>[];
      final sub = collect(ds, emitted);
      await _settle();

      final change = ds.changePassword(
        currentPassword: 'abcd1234',
        newPassword: 'Wxyz5678',
      );
      await _settle();
      realtime.emit(_userTopic);
      await _settle();
      expect(count(_refreshPath), 0);

      gate.complete(pbJson({'id': 'user-a'}));
      await change;
      await _settle();

      final paths = requests.map((r) => r.url.path).toList();
      expect(count(_refreshPath), 1);
      expect(
        paths.indexOf(_refreshPath),
        greaterThan(paths.indexOf(_authPath)),
      );
      expect(requests.last.headers['Authorization'], newToken);
      expect(ds.currentUser()?.uid, 'user-a');
      expect(emitted.where((u) => u == null), isEmpty);
      await sub.cancel();
    },
  );

  // REQ-009: event arrives while this device signs out the others: deferred, refresh with the token returned by the route, session kept
  test(
    'should not drop this device when user event arrives during own sign out of other devices',
    () async {
      final gate = Completer<http.Response>();
      final ds = build((request) async {
        if (request.url.path == PbRoutes.signOutOtherDevices) {
          return gate.future;
        }
        if (request.url.path == _refreshPath) {
          return request.headers['Authorization'] == newToken
              ? _authBody(newToken)
              : pbError(401);
        }
        return pbError(404);
      });
      final emitted = <UserModel?>[];
      final sub = collect(ds, emitted);
      await _settle();

      final signOut = ds.signOutOtherDevices();
      await _settle();
      realtime.emit(_userTopic);
      await _settle();
      expect(count(_refreshPath), 0);

      gate.complete(_authBody(newToken));
      await signOut;
      await _settle();

      expect(count(_refreshPath), 1);
      expect(requests.last.headers['Authorization'], newToken);
      expect(ds.currentUser()?.uid, 'user-a');
      expect(emitted.where((u) => u == null), isEmpty);
      await sub.cancel();
    },
  );

  // Refresh of another event running when the own change starts: the change waits for it before its request
  test('should wait running refresh before own change', () async {
    final gate = Completer<http.Response>();
    final ds = build((request) async {
      if (request.url.path == _refreshPath) return gate.future;
      if (request.url.path == PbRoutes.changeEmail) return _authBody(newToken);
      return pbError(404);
    });
    final sub = collect(ds, []);
    await _settle();

    realtime.emit(_userTopic);
    await _settle();
    final change = ds.changeEmail(
      email: 'ana.lima@exemplo.com',
      currentPassword: 'abcd1234',
    );
    await _settle();
    expect(count(PbRoutes.changeEmail), 0);

    gate.complete(_authBody(oldToken));
    await change;

    final paths = requests.map((r) => r.url.path).toList();
    expect(paths, [_refreshPath, PbRoutes.changeEmail]);
    await sub.cancel();
  });

  // Signing out of the account or cancelling the stream cancels both subscriptions
  test('should unsubscribe on sign out and on cancel', () async {
    final ds = build(refreshes(200));
    final sub = collect(ds, []);
    await _settle();

    await ds.signOut();
    await _settle();
    expect(realtime.unsubscribeCount, 2);

    final ds2 = build(refreshes(200));
    final sub2 = collect(ds2, []);
    await _settle();
    await sub2.cancel();
    await _settle();
    expect(realtime.unsubscribeCount, 2);
    await sub.cancel();
  });

  // authState().first (lock screen) does not open a realtime subscription
  test('should not subscribe for authState().first', () async {
    final ds = build(refreshes(200));

    final user = await ds.authState().first;
    await _settle();
    realtime.emit(_userTopic);
    realtime.emit(RealtimeTopics.connect);
    await _settle();

    expect(user?.uid, 'user-a');
    expect(requests, isEmpty);
  });

  // Realtime subscription fails (no internet): warning log, the stream keeps emitting the user
  test('should keep emitting user when realtime subscribe fails', () async {
    final failing = _ThrowingRealtimeSubscriber();
    session = buildSession(refreshes(200));
    final ds = AuthRemoteDataSourceImpl(session, failing);
    final emitted = <UserModel?>[];
    final errors = <Object>[];
    final sub = collect(ds, emitted, errors: errors);
    await _settle();

    session.client.authStore.save(
      newToken,
      RecordModel.fromJson({
        'id': 'user-a',
        'collectionName': 'users',
        'email': 'a@b.com',
        'name': 'Ana',
      }),
    );
    await _settle();

    expect(failing.attempts, greaterThan(0));
    expect(errors, isEmpty);
    expect(emitted.first?.uid, 'user-a');
    expect(emitted.last?.displayName, 'Ana');
    await sub.cancel();
  });

  // REQ-009: password change accepted: this device keeps 1 open session (token returned by the sign out route saved)
  test(
    'should keep this device signed in after own password change and sign out of other devices',
    () async {
      final ds = build((request) async {
        if (request.method == 'PATCH') return pbJson({'id': 'user-a'});
        if (request.url.path == _authPath) return _authBody(newToken);
        if (request.url.path == PbRoutes.signOutOtherDevices) {
          return _authBody(newToken);
        }
        return pbError(404);
      });
      final sub = collect(ds, []);
      await _settle();

      await ds.changePassword(
        currentPassword: 'abcd1234',
        newPassword: 'Wxyz5678',
      );
      await ds.signOutOtherDevices();
      await _settle();

      expect(ds.currentUser()?.uid, 'user-a');
      expect(count(PbRoutes.signOutOtherDevices), 1);
      await sub.cancel();
    },
  );

  // The wrong-password error of an own change keeps coming out and no refresh is lost
  test('should rethrow the change error and keep the session', () async {
    final ds = build((request) async {
      if (request.method == 'PATCH') {
        return pbError(
          400,
          data: {
            'oldPassword': {'code': 'validation_invalid_old_password'},
          },
        );
      }
      return pbError(404);
    });
    final sub = collect(ds, []);
    await _settle();

    await expectLater(
      ds.changePassword(currentPassword: 'x', newPassword: 'Wxyz5678'),
      throwsA(isA<Object>()),
    );
    expect(ds.currentUser()?.uid, 'user-a');
    await sub.cancel();
  });
}
