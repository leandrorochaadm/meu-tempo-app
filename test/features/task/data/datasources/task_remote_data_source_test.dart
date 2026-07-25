import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/firestore_paths.dart';
import 'package:meu_tempo/features/task/data/datasources/task_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/task_model.dart';
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

  group('escritas atômicas de hierarquia (WriteBatch)', () {
    TaskModel model(String id, {String? parentId}) => TaskModel(
          id: id,
          title: id.isEmpty ? 'Nova filha' : id,
          listId: 'inbox',
          createdAt: DateTime(2026, 7, 20),
          parentId: parentId,
        );

    Future<bool?> hasChildrenOf(String id) async {
      final doc = await collection().doc(id).get();
      return doc.data()?['hasChildren'] as bool?;
    }

    Future<List<String>> idsInCollection() async {
      final snap = await collection().get();
      return snap.docs.map((d) => d.id).toList();
    }

    test('createChild cria a filha e marca o pai no mesmo commit', () async {
      await seed('mae', isDone: false);

      final created = await dataSource.createChild(
        model('', parentId: 'mae'),
        parentId: 'mae',
      );

      expect(created.id, isNotEmpty);
      expect(created.parentId, 'mae');
      expect(await hasChildrenOf('mae'), isTrue);
      expect(await idsInCollection(), hasLength(2));
    });

    test('createChild devolve o model já com o id gerado', () async {
      await seed('mae', isDone: false);

      final created = await dataSource.createChild(
        model('', parentId: 'mae'),
        parentId: 'mae',
      );
      final ids = await idsInCollection();

      expect(ids, contains(created.id));
      expect(created.title, isNotEmpty);
    });

    test('moveTask grava a tarefa e ajusta os dois pais no mesmo commit',
        () async {
      await seed('maeAntiga', isDone: false);
      await seed('maeNova', isDone: false);
      await collection().doc('maeAntiga').update({'hasChildren': true});
      await seed('filha', isDone: false);

      await dataSource.moveTask(
        [model('filha', parentId: 'maeNova')],
        newParentId: 'maeNova',
        emptiedParentId: 'maeAntiga',
      );

      final filha = await collection().doc('filha').get();
      expect(filha.data()?['parentId'], 'maeNova');
      expect(await hasChildrenOf('maeNova'), isTrue);
      expect(await hasChildrenOf('maeAntiga'), isFalse);
    });

    test('moveTask sem emptiedParentId não toca no pai antigo', () async {
      await seed('maeAntiga', isDone: false);
      await seed('maeNova', isDone: false);
      await collection().doc('maeAntiga').update({'hasChildren': true});
      await seed('filha', isDone: false);

      await dataSource.moveTask(
        [model('filha', parentId: 'maeNova')],
        newParentId: 'maeNova',
      );

      // Ainda tem outra filha: continua marcada como mãe.
      expect(await hasChildrenOf('maeAntiga'), isTrue);
      expect(await hasChildrenOf('maeNova'), isTrue);
    });

    test('moveTask para raiz grava parentId nulo e libera o pai', () async {
      await seed('mae', isDone: false);
      await collection().doc('mae').update({'hasChildren': true});
      await seed('filha', isDone: false);

      await dataSource.moveTask(
        [model('filha')],
        emptiedParentId: 'mae',
      );

      final filha = await collection().doc('filha').get();
      expect(filha.data()?['parentId'], isNull);
      expect(await hasChildrenOf('mae'), isFalse);
    });

    test('deleteSubtree remove todos os ids e libera o pai no mesmo commit',
        () async {
      await seed('mae', isDone: false);
      await collection().doc('mae').update({'hasChildren': true});
      await seed('filha', isDone: false);
      await seed('neta', isDone: false);
      await seed('outra', isDone: false);

      await dataSource.deleteSubtree(
        ['filha', 'neta'],
        emptiedParentId: 'mae',
      );

      final ids = await idsInCollection();
      expect(ids, isNot(contains('filha')));
      expect(ids, isNot(contains('neta')));
      expect(ids, containsAll(['mae', 'outra']));
      expect(await hasChildrenOf('mae'), isFalse);
    });

    test('deleteSubtree sem emptiedParentId só remove', () async {
      await seed('mae', isDone: false);
      await collection().doc('mae').update({'hasChildren': true});
      await seed('filha', isDone: false);

      await dataSource.deleteSubtree(['filha']);

      expect(await idsInCollection(), ['mae']);
      expect(await hasChildrenOf('mae'), isTrue);
    });

    test('restoreSubtree recria com os ids originais e remarca o pai',
        () async {
      await seed('mae', isDone: false);

      await dataSource.restoreSubtree(
        [model('filha', parentId: 'mae'), model('neta', parentId: 'filha')],
        parentId: 'mae',
      );

      final ids = await idsInCollection();
      expect(ids, containsAll(['mae', 'filha', 'neta']));
      expect(await hasChildrenOf('mae'), isTrue);
      final neta = await collection().doc('neta').get();
      expect(neta.data()?['parentId'], 'filha');
    });

    test('restoreSubtree sem parentId (raiz) não remarca ninguém', () async {
      await dataSource.restoreSubtree([model('mae')]);

      expect(await idsInCollection(), ['mae']);
      expect(await hasChildrenOf('mae'), isFalse);
    });

    test('escritas atômicas ficam na coleção do usuário logado (isolamento)',
        () async {
      await seed('mae', isDone: false);

      await dataSource.createChild(model('', parentId: 'mae'), parentId: 'mae');

      final alheia =
          await firestore.collection(FirestorePaths.tasks('outro')).get();
      expect(alheia.docs, isEmpty);
      expect(await idsInCollection(), hasLength(2));
    });
  });
}
