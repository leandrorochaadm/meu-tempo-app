import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/firestore_paths.dart';
import 'package:meu_tempo/features/task/data/datasources/task_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockAuth auth;
  late TaskRemoteDataSourceImpl dataSource;

  const uid = 'u1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = _MockAuth();
    final user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(uid);
    dataSource = TaskRemoteDataSourceImpl(firestore, auth);
  });

  CollectionReference<Map<String, dynamic>> collection() =>
      firestore.collection(FirestorePaths.tasks(uid));

  Future<void> seed(String id, {required bool isDone, int order = 0}) =>
      collection().doc(id).set({
        'title': id,
        'listId': 'inbox',
        'createdAt': Timestamp.fromDate(DateTime(2026, 7, 20 + order)),
        'isDone': isDone,
        'hasChildren': false,
        'spentMinutes': 0,
      });

  test('includeDone: false traz apenas as pendentes (filtro no backend)',
      () async {
    await seed('pendente', isDone: false);
    await seed('concluida', isDone: true);

    final models = await dataSource.watchTasks(includeDone: false).first;

    expect(models.map((m) => m.id), ['pendente']);
  });

  test('includeDone: true traz todas (pendentes e concluídas)', () async {
    await seed('pendente', isDone: false);
    await seed('concluida', isDone: true);

    final models = await dataSource.watchTasks(includeDone: true).first;

    expect(models.map((m) => m.id), containsAll(['pendente', 'concluida']));
  });

  test('ordena por createdAt desc (mais recente primeiro)', () async {
    await seed('antiga', isDone: false, order: 0);
    await seed('nova', isDone: false, order: 5);

    final models = await dataSource.watchTasks(includeDone: false).first;

    expect(models.map((m) => m.id).toList(), ['nova', 'antiga']);
  });

  test('só enxerga a coleção do usuário logado (isolamento)', () async {
    await seed('minha', isDone: false);
    await firestore.collection(FirestorePaths.tasks('outro')).doc('alheia').set({
      'title': 'Alheia',
      'listId': 'inbox',
      'createdAt': Timestamp.fromDate(DateTime(2026, 7, 20)),
      'isDone': false,
      'hasChildren': false,
      'spentMinutes': 0,
    });

    final models = await dataSource.watchTasks(includeDone: true).first;

    expect(models.map((m) => m.id), ['minha']);
  });
}
