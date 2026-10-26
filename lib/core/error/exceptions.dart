import 'package:firebase_core/firebase_core.dart';

import 'auth_failures.dart';
import 'failures.dart';

/// Exceções internas da camada `data`. Os DataSources lançam estas; os
/// Repositories capturam e convertem para [Failure] (`toFailure`).
sealed class AppException implements Exception {
  const AppException();

  Failure toFailure();
}

class ServerException extends AppException {
  const ServerException();
  @override
  Failure toFailure() => const ServerFailure();
}

class NetworkException extends AppException {
  const NetworkException();
  @override
  Failure toFailure() => const NetworkFailure();
}

class PermissionException extends AppException {
  const PermissionException();
  @override
  Failure toFailure() => const PermissionDeniedFailure();
}

class NotFoundException extends AppException {
  const NotFoundException();
  @override
  Failure toFailure() => const NotFoundFailure();
}

/// Repeated id or unique key (`UNIQUE (user)`, generation marker). Whoever
/// does not handle it sees a server error.
class ConflictException extends AppException {
  const ConflictException();
  @override
  Failure toFailure() => const ServerFailure();
}

class UnauthenticatedException extends AppException {
  const UnauthenticatedException();
  @override
  Failure toFailure() => const UnauthenticatedFailure();
}

class AuthException extends AppException {
  const AuthException();
  @override
  Failure toFailure() => const AuthFailure();
}

/// Mapeia o `code` de uma [FirebaseException] do Firestore para [AppException].
AppException mapFirestoreException(FirebaseException e) => switch (e.code) {
  'permission-denied' => const PermissionException(),
  'unavailable' => const NetworkException(),
  'not-found' => const NotFoundException(),
  'unauthenticated' => const UnauthenticatedException(),
  _ => const ServerException(),
};
