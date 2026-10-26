import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/error/pocketbase_error_mapper.dart';
import 'package:pocketbase/pocketbase.dart';

ClientException _error(
  int status, [
  Map<String, dynamic> response = const {},
]) => ClientException(statusCode: status, response: response);

Map<String, dynamic> _body(Map<String, dynamic> data) => {
  'status': 400,
  'message': 'Failed',
  'data': data,
};

Map<String, dynamic> _batchItem(int status, Map<String, dynamic> data) => {
  'code': 'batch_request_failed',
  'response': {'status': status, 'data': data},
};

void main() {
  group('status table', () {
    test('0 and abort are network', () {
      expect(mapPocketBaseError(_error(0)), isA<NetworkException>());
      expect(
        mapPocketBaseError(ClientException(isAbort: true, statusCode: 400)),
        isA<NetworkException>(),
      );
    });

    test('404 is not found', () {
      expect(mapPocketBaseError(_error(404)), isA<NotFoundException>());
    });

    test('401 and 403 are permission', () {
      expect(mapPocketBaseError(_error(401)), isA<PermissionException>());
      expect(mapPocketBaseError(_error(403)), isA<PermissionException>());
    });

    test('429, 408, 500 and 503 are server', () {
      for (final status in [429, 408, 500, 503]) {
        expect(mapPocketBaseError(_error(status)), isA<ServerException>());
      }
    });
  });

  group('400', () {
    test('unique violation is conflict', () {
      final e = _error(
        400,
        _body({
          'user': {'code': 'validation_not_unique', 'message': 'x'},
        }),
      );
      expect(mapPocketBaseError(e), isA<ConflictException>());
    });

    test('repeated id is conflict', () {
      final e = _error(
        400,
        _body({
          'id': {'code': 'validation_pk_invalid'},
        }),
      );
      expect(mapPocketBaseError(e), isA<ConflictException>());
    });

    test('other validation is server', () {
      final e = _error(
        400,
        _body({
          'title': {'code': 'validation_required'},
        }),
      );
      expect(mapPocketBaseError(e), isA<ServerException>());
    });

    test('missing or malformed data is server', () {
      expect(mapPocketBaseError(_error(400)), isA<ServerException>());
      expect(
        mapPocketBaseError(_error(400, {'data': 'texto'})),
        isA<ServerException>(),
      );
    });
  });

  group('batch', () {
    test('map: 404 inside is not found', () {
      final e = _error(
        400,
        _body({
          'requests': {'1': _batchItem(404, {})},
        }),
      );
      expect(mapPocketBaseError(e), isA<NotFoundException>());
    });

    test('map: unique inside is conflict', () {
      final e = _error(
        400,
        _body({
          'requests': {
            '1': _batchItem(400, {
              'id': {'code': 'validation_not_unique'},
            }),
          },
        }),
      );
      expect(mapPocketBaseError(e), isA<ConflictException>());
    });

    test('list works the same', () {
      final e = _error(
        400,
        _body({
          'requests': [
            <String, dynamic>{},
            _batchItem(400, {
              'id': {'code': 'validation_not_unique'},
            }),
          ],
        }),
      );
      expect(mapPocketBaseError(e), isA<ConflictException>());
    });

    test('403 inside is permission', () {
      final e = _error(
        400,
        _body({
          'requests': {'0': _batchItem(403, {})},
        }),
      );
      expect(mapPocketBaseError(e), isA<PermissionException>());
    });

    test('item without response is server', () {
      final e = _error(
        400,
        _body({
          'requests': {
            '0': {'code': 'batch_request_failed'},
          },
        }),
      );
      expect(mapPocketBaseError(e), isA<ServerException>());
    });
  });

  test('ConflictException maps to ServerFailure', () {
    expect(const ConflictException().toFailure(), isA<ServerFailure>());
  });
}
