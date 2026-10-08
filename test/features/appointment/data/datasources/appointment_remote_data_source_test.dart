import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/firestore_paths.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/appointment/data/appointment_fields.dart';
import 'package:meu_tempo/features/appointment/data/datasources/appointment_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockAuth auth;
  late AppointmentRemoteDataSourceImpl dataSource;

  const uid = 'u1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = _MockAuth();
    final user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(uid);
    dataSource = AppointmentRemoteDataSourceImpl(firestore, auth);
  });

  CollectionReference<Map<String, dynamic>> collection() =>
      firestore.collection(FirestorePaths.appointments(uid));

  Future<void> seed(String id, String title, DateTime date) =>
      collection().doc(id).set({
        'title': title,
        'listId': 'prof',
        'date': Timestamp.fromDate(date),
        'startMinute': 900,
        'durationMinutes': 60,
        'spentMinutes': 0,
      });

  test('watchAll emite todos os compromissos do usuário', () async {
    await seed('a1', 'Reunião A', DateTime(2026, 7, 10));
    await seed('a2', 'Reunião B', DateTime(2026, 7, 25));

    final models = await dataSource.watchAll().first;

    expect(models.map((m) => m.id), containsAll(['a1', 'a2']));
    expect(models.map((m) => m.title), containsAll(['Reunião A', 'Reunião B']));
  });

  test('watchAll só enxerga a coleção do usuário logado (isolamento)',
      () async {
    await seed('meu', 'Meu', DateTime(2026, 7, 10));
    // Compromisso de outro usuário — não deve aparecer.
    await firestore
        .collection(FirestorePaths.appointments('outro'))
        .doc('alheio')
        .set({
      'title': 'Alheio',
      'listId': 'x',
      'date': Timestamp.fromDate(DateTime(2026, 7, 10)),
      'startMinute': 600,
      'durationMinutes': 30,
      'spentMinutes': 0,
    });

    final models = await dataSource.watchAll().first;

    expect(models.map((m) => m.id), ['meu']);
  });

  test('watchAll lê compromisso sem isDone como não concluído', () async {
    await seed('a1', 'Antigo', DateTime(2026, 7, 10));

    final models = await dataSource.watchAll().first;

    expect(models.single.isDone, isFalse);
  });

  test('setDone(true) conclui o compromisso', () async {
    await seed('a1', 'Reunião', DateTime(2026, 7, 10));

    await dataSource.setDone('a1', true);

    final doc = await collection().doc('a1').get();
    expect(doc.data()![AppointmentFields.isDone], isTrue);
  });

  test('setDone(false) reabre o compromisso', () async {
    await seed('a1', 'Reunião', DateTime(2026, 7, 10));

    await dataSource.setDone('a1', true);
    await dataSource.setDone('a1', false);

    final doc = await collection().doc('a1').get();
    expect(doc.data()![AppointmentFields.isDone], isFalse);
    final models = await dataSource.watchAll().first;
    expect(models.single.isDone, isFalse);
  });

  test('setDone em compromisso inexistente lança NotFoundException', () async {
    expect(
      () => dataSource.setDone('nao-existe', true),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('setDone só grava na coleção do usuário logado', () async {
    await firestore
        .collection(FirestorePaths.appointments('outro'))
        .doc('a1')
        .set({'title': 'Alheio'});

    await expectLater(
      () => dataSource.setDone('a1', true),
      throwsA(isA<NotFoundException>()),
    );

    final doc = await firestore
        .collection(FirestorePaths.appointments('outro'))
        .doc('a1')
        .get();
    expect(doc.data()!.containsKey(AppointmentFields.isDone), isFalse);
  });
}
