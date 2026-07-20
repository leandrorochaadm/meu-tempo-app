// PLACEHOLDER — substitua rodando `flutterfire configure` (gera este arquivo
// com as chaves reais do seu projeto Firebase). Os valores abaixo são fictícios
// e servem apenas para o código compilar até você conectar o Firebase.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    // A v1 é Web/PWA — outras plataformas não são suportadas nesta versão.
    throw UnsupportedError(
      'Plataforma não suportada. Rode `flutterfire configure`.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO_API_KEY',
    appId: 'TODO_APP_ID',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    authDomain: 'TODO_PROJECT_ID.firebaseapp.com',
    storageBucket: 'TODO_PROJECT_ID.appspot.com',
  );
}
