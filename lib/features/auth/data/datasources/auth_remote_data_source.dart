import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/data/pocketbase/pocketbase_session.dart';
import '../../../../core/data/pocketbase/realtime_subscriber.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/pocketbase_error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/user_model.dart';

const int _statusBadRequest = 400;
const String _methodPost = 'POST';
const String _keyToken = 'token';
const String _keyRecord = 'record';

/// PocketBase auth access. Throws [AppException] on error.
abstract class AuthRemoteDataSource {
  /// Signs in with e-mail and password. The user arrives through [authState].
  Future<void> signInWithEmail(String email, String password);

  /// Creates the user record and signs in. Throws [EmailAlreadyInUseException]
  /// when the e-mail already has an account (REQ-005), else [AppException].
  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  });
  Future<void> signOut();

  /// Deletes the signed-in user's record. The SDK clears the session on
  /// success; an account already gone (404) also clears it, without error.
  Future<void> deleteCurrentUser();

  /// Saves the signed-in user's name. The SDK refreshes the auth store, so
  /// [authState] emits the new name.
  Future<void> updateDisplayName(String displayName);

  /// Changes the e-mail through the server route; the SDK auth store gets the
  /// new token. Throws [WrongCurrentPasswordException] or
  /// [EmailAlreadyInUseException] (REQ-007), else [AppException].
  Future<void> changeEmail({
    required String email,
    required String currentPassword,
  });

  /// Saves the new password and signs in again with it. Throws
  /// [WrongCurrentPasswordException] (REQ-008), else [AppException].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Renews the token key on the server (other devices lose the session) and
  /// saves the new token of this device. // REQ-009
  Future<void> signOutOtherDevices();
  Stream<UserModel?> authState();
  UserModel? currentUser();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // Without a subscriber the session is not watched (old tests).
  AuthRemoteDataSourceImpl(this._session, [this._realtime]);

  @factoryMethod
  static AuthRemoteDataSourceImpl create(
    PocketBaseSession session,
    RealtimeSubscriber realtime,
  ) => AuthRemoteDataSourceImpl(session, realtime);

  final PocketBaseSession _session;
  final RealtimeSubscriber? _realtime;

  // REQ-009: own changes (password, e-mail, sign out of other devices) defer
  // the session checks until the new token is saved.
  int _ownChangesInFlight = 0;
  bool _checkPending = false;
  Future<void>? _refreshInFlight;

  Future<T> _ownChange<T>(Future<T> Function() action) async {
    final running = _refreshInFlight;
    if (running != null) await running;
    _ownChangesInFlight++;
    try {
      return await action();
    } finally {
      _ownChangesInFlight--;
      if (_ownChangesInFlight == 0 && _checkPending) {
        _checkPending = false;
        await _session.refreshSession();
      }
    }
  }

  void _onSessionEvent() {
    if (_ownChangesInFlight > 0) {
      _checkPending = true;
      return;
    }
    if (_refreshInFlight != null) return;
    final refresh = _session.refreshSession();
    _refreshInFlight = refresh;
    refresh.whenComplete(() {
      if (identical(_refreshInFlight, refresh)) _refreshInFlight = null;
    });
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _session.client
          .collection(PbCollections.users)
          .authWithPassword(email, password);
    } on ClientException catch (e) {
      // 400 = wrong credentials or unknown account.
      if (e.statusCode == _statusBadRequest) throw const AuthException();
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final users = _session.client.collection(PbCollections.users);
    try {
      await users.create(
        body: {
          PbFields.email: email,
          PbFields.password: password,
          PbFields.passwordConfirm: password,
          PbFields.name: displayName,
        },
      );
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is ConflictException && isFieldNotUnique(e, PbFields.email)) {
        throw const EmailAlreadyInUseException(); // REQ-005
      }
      throw error;
    }
    try {
      await users.authWithPassword(email, password);
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> signOut() async {
    _session.client.authStore.clear();
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final userId = _session.userId;
    try {
      await _session.client
          .collection(PbCollections.users)
          .update(userId, body: {PbFields.name: displayName});
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> changeEmail({
    required String email,
    required String currentPassword,
  }) => _ownChange(() => _changeEmail(email, currentPassword));

  Future<void> _changeEmail(String email, String currentPassword) async {
    _requireSession();
    try {
      final json = await _session.client.send<Map<String, dynamic>>(
        PbRoutes.changeEmail,
        method: _methodPost,
        body: {PbFields.email: email, PbFields.oldPassword: currentPassword},
      );
      _saveSession(json);
    } on ClientException catch (e) {
      if (isInvalidOldPassword(e, PbFields.oldPassword)) {
        throw const WrongCurrentPasswordException(); // REQ-007
      }
      if (isFieldNotUnique(e, PbFields.email)) {
        throw const EmailAlreadyInUseException(); // REQ-007
      }
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _ownChange(() => _changePassword(currentPassword, newPassword));

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final userId = _session.userId;
    final email = currentUser()!.email;
    final users = _session.client.collection(PbCollections.users);
    try {
      await users.update(
        userId,
        body: {
          PbFields.password: newPassword,
          PbFields.passwordConfirm: newPassword,
          PbFields.oldPassword: currentPassword,
        },
      );
    } on ClientException catch (e) {
      if (isInvalidOldPassword(e, PbFields.oldPassword)) {
        throw const WrongCurrentPasswordException(); // REQ-008
      }
      throw mapPocketBaseError(e);
    }
    try {
      // The token key changed: this device needs a new token.
      await users.authWithPassword(email, newPassword);
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  @override
  Future<void> signOutOtherDevices() => _ownChange(_signOutOtherDevices);

  Future<void> _signOutOtherDevices() async {
    _requireSession();
    try {
      final json = await _session.client.send<Map<String, dynamic>>(
        PbRoutes.signOutOtherDevices,
        method: _methodPost,
      );
      _saveSession(json);
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);
    }
  }

  /// Throws [UnauthenticatedException] when signed out, before any request.
  void _requireSession() => _session.userId;

  void _saveSession(Map<String, dynamic> json) {
    _session.client.authStore.save(
      json[_keyToken] as String,
      RecordModel.fromJson(json[_keyRecord] as Map<String, dynamic>),
    );
  }

  @override
  Future<void> deleteCurrentUser() async {
    final userId = _session.userId;
    try {
      await _session.client.collection(PbCollections.users).delete(userId);
    } on ClientException catch (e) {
      final error = mapPocketBaseError(e);
      if (error is NotFoundException) {
        _session.client.authStore.clear();
        return;
      }
      throw error;
    }
  }

  @override
  Stream<UserModel?> authState() {
    late final StreamController<UserModel?> controller;
    StreamSubscription<AuthStoreEvent>? sub;
    final realtime = _realtime;
    var cancelled = false;
    String? watchedId;
    var watchEpoch = 0;
    final unsubscribes = <RealtimeUnsubscribe>[];

    Future<void> stopWatching() async {
      watchedId = null;
      watchEpoch++;
      final pending = List.of(unsubscribes);
      unsubscribes.clear();
      for (final unsubscribe in pending) {
        try {
          await unsubscribe();
        } catch (error) {
          AppLogger.logWarning('Could not stop watching session: $error');
        }
      }
    }

    // REQ-009: watch the own user record while signed in.
    Future<void> check() async {
      if (realtime == null || cancelled) return;
      final id = _session.isSignedIn
          ? _session.client.authStore.record!.id
          : null;
      if (id == watchedId) return;
      await stopWatching();
      if (id == null) return;
      watchedId = id;
      final epoch = watchEpoch;
      for (final topic in [
        RealtimeTopics.record(PbCollections.users, id),
        RealtimeTopics.connect,
      ]) {
        try {
          final unsubscribe = await realtime.subscribe(topic, _onSessionEvent);
          if (cancelled || epoch != watchEpoch) {
            await unsubscribe();
          } else {
            unsubscribes.add(unsubscribe);
          }
        } catch (error) {
          AppLogger.logWarning('Could not watch session: $error');
        }
      }
    }

    controller = StreamController<UserModel?>(
      onListen: () {
        controller.add(currentUser());
        sub = _session.client.authStore.onChange.listen((_) {
          controller.add(currentUser());
          check();
        });
        Future(check);
      },
      onCancel: () async {
        cancelled = true;
        await sub?.cancel();
        await stopWatching();
      },
    );
    return controller.stream;
  }

  @override
  UserModel? currentUser() {
    if (!_session.isSignedIn) return null;
    return UserModel.fromRecord(_session.client.authStore.record!);
  }
}
