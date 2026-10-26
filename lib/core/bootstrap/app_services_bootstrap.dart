import '../data/pocketbase/pocketbase_session.dart';
import '../di/injection.dart';

/// Builds the DI container (PocketBase client with the saved token). Used by
/// the app (`main`) and by the lock screen background entrypoint.
/// [refreshSession] renews the PocketBase token (foreground app only; the
/// background engine just reads the saved one).
Future<void> initializeAppServices({bool refreshSession = true}) async {
  await configureDependencies();

  if (refreshSession) {
    await getIt<PocketBaseSession>().refreshSession();
  }
}
