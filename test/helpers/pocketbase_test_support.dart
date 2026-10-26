import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meu_tempo/core/data/pocketbase/pocketbase_session.dart';
import 'package:meu_tempo/core/data/pocketbase/realtime_subscriber.dart';
import 'package:pocketbase/pocketbase.dart';

String fakeJwt({required DateTime expiresAt}) {
  String enc(Map<String, Object?> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp = expiresAt.millisecondsSinceEpoch ~/ 1000;
  return '${enc({'alg': 'HS256'})}.${enc({'exp': exp})}.x';
}

PocketBaseSession signedOutSession(MockClientHandler handler) =>
    PocketBaseSession(
      PocketBase(
        'http://pb.test',
        authStore: AuthStore(),
        httpClientFactory: () => MockClient(handler),
      ),
    );

PocketBaseSession signedInSession(
  MockClientHandler handler, {
  String userId = 'user-a',
}) {
  final session = signedOutSession(handler);
  session.client.authStore.save(
    fakeJwt(expiresAt: DateTime.now().add(const Duration(days: 1))),
    RecordModel.fromJson({'id': userId}),
  );
  return session;
}

http.Response pbJson(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> pbPage(
  List<Map<String, dynamic>> items, {
  int perPage = 500,
}) => {
  'page': 1,
  'perPage': perPage,
  'totalItems': -1,
  'totalPages': -1,
  'items': items,
};

http.Response pbError(int status, {Map<String, dynamic> data = const {}}) =>
    pbJson({
      'status': status,
      'message': 'error',
      'data': data,
    }, status: status);

http.Response pbNotUnique(String field) => pbError(
  400,
  data: {
    field: {
      'code': 'validation_not_unique',
      'message': 'Value must be unique.',
    },
  },
);

class FakeRealtimeSubscriber implements RealtimeSubscriber {
  final Map<String, List<void Function()>> _listeners = {};
  int _unsubscribeCount = 0;

  int get unsubscribeCount => _unsubscribeCount;

  @override
  Future<RealtimeUnsubscribe> subscribe(
    String topic,
    void Function() onEvent,
  ) async {
    _listeners.putIfAbsent(topic, () => []).add(onEvent);
    return () async {
      _unsubscribeCount++;
      _listeners[topic]?.remove(onEvent);
    };
  }

  void emit(String topic) {
    for (final listener in List.of(_listeners[topic] ?? const [])) {
      listener();
    }
  }
}
