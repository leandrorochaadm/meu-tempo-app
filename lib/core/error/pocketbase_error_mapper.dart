import 'package:pocketbase/pocketbase.dart';

import '../logging/app_logger.dart';
import 'exceptions.dart';
import 'pocketbase_error_code_enum.dart';

const int _statusNoConnection = 0;
const int _statusBadRequest = 400;
const int _statusUnauthorized = 401;
const int _statusForbidden = 403;
const int _statusNotFound = 404;
const int _statusTooManyRequests = 429;
const int _statusServerError = 500;

const String _keyData = 'data';
const String _keyRequests = 'requests';
const String _keyResponse = 'response';
const String _keyStatus = 'status';
const String _keyCode = 'code';
const String _keyMessage = 'message';

/// Translates a [ClientException] from the PocketBase SDK into an
/// [AppException]. The server message goes only to the log, never to the
/// screen.
AppException mapPocketBaseError(ClientException e) {
  final data = _asMap(e.response[_keyData]);
  final exception = _translate(
    e.isAbort ? _statusNoConnection : e.statusCode,
    data,
    unwrapBatch: true,
  );
  AppLogger.logWarning(
    'PocketBase error ${e.statusCode} ${_firstFieldCode(data)}: '
    '${e.response[_keyMessage]}',
  );
  return exception;
}

AppException _translate(
  int status,
  Map<String, dynamic>? data, {
  required bool unwrapBatch,
}) {
  if (status == _statusNoConnection) return const NetworkException();
  if (status == _statusNotFound) return const NotFoundException();
  if (status == _statusUnauthorized || status == _statusForbidden) {
    return const PermissionException();
  }
  if (status == _statusTooManyRequests || status >= _statusServerError) {
    return const ServerException();
  }
  if (status != _statusBadRequest || data == null) {
    return const ServerException();
  }
  if (_hasConflict(data)) return const ConflictException();
  if (unwrapBatch) {
    final inner = _firstFailedBatchResponse(data);
    if (inner != null) {
      final innerStatus = inner[_keyStatus];
      return _translate(
        innerStatus is int ? innerStatus : _statusServerError,
        _asMap(inner[_keyData]),
        unwrapBatch: false,
      );
    }
  }
  return const ServerException();
}

bool _hasConflict(Map<String, dynamic> data) {
  for (final field in data.values) {
    final map = _asMap(field);
    if (map == null) continue;
    final code = map[_keyCode];
    if (code is String && PocketBaseErrorCodeEnum.fromApi(code).isConflict) {
      return true;
    }
  }
  return false;
}

Map<String, dynamic>? _firstFailedBatchResponse(Map<String, dynamic> data) {
  final requests = data[_keyRequests];
  final Iterable<dynamic> items = switch (requests) {
    final Map<dynamic, dynamic> map => map.values,
    final List<dynamic> list => list,
    _ => const [],
  };
  for (final item in items) {
    final map = _asMap(item);
    if (map == null) continue;
    final code = PocketBaseErrorCodeEnum.fromApi(map[_keyCode] as String?);
    if (code != PocketBaseErrorCodeEnum.batchRequestFailed) continue;
    final response = _asMap(map[_keyResponse]);
    if (response != null) return response;
  }
  return null;
}

String _firstFieldCode(Map<String, dynamic>? data) {
  if (data == null) return PocketBaseErrorCodeEnum.unknown.apiValue;
  for (final field in data.values) {
    final code = _asMap(field)?[_keyCode];
    if (code is String) return code;
  }
  return PocketBaseErrorCodeEnum.unknown.apiValue;
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is! Map) return null;
  return {for (final entry in value.entries) entry.key.toString(): entry.value};
}
