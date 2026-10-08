import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/build_task_tree_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/complete_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_prioritized_leaves_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

void main() {
  late _MockTaskRepo repo;
  final today = DateTime(2026, 7, 20);

  setUp(() {
    repo = _MockTaskRepo();
    when(
      () => repo.setDone(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  TaskEntity t(
    String id, {
    String? parentId,
    bool done = false,
    bool hasChildren = false,
    int? estimatedMinutes,
  }) => TaskEntity(
    id: id,
    title: id,
    listId: 'inbox',
    createdAt: today,
    parentId: parentId,
    isDone: done,
    hasChildren: hasChildren,
    estimatedMinutes: estimatedMinutes,
  );

  test('concluir a última folha conclui a mãe automaticamente', () async {
    when(() => repo.getTasks()).thenAnswer(
      (_) async => Right([
        t('mae', hasChildren: true),
        t('f1', parentId: 'mae', done: true),
        t('f2', parentId: 'mae'), // vai ser concluída agora
      ]),
    );

    await CompleteTaskUseCase(repo)(
      const CompleteTaskParams(taskId: 'f2', done: true),
    );

    verify(() => repo.setDone('f2', true)).called(1);
    verify(() => repo.setDone('mae', true)).called(1);
  });

  test('reabrir uma folha reabre a mãe concluída', () async {
    when(() => repo.getTasks()).thenAnswer(
      (_) async => Right([
        t('mae', done: true, hasChildren: true),
        t('f1', parentId: 'mae', done: true),
      ]),
    );

    await CompleteTaskUseCase(repo)(
      const CompleteTaskParams(taskId: 'f1', done: false),
    );

    verify(() => repo.setDone('f1', false)).called(1);
    verify(() => repo.setDone('mae', false)).called(1);
  });

  test('não regrava quem já está no estado desejado', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([t('solo')]));

    await CompleteTaskUseCase(repo)(
      const CompleteTaskParams(taskId: 'solo', done: false),
    );

    verifyNever(() => repo.setDone(any(), any()));
  });

  test('reabrir a neta reabre a mãe e a avó que concluíram sozinhas', () async {
    when(() => repo.getTasks()).thenAnswer(
      (_) async => Right([
        t('avo', done: true, hasChildren: true),
        t('mae', parentId: 'avo', done: true, hasChildren: true),
        t('neta', parentId: 'mae', done: true),
      ]),
    );

    final result = await CompleteTaskUseCase(repo)(
      const CompleteTaskParams(taskId: 'neta', done: false),
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repo.setDone('neta', false)).called(1);
    verify(() => repo.setDone('mae', false)).called(1);
    verify(() => repo.setDone('avo', false)).called(1);
  });

  test('reabrir a neta não regrava a avó que já estava aberta', () async {
    when(() => repo.getTasks()).thenAnswer(
      (_) async => Right([
        t('avo', hasChildren: true),
        t('mae', parentId: 'avo', done: true, hasChildren: true),
        t('neta', parentId: 'mae', done: true),
        t('tia', parentId: 'avo'),
      ]),
    );

    await CompleteTaskUseCase(repo)(
      const CompleteTaskParams(taskId: 'neta', done: false),
    );

    verify(() => repo.setDone('neta', false)).called(1);
    verify(() => repo.setDone('mae', false)).called(1);
    verifyNever(() => repo.setDone('avo', any()));
  });

  test(
    'reabrir uma neta reabre a avó e só a mãe dela; o ramo irmão não é regravado',
    () async {
      when(() => repo.getTasks()).thenAnswer(
        (_) async => Right([
          t('avo', done: true, hasChildren: true),
          t('mae1', parentId: 'avo', done: true, hasChildren: true),
          t('n1', parentId: 'mae1', done: true),
          t('mae2', parentId: 'avo', done: true, hasChildren: true),
          t('n2', parentId: 'mae2', done: true),
        ]),
      );

      await CompleteTaskUseCase(repo)(
        const CompleteTaskParams(taskId: 'n1', done: false),
      );

      verify(() => repo.setDone('n1', false)).called(1);
      verify(() => repo.setDone('mae1', false)).called(1);
      verify(() => repo.setDone('avo', false)).called(1);
      verifyNever(() => repo.setDone('mae2', any()));
      verifyNever(() => repo.setDone('n2', any()));
    },
  );

  test('repassa o Failure do getTasks sem gravar', () async {
    when(
      () => repo.getTasks(),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await CompleteTaskUseCase(repo)(
      const CompleteTaskParams(taskId: 'f1', done: false),
    );

    expect(result, const Left<Failure, Unit>(NetworkFailure()));
    verifyNever(() => repo.setDone(any(), any()));
  });

  test(
    'folha reaberta volta à fila de prioridade e a barra da mãe cai',
    () async {
      final store = <String, TaskEntity>{
        'mae': t('mae', done: true, hasChildren: true),
        'f1': t('f1', parentId: 'mae', done: true, estimatedMinutes: 30),
        'f2': t('f2', parentId: 'mae', done: true, estimatedMinutes: 30),
      };
      when(
        () => repo.getTasks(),
      ).thenAnswer((_) async => Right(store.values.toList()));
      when(() => repo.setDone(any(), any())).thenAnswer((inv) async {
        final id = inv.positionalArguments[0] as String;
        final done = inv.positionalArguments[1] as bool;
        final old = store[id]!;
        store[id] = TaskEntity(
          id: old.id,
          title: old.title,
          listId: old.listId,
          createdAt: old.createdAt,
          parentId: old.parentId,
          estimatedMinutes: old.estimatedMinutes,
          dueDate: old.dueDate,
          importance: old.importance,
          isDone: done,
          hasChildren: old.hasChildren,
          spentMinutes: old.spentMinutes,
        );
        return const Right(unit);
      });
      const prioritized = GetPrioritizedLeavesUseCase();
      expect(prioritized(store.values.toList(), today), isEmpty);

      await CompleteTaskUseCase(repo)(
        const CompleteTaskParams(taskId: 'f2', done: false),
      );

      final tasks = store.values.toList();
      expect(store['mae']!.isDone, isFalse);
      expect(prioritized(tasks, today).map((l) => l.task.id), ['f2']);
      final root = const BuildTaskTreeUseCase(prioritized)(tasks, today).single;
      expect(root.progress, 0.5); // antes: 2/2 = 1.0
    },
  );
}
