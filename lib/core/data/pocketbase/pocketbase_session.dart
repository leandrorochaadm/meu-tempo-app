import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../constants/pb_schema.dart';
import '../../error/exceptions.dart';
import '../../logging/app_logger.dart';

const int _statusUnauthorized = 401;
const int _statusForbidden = 403;
const int _statusNotFound = 404;

/// Single PocketBase client plus the signed-in user. Injected into the
/// datasources.
@lazySingleton
class PocketBaseSession {
  PocketBaseSession(this.client);

  static const Duration refreshTimeout = Duration(seconds: 10);

  final PocketBase client;

  /// Only checks the token expiry on the device; the server has the last word.
  bool get isSignedIn =>
      client.authStore.isValid && client.authStore.record != null;

  String get userId {
    if (!isSignedIn) throw const UnauthenticatedException();
    return client.authStore.record!.id;
  }

  /// Renews the token. Never throws: the session is cleared only when the
  /// server says the account is gone or the token is refused.
  Future<void> refreshSession({Duration timeout = refreshTimeout}) async {
    if (!isSignedIn) return;
    try {
      await client
          .collection(PbCollections.users)
          .authRefresh()
          .timeout(timeout);
    } on ClientException catch (error, stack) {
      switch (error.statusCode) {
        case _statusUnauthorized || _statusForbidden || _statusNotFound:
          client.authStore.clear();
          AppLogger.logInfo('Session rejected by the server; cleared');
        default:
          AppLogger.logWarning(
            'Could not refresh session (${error.statusCode}): $error\n$stack',
          );
      }
    } catch (error, stack) {
      AppLogger.logWarning('Could not refresh session: $error\n$stack');
    }
  }
}
