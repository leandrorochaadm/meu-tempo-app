import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Acesso ao Firebase Auth. Lança [AppException] em caso de erro.
abstract class AuthRemoteDataSource {
  /// Inicia o login SSO Google via **redirect** (a página navega para o Google
  /// e volta). O login efetivo chega depois pelo [authState] — este método só
  /// dispara o fluxo, não retorna o usuário.
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Stream<UserModel?> authState();
  UserModel? currentUser();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<void> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      // Fluxo Web mobile: redirect (não popup). O popup é frágil em navegador
      // de celular e incompatível com cross-origin isolation; o redirect
      // navega para o Google e volta. O login chega pelo `authStateChanges`.
      await _auth.signInWithRedirect(provider);
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
