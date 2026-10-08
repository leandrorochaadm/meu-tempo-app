import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import '../di/injection.dart';

/// Firebase + always-online Firestore + DI. Used by the app (`main`) and by
/// the lock screen background entrypoint — the Firestore settings must be the
/// same in both engines of the same process (the native instance is shared).
Future<void> initializeAppServices() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App sempre online — sem cache offline (ver design/fricção zero).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  await configureDependencies();
}
