import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/secure_storage_keys.dart';
import 'package:meu_tempo/core/data/pocketbase/pocketbase_client_factory.dart';
import 'package:pocketbase/pocketbase.dart';

const _baseUrl = 'http://pb.test';
const _storage = FlutterSecureStorage();

String _jwt() {
  final exp =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  String enc(Map<String, Object?> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${enc({'alg': 'HS256'})}.${enc({'exp': exp})}.x';
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('empty storage gives no session', () async {
    final pb = await PocketBaseClientFactory.create(
      baseUrl: _baseUrl,
      storage: _storage,
    );
    expect(pb.authStore.token, isEmpty);
  });

  test('restores the saved session', () async {
    final first = await PocketBaseClientFactory.create(
      baseUrl: _baseUrl,
      storage: _storage,
    );
    first.authStore.save(
      _jwt(),
      RecordModel({'id': 'user-a', 'collectionName': 'users'}),
    );
    await Future<void>.delayed(Duration.zero);

    final second = await PocketBaseClientFactory.create(
      baseUrl: _baseUrl,
      storage: _storage,
    );
    expect(second.authStore.record?.id, 'user-a');
    expect(second.authStore.isValid, isTrue);
  });

  test('clear removes the key', () async {
    final pb = await PocketBaseClientFactory.create(
      baseUrl: _baseUrl,
      storage: _storage,
    );
    pb.authStore.save(_jwt(), RecordModel({'id': 'user-a'}));
    await Future<void>.delayed(Duration.zero);
    pb.authStore.clear();
    await Future<void>.delayed(Duration.zero);
    expect(
      await _storage.containsKey(key: SecureStorageKeys.pocketBaseAuth),
      isFalse,
    );
  });

  test('corrupted value gives no session and deletes the key', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureStorageKeys.pocketBaseAuth: '{não é json',
    });
    final pb = await PocketBaseClientFactory.create(
      baseUrl: _baseUrl,
      storage: _storage,
    );
    expect(pb.authStore.token, isEmpty);
    expect(
      await _storage.containsKey(key: SecureStorageKeys.pocketBaseAuth),
      isFalse,
    );
  });
}
