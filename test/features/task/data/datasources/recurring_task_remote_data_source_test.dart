import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/firestore_paths.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/task/data/datasources/recurring_task_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/recurring_task_model.dart';
import 'package:meu_tempo/features/task/data/recurring_task_fields.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late RecurringTaskRemoteDataSourceImpl dataSource;

  const uid = 'u1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    final auth = _MockAuth();
    final user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(uid);
    dataSource = RecurringTaskRemoteDataSourceImpl(firestore, auth);
  });

  CollectionReference<Map<String, dynamic>> collection([String owner = uid]) =>
      firestore.collection(FirestorePaths.recurringTasks(owner));

  RecurringTaskModel model({
    String id = 'r1',
    String title = 'Academia',
    String listId = 'l1',
    DateTime? lastGeneratedOn,
  }) => RecurringTaskModel(
    id: id,
    title: title,
    listId: listId,
    estimatedMinutes: 60,
    importance: ImportanceEnum.high,
    weekdays: const [WeekdayEnum.monday],
    createdAt: DateTime(2026, 10, 1),
    lastGeneratedOn: lastGeneratedOn,
  );

  Future<void> seed(RecurringTaskModel m, [String owner = uid]) =>
      collection(owner).doc(m.id).set(m.toJson());

  Future<bool> claim(DateTime day) => dataSource.claimGeneration(
    'r1',
    day,
    canClaim: (m) => !m.toEntity().wasGeneratedOn(day),
  );

  Future<Timestamp?> storedMark() async {
    final snap = await collection().doc('r1').get();
    return snap.data()?[RecurringTaskFields.lastGeneratedOn] as Timestamp?;
  }

  test('create should persist and return the generated id', () async {
    final created = await dataSource.create(model(id: ''));

    expect(created.id, isNotEmpty);
    expect((await collection().doc(created.id).get()).exists, isTrue);
  });

  test('watchAll should order by title', () async {
    await seed(model(id: 'a', title: 'Ler'));
    await seed(model(id: 'b', title: 'Academia'));

    final models = await dataSource.watchAll().first;

    expect(models.map((m) => m.title), ['Academia', 'Ler']);
  });

  test('watchAll should only see the logged user collection', () async {
    await seed(model(id: 'a'));
    await seed(model(id: 'b', title: 'Outro'), 'outro');

    final models = await dataSource.watchAll().first;

    expect(models.map((m) => m.id), ['a']);
  });

  test('update should keep lastGeneratedOn', () async {
    await seed(model(lastGeneratedOn: DateTime(2026, 10, 12)));

    await dataSource.update(model(title: 'Novo'));

    final data = (await collection().doc('r1').get()).data()!;
    expect(data[RecurringTaskFields.title], 'Novo');
    expect(await storedMark(), Timestamp.fromDate(DateTime(2026, 10, 12)));
  });

  test(
    'update should throw NotFoundException when template was deleted',
    () async {
      expect(
        () => dataSource.update(model(id: 'gone')),
        throwsA(isA<NotFoundException>()),
      );
    },
  );

  test('delete then restore should recreate with the same id', () async {
    final original = model(lastGeneratedOn: DateTime(2026, 10, 12));
    await seed(original);

    await dataSource.delete('r1');
    expect((await collection().doc('r1').get()).exists, isFalse);

    await dataSource.restore(original);
    expect((await collection().doc('r1').get()).exists, isTrue);
    expect(await storedMark(), Timestamp.fromDate(DateTime(2026, 10, 12)));
  });

  test(
    'claimGeneration should return true then false on the same day',
    () async {
      await seed(model());

      expect(await claim(DateTime(2026, 10, 12, 8)), isTrue);
      expect(await storedMark(), Timestamp.fromDate(DateTime(2026, 10, 12)));
      expect(await claim(DateTime(2026, 10, 12, 20)), isFalse);
    },
  );

  test('claimGeneration should return true on the next day', () async {
    await seed(model());
    await claim(DateTime(2026, 10, 12, 8));

    expect(await claim(DateTime(2026, 10, 13)), isTrue);
    expect(await storedMark(), Timestamp.fromDate(DateTime(2026, 10, 13)));
  });

  test('claimGeneration should not write when canClaim refuses', () async {
    await seed(model(lastGeneratedOn: DateTime(2026, 10, 11)));

    final claimed = await dataSource.claimGeneration(
      'r1',
      DateTime(2026, 10, 12),
      canClaim: (_) => false,
    );

    expect(claimed, isFalse);
    expect(await storedMark(), Timestamp.fromDate(DateTime(2026, 10, 11)));
  });

  test(
    'claimGeneration should return false when template does not exist',
    () async {
      var called = false;

      final claimed = await dataSource.claimGeneration(
        'missing',
        DateTime(2026, 10, 12),
        canClaim: (_) {
          called = true;
          return true;
        },
      );

      expect(claimed, isFalse);
      expect(called, isFalse);
    },
  );

  test('moveToList should move only templates of the source list', () async {
    await seed(model(id: 'a'));
    await seed(model(id: 'b'));
    await seed(model(id: 'c', listId: 'l2'));

    await dataSource.moveToList('l1', 'l3');

    Future<String?> listOf(String id) async =>
        (await collection().doc(id).get()).data()?[RecurringTaskFields.listId]
            as String?;
    expect(await listOf('a'), 'l3');
    expect(await listOf('b'), 'l3');
    expect(await listOf('c'), 'l2');
  });

  test('deleteByList should delete only templates of the list', () async {
    await seed(model(id: 'a'));
    await seed(model(id: 'c', listId: 'l2'));

    await dataSource.deleteByList('l1');

    final ids = (await collection().get()).docs.map((d) => d.id);
    expect(ids, ['c']);
  });

  test(
    'moveToList and deleteByList should do nothing when list is empty',
    () async {
      await seed(model(id: 'a', listId: 'l2'));

      await dataSource.moveToList('l1', 'l3');
      await dataSource.deleteByList('l1');

      expect((await collection().get()).docs.map((d) => d.id), ['a']);
    },
  );
}
