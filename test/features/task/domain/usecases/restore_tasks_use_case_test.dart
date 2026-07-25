import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/restore_tasks_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

class _FakeTask extends Fake implements TaskEntity {}

void main() {
  late _MockTaskRepo repo;
  final today = DateTime(2026, 7, 20);

  setUpAll(() => registerFallbackValue(_FakeTask()));

  setUp(() {
    repo = _MockTaskRepo();
    when(() => repo.restoreSubtree(any(), parentId: any(named: 'parentId')))
        .thenAnswer((_) async => const Right(unit));
  });

  TaskEntity node(String id, {String? parentId}) => TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        parentId: parentId,
      );

  /// Captura a chamada atômica: subárvore recriada + pai remarcado.
  /// `verify` consome as interações, então chame **uma vez** por teste.
  ({List<TaskEntity> tasks, String? parent}) captureRestore() {
    final captured = verify(() => repo.restoreSubtree(
          captureAny(),
          parentId: captureAny(named: 'parentId'),
        )).captured;
    return (
      tasks: captured[0] as List<TaskEntity>,
      parent: captured[1] as String?,
    );
  }

  test('recria a subárvore inteira numa única escrita atômica', () async {
    final removed = [
      node('filha', parentId: 'mae'),
      node('neta', parentId: 'filha'),
    ];

    await RestoreTasksUseCase(repo)(RestoreTasksParams(tasks: removed));

    expect(captureRestore().tasks.map((t) => t.id), ['filha', 'neta']);
    // Nenhuma escrita solta fora do batch.
    verifyNever(() => repo.update(any()));
  });

  test('remarca o pai externo da raiz restaurada', () async {
    final removed = [node('filha', parentId: 'mae')];

    await RestoreTasksUseCase(repo)(RestoreTasksParams(tasks: removed));

    expect(captureRestore().parent, 'mae');
  });

  test('raiz sem pai não pede remarcação de pai', () async {
    await RestoreTasksUseCase(repo)(RestoreTasksParams(tasks: [node('mae')]));

    expect(captureRestore().parent, isNull);
  });

  test('lista vazia não escreve nada e retorna sucesso', () async {
    final r = await RestoreTasksUseCase(repo)(
      const RestoreTasksParams(tasks: []),
    );

    expect(r.isRight(), isTrue);
    verifyNever(
      () => repo.restoreSubtree(any(), parentId: any(named: 'parentId')),
    );
  });

  test('usa o primeiro elemento como raiz da subárvore', () async {
    // `DeleteTaskUseCase` devolve raiz primeiro; o pai vem dela, não das netas.
    final removed = [
      node('filha', parentId: 'mae'),
      node('neta', parentId: 'filha'),
    ];

    await RestoreTasksUseCase(repo)(RestoreTasksParams(tasks: removed));

    expect(captureRestore().parent, 'mae'); // e não 'filha'
  });

  test('propaga o Failure da escrita atômica', () async {
    when(() => repo.restoreSubtree(any(), parentId: any(named: 'parentId')))
        .thenAnswer((_) async => const Left(ServerFailure()));

    final r = await RestoreTasksUseCase(repo)(
      RestoreTasksParams(tasks: [node('mae')]),
    );

    expect(r.getLeft().toNullable(), isA<ServerFailure>());
  });
}
