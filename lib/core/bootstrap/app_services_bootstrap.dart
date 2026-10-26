import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import '../data/pocketbase/pocketbase_session.dart';
import '../di/injection.dart';

/// Firebase (until step 14) + PocketBase client + always-online Firestore + DI. Used by the app (`main`) and by
/// the lock screen background entrypoint — the Firestore settings must be the
/// same in both engines of the same process (the native instance is shared).
/// [refreshSession] renews the PocketBase token (foreground app only; the
/// background engine just reads the saved one).
Future<void> initializeAppServices({bool refreshSession = true}) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App sempre online — sem cache offline (ver design/fricção zero).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  await configureDependencies();

  if (refreshSession) {
    await getIt<PocketBaseSession>().refreshSession();
  }
}
