import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/auth/data/datasources/account_data_remote_data_source.dart';

import '../../../../helpers/pocketbase_test_support.dart';

const _tasksPath = '/api/collections/tasks/records';
const _recurringPath = '/api/collections/recurring_tasks/records';

Map<String, dynamic> _task(String id, {String? parent}) => {
  'id': id,
  'collectionName': 'tasks',
  'user': 'user-a',
  'title': 'Tarefa $id',
  'list': 'l1',
  'parent': parent ?? '',
  'created_at': '2026-10-15 11:00:00.000Z',
  'is_done': false,
  'has_children': false,
  'spent_minutes': 0,
};

Map<String, dynamic> _recurring(String id) => {
  'id': id,
  'collectionName': 'recurring_tasks',
  'user': 'user-a',
};

/// Reads the requests of a `POST /api/batch` (JSON or multipart payload).
List<Map<String, dynamic>> _batchRequests(http.Request r) {
  final Object? decoded;
  if (r.headers['content-type']?.startsWith('multipart/') ?? false) {
    final match = RegExp(
      r'name="@jsonPayload"\r\n\r\n(.*?)\r\n--',
      dotAll: true,
    ).firstMatch(r.body);
    decoded = jsonDecode(match!.group(1)!);
  } else {
    decoded = jsonDecode(r.body);
  }
  return ((decoded! as Map<String, dynamic>)['requests'] as List)
      .cast<Map<String, dynamic>>();
}

void main() {
  late List<http.Request> requests;

  AccountDataRemoteDataSourceImpl build({
    List<Map<String, dynamic>> tasks = const [],
    List<Map<String, dynamic>> recurring = const [],
    http.Response? batchResponse,
    bool signedIn = true,
  }) {
    requests = [];
    Future<http.Response> handler(http.Request r) async {
      requests.add(r);
      final page = switch (r.url.path) {
        _tasksPath => tasks,
        _recurringPath => recurring,
        _ => null,
      };
      if (page != null) return pbJson(pbPage(page, perPage: 1000));
      if (batchResponse != null) return batchResponse;
      final n = _batchRequests(r).length;
      return pbJson([
        for (var i = 0; i < n; i++) {'status': 204, 'body': null},
      ]);
    }

    final session = signedIn
        ? signedInSession(handler)
        : signedOutSession(handler);
    return AccountDataRemoteDataSourceImpl(session);
  }

  List<http.Request> batches() =>
      requests.where((r) => r.url.path == '/api/batch').toList();

  List<String> deletedUrls() => [
    for (final b in batches())
      for (final r in _batchRequests(b)) '${r['method']} ${r['url']}',
  ];

  test('should not send batch when there are no records', () async {
    await build().deleteBlockingRecords();
    expect(batches(), isEmpty);
    expect(requests.map((r) => r.url.path), [_tasksPath, _recurringPath]);
  });

  test(
    'should delete children before parents and recurring tasks last',
    () async {
      await build(
        tasks: [
          _task('mae'),
          _task('filha', parent: 'mae'),
          _task('neta', parent: 'filha'),
        ],
        recurring: [_recurring('r1')],
      ).deleteBlockingRecords();

      expect(batches(), hasLength(1));
      expect(deletedUrls(), [
        'DELETE /api/collections/tasks/records/neta',
        'DELETE /api/collections/tasks/records/filha',
        'DELETE /api/collections/tasks/records/mae',
        'DELETE /api/collections/recurring_tasks/records/r1',
      ]);
    },
  );

  test('should split deletion into batches of 500', () async {
    await build(
      tasks: [for (var i = 0; i < 501; i++) _task('t$i')],
      recurring: [_recurring('r1')],
    ).deleteBlockingRecords();

    final sent = batches();
    expect(sent.map((b) => _batchRequests(b).length), [500, 2]);
    expect(
      deletedUrls().last,
      'DELETE /api/collections/recurring_tasks/records/r1',
    );
    expect(deletedUrls().toSet(), hasLength(502));
  });

  test('should throw UnauthenticatedException without session', () async {
    await expectLater(
      build(signedIn: false).deleteBlockingRecords(),
      throwsA(isA<UnauthenticatedException>()),
    );
    expect(requests, isEmpty);
  });

  test('should map server error', () async {
    await expectLater(
      build(
        tasks: [_task('a')],
        batchResponse: pbError(500),
      ).deleteBlockingRecords(),
      throwsA(isA<ServerException>()),
    );
  });
}
