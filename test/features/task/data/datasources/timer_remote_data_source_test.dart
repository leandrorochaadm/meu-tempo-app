import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/firestore_paths.dart';
import 'package:meu_tempo/features/task/data/active_timer_fields.dart';
import 'package:meu_tempo/features/task/data/datasources/timer_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/active_timer_model.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockAuth auth;
  late TimerRemoteDataSourceImpl dataSource;

  const uid = 'u1';
  final startedAt = DateTime(2026, 7, 20, 10, 30);

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = _MockAuth();
    final user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(uid);
    dataSource = TimerRemoteDataSourceImpl(firestore, auth);
  });

  DocumentReference<Map<String, dynamic>> doc() => firestore
      .collection(FirestorePaths.config(uid))
      .doc(FirestorePaths.activeTimerDoc);

  ActiveTimerModel model(TimerStatusEnum status) => ActiveTimerModel.fromEntity(
    ActiveTimerEntity(
      targetId: 't1',
      targetType: TimerTargetTypeEnum.task,
      listId: 'l1',
      startedAt: startedAt,
      status: status,
    ),
  );

  group('TimerRemoteDataSourceImpl', () {
    test('setActive grava o status e getActive lê de volta', () async {
      await dataSource.setActive(model(TimerStatusEnum.paused));

      expect(
        (await doc().get()).data()![ActiveTimerFields.status],
        TimerStatusEnum.paused.apiValue,
      );
      final read = await dataSource.getActive();
      expect(read?.toEntity().status, TimerStatusEnum.paused);
    });

    test('doc antigo sem status é lido como running', () async {
      await doc().set({
        ActiveTimerFields.targetId: 't1',
        ActiveTimerFields.startedAt: Timestamp.fromDate(startedAt),
        ActiveTimerFields.targetType: TimerTargetTypeEnum.task.name,
        ActiveTimerFields.listId: 'l1',
      });

      final read = await dataSource.getActive();

      expect(read?.toEntity().status, TimerStatusEnum.running);
    });

    test('replaceActiveIf grava quando o predicado aceita', () async {
      await dataSource.setActive(model(TimerStatusEnum.running));

      final replaced = await dataSource.replaceActiveIf(
        matches: (_) => true,
        replacement: model(TimerStatusEnum.paused),
      );

      expect(replaced, isTrue);
      expect(
        (await doc().get()).data()![ActiveTimerFields.status],
        TimerStatusEnum.paused.apiValue,
      );
    });

    test('replaceActiveIf não grava quando o predicado recusa', () async {
      await dataSource.setActive(model(TimerStatusEnum.running));

      final replaced = await dataSource.replaceActiveIf(
        matches: (_) => false,
        replacement: model(TimerStatusEnum.paused),
      );

      expect(replaced, isFalse);
      expect(
        (await doc().get()).data()![ActiveTimerFields.status],
        TimerStatusEnum.running.apiValue,
      );
    });

    test('replaceActiveIf sem doc passa null ao predicado', () async {
      var receivedNull = false;

      final replaced = await dataSource.replaceActiveIf(
        matches: (current) {
          receivedNull = current == null;
          return false;
        },
        replacement: model(TimerStatusEnum.paused),
      );

      expect(replaced, isFalse);
      expect(receivedNull, isTrue);
      expect((await doc().get()).exists, isFalse);
    });

    test('clearActiveIf apaga quando o predicado aceita', () async {
      await dataSource.setActive(model(TimerStatusEnum.running));

      final cleared = await dataSource.clearActiveIf(matches: (_) => true);

      expect(cleared, isTrue);
      expect((await doc().get()).exists, isFalse);
    });

    test('clearActiveIf não apaga quando o predicado recusa', () async {
      await dataSource.setActive(model(TimerStatusEnum.running));

      final cleared = await dataSource.clearActiveIf(matches: (_) => false);

      expect(cleared, isFalse);
      expect(
        (await doc().get()).data()![ActiveTimerFields.status],
        TimerStatusEnum.running.apiValue,
      );
    });

    test('clearActiveIf sem doc passa null ao predicado', () async {
      var receivedNull = false;

      final cleared = await dataSource.clearActiveIf(
        matches: (current) {
          receivedNull = current == null;
          return false;
        },
      );

      expect(cleared, isFalse);
      expect(receivedNull, isTrue);
    });

    test('claimActive devolve o pausado e apaga o doc', () async {
      await dataSource.setActive(model(TimerStatusEnum.paused));

      final claimed = await dataSource.claimActive();

      expect(claimed?.toEntity().status, TimerStatusEnum.paused);
      expect((await doc().get()).exists, isFalse);
    });
  });
}
