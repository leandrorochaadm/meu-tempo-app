import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/complete_task_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

void main() {
  late _MockTaskRepo repo;
  final today = DateTime(2026, 7, 20);

  setUp(() {
    repo = _MockTaskRepo();
    when(() => repo.setDone(any(), any()))
        .thenAnswer((_) async => const Right(unit));
  });

  TaskEntity t(String id, {String? parentId, bool done = false, bool hasChildren = false}) =>
      TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        parentId: parentId,
        isDone: done,
        hasChildren: hasChildren,
      );

  test('concluir a última folha conclui a mãe automaticamente', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('mae', hasChildren: true),
          t('f1', parentId: 'mae', done: true),
          t('f2', parentId: 'mae'), // vai ser concluída agora
        ]));

    await CompleteTaskUseCase(repo)(
      const CompleteTaskParams(taskId: 'f2', done: true),
    );

    verify(() => repo.setDone('f2', true)).called(1);
    verify(() => repo.setDone('mae', true)).called(1);
  });

  test('reabrir uma folha reabre a mãe concluída', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('mae', done: true, hasChildren: true),
          t('f1', parentId: 'mae', done: true),
        ]));

    await CompleteTaskUseCase(repo)(
      const CompleteTaskParams(taskId: 'f1', done: false),
    );

    verify(() => repo.setDone('f1', false)).called(1);
    verify(() => repo.setDone('mae', false)).called(1);
  });

  test('não regrava quem já está no estado desejado', () async {
    when(() => repo.getTasks())
        .thenAnswer((_) async => Right([t('solo')]));

    await CompleteTaskUseCase(repo)(
      const CompleteTaskParams(taskId: 'solo', done: false),
    );

    verifyNever(() => repo.setDone(any(), any()));
  });
}
