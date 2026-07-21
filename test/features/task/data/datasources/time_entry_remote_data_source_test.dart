import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/firestore_paths.dart';
import 'package:meu_tempo/features/task/data/datasources/time_entry_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/time_entry_model.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockAuth auth;
  late TimeEntryRemoteDataSourceImpl dataSource;

  const uid = 'u1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = _MockAuth();
    final user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(uid);
    dataSource = TimeEntryRemoteDataSourceImpl(firestore, auth);
  });

  CollectionReference<Map<String, dynamic>> collection() =>
      firestore.collection(FirestorePaths.timeEntries(uid));

  Future<void> seed(
    String id, {
    required String targetId,
    required int minutes,
    required DateTime occurredAt,
    String listId = 'l1',
  }) =>
      collection().doc(id).set({
        'targetId': targetId,
        'targetType': TimerTargetTypeEnum.task.name,
        'listId': listId,
        'minutes': minutes,
        'origin': TimeEntryOriginEnum.manual.name,
        'occurredAt': Timestamp.fromDate(occurredAt),
      });

  group('watchByTarget', () {
    test('retorna só os registros da folha alvo', () async {
      await seed('e1', targetId: 't1', minutes: 30, occurredAt: DateTime(2026, 7, 10));
      await seed('e2', targetId: 't2', minutes: 15, occurredAt: DateTime(2026, 7, 11));

      final models = await dataSource.watchByTarget('t1').first;

      expect(models.map((m) => m.id), ['e1']);
    });

    test('ordena por occurredAt decrescente (mais recente primeiro)', () async {
      await seed('antigo', targetId: 't1', minutes: 10, occurredAt: DateTime(2026, 7, 1));
      await seed('novo', targetId: 't1', minutes: 20, occurredAt: DateTime(2026, 7, 20));
      await seed('meio', targetId: 't1', minutes: 30, occurredAt: DateTime(2026, 7, 10));

      final models = await dataSource.watchByTarget('t1').first;

      expect(models.map((m) => m.id), ['novo', 'meio', 'antigo']);
    });

    test('isola por usuário logado', () async {
      await seed('meu', targetId: 't1', minutes: 30, occurredAt: DateTime(2026, 7, 10));
      await firestore
          .collection(FirestorePaths.timeEntries('outro'))
          .doc('alheio')
          .set({
        'targetId': 't1',
        'targetType': TimerTargetTypeEnum.task.name,
        'listId': 'x',
        'minutes': 99,
        'origin': TimeEntryOriginEnum.manual.name,
        'occurredAt': Timestamp.fromDate(DateTime(2026, 7, 10)),
      });

      final models = await dataSource.watchByTarget('t1').first;

      expect(models.map((m) => m.id), ['meu']);
    });
  });

  group('update', () {
    test('sobrescreve minutos e data do registro existente', () async {
      await seed('e1', targetId: 't1', minutes: 30, occurredAt: DateTime(2026, 7, 10));

      await dataSource.update(TimeEntryModel.fromEntity(TimeEntryEntity(
        id: 'e1',
        targetId: 't1',
        targetType: TimerTargetTypeEnum.task,
        listId: 'l1',
        minutes: 55,
        origin: TimeEntryOriginEnum.manual,
        occurredAt: DateTime(2026, 7, 12),
      )));

      final doc = await collection().doc('e1').get();
      expect(doc.data()!['minutes'], 55);
    });
  });

  group('delete', () {
    test('remove o registro pelo id', () async {
      await seed('e1', targetId: 't1', minutes: 30, occurredAt: DateTime(2026, 7, 10));

      await dataSource.delete('e1');

      final doc = await collection().doc('e1').get();
      expect(doc.exists, isFalse);
    });
  });
}
