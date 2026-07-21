import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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
    when(() => repo.update(any())).thenAnswer((_) async => const Right(unit));
    when(() => repo.setHasChildren(any(), any()))
        .thenAnswer((_) async => const Right(unit));
  });

  TaskEntity node(String id, {String? parentId}) => TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        parentId: parentId,
      );

  test('recria cada nó e reativa hasChildren do pai externo', () async {
    final removed = [node('filha', parentId: 'mae'), node('neta', parentId: 'filha')];

    await RestoreTasksUseCase(repo)(RestoreTasksParams(tasks: removed));

    verify(() => repo.update(any())).called(2);
    verify(() => repo.setHasChildren('mae', true)).called(1);
  });

  test('raiz sem pai não chama setHasChildren', () async {
    await RestoreTasksUseCase(repo)(RestoreTasksParams(tasks: [node('mae')]));

    verify(() => repo.update(any())).called(1);
    verifyNever(() => repo.setHasChildren(any(), any()));
  });
}
