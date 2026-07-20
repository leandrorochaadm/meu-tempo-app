import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Acesso ao Firebase Auth. Lança [AppException] em caso de erro.
abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Stream<UserModel?> authState();
  UserModel? currentUser();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      // Fluxo Web: popup do Google via firebase_auth (sem plugin extra).
      final credential = await _auth.signInWithPopup(provider);
      final user = credential.user;
      if (user == null) throw const AuthException();
      return UserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }

  @override
  Stream<UserModel?> authState() => _auth.authStateChanges().map(
        (user) => user == null ? null : UserModel.fromFirebaseUser(user),
      );

  @override
  UserModel? currentUser() {
    final user = _auth.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }
}
