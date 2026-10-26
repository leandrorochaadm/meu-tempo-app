import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/data/pocketbase/pocketbase_session.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/pocketbase_error_mapper.dart';
import '../models/user_model.dart';

const int _statusBadRequest = 400;

/// PocketBase auth access. Throws [AppException] on error.
abstract class AuthRemoteDataSource {
  /// Signs in with e-mail and password. The user arrives through [authState].
  Future<void> signInWithEmail(String email, String password);
  Future<void> signOut();
  Stream<UserModel?> authState();
  UserModel? currentUser();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._session);

  final PocketBaseSession _session;

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
  Future<void> signOut() async {
    _session.client.authStore.clear();
  }

  @override
  Stream<UserModel?> authState() {
    late final StreamController<UserModel?> controller;
    StreamSubscription<AuthStoreEvent>? sub;
    controller = StreamController<UserModel?>(
      onListen: () {
        controller.add(currentUser());
        sub = _session.client.authStore.onChange.listen(
          (_) => controller.add(currentUser()),
        );
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  @override
  UserModel? currentUser() {
    if (!_session.isSignedIn) return null;
    return UserModel.fromRecord(_session.client.authStore.record!);
  }
}
