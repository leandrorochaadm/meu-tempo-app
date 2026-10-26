import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../constants/secure_storage_keys.dart';
import '../../logging/app_logger.dart';

/// Builds the single [PocketBase] client with the session persisted in the
/// secure storage. The only place that knows `flutter_secure_storage`.
abstract final class PocketBaseClientFactory {
  /// `first_unlock` lets the lock screen background engine read the token
  /// while the phone is locked (iOS).
  static const FlutterSecureStorage secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<PocketBase> create({
    required String baseUrl,
    FlutterSecureStorage storage = secureStorage,
  }) async {
    final authStore = await _buildAuthStore(storage);
    return PocketBase(baseUrl, authStore: authStore);
  }

  static Future<AsyncAuthStore> _buildAuthStore(
    FlutterSecureStorage storage,
  ) async {
    AsyncAuthStore build(String? initial) => AsyncAuthStore(
      save: (data) =>
          storage.write(key: SecureStorageKeys.pocketBaseAuth, value: data),
      clear: () => storage.delete(key: SecureStorageKeys.pocketBaseAuth),
      initial: initial,
    );

    String? initial;
    try {
      initial = await storage.read(key: SecureStorageKeys.pocketBaseAuth);
      final store = build(initial);
      // The SDK silently ignores unreadable data: treat it as corrupted.
      if (initial != null && initial.isNotEmpty && store.token.isEmpty) {
        throw const FormatException('Unreadable saved session');
      }
      return store;
    } catch (error, stack) {
      AppLogger.logWarning(
        'Discarding saved PocketBase session: $error\n$stack',
      );
      try {
        await storage.delete(key: SecureStorageKeys.pocketBaseAuth);
      } catch (_) {
        // Nothing else to do; the boot must go on without a session.
      }
      return build(null);
    }
  }
}
