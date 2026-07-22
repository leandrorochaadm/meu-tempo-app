import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

/// Inicializa o container de DI. Gerado por `injectable` em `injection.config.dart`
/// (rodar `dart run build_runner build`). Assíncrono por causa do
/// `@preResolve` do [SharedPreferences] — o `main` precisa dar `await`.
@InjectableInit()
Future<void> configureDependencies() => getIt.init();

/// Registra as instâncias do Firebase como dependências únicas — nunca usar
/// `.instance` direto nos DataSources (testabilidade).
@module
abstract class FirebaseModule {
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
}

/// Registra o armazenamento local de preferências de UI (ex.: filtro de lista).
/// `@preResolve` resolve o `Future` na inicialização do container.
@module
abstract class PreferencesModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
