import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Acesso ao Firebase Auth. Lança [AppException] em caso de erro.
abstract class AuthRemoteDataSource {
  /// Inicia o login SSO Google. Usa **redirect** quando o app é servido no
  /// mesmo domínio do `authDomain` (produção) e **popup** caso contrário
  /// (dev em localhost). Em qualquer caso o usuário chega pelo [authState].
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Stream<UserModel?> authState();
  UserModel? currentUser();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._auth);

  final FirebaseAuth _auth;

  /// O `signInWithRedirect` só sobrevive ao retorno do Google quando o handler
  /// (`https://<authDomain>/__/auth/handler`) está na **mesma origem** da
  /// página: com o particionamento de storage do Chrome/Safari, o estado do
  /// redirect é descartado entre origens diferentes e o usuário volta
  /// deslogado. Em produção o PWA é servido no próprio `authDomain`, então o
  /// redirect vale — é o único fluxo confiável no PWA instalado (no iOS o
  /// popup abre fora do app e não retorna). Em dev (localhost) as origens
  /// diferem, e aí o popup é o que funciona.
  bool get _sameOriginAsAuthDomain =>
      _auth.app.options.authDomain == Uri.base.host;

  @override
  Future<void> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      if (_sameOriginAsAuthDomain) {
        await _auth.signInWithRedirect(provider);
      } else {
        await _auth.signInWithPopup(provider);
      }
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
