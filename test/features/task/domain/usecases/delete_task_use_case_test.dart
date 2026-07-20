import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/delete_task_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

void main() {
  late _MockTaskRepo repo;
  final today = DateTime(2026, 7, 20);

  setUp(() {
    repo = _MockTaskRepo();
    when(() => repo.delete(any())).thenAnswer((_) async => const Right(unit));
    when(() => repo.setHasChildren(any(), any()))
        .thenAnswer((_) async => const Right(unit));
  });

  TaskEntity t(String id, {String? parentId, bool hasChildren = false}) =>
      TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        parentId: parentId,
        hasChildren: hasChildren,
      );

  test('exclui a tarefa e todos os descendentes (cascata)', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('mae', hasChildren: true),
          t('filha', parentId: 'mae', hasChildren: true),
          t('neta', parentId: 'filha'),
          t('outra'),
        ]));

    await DeleteTaskUseCase(repo)(const DeleteTaskParams(taskId: 'mae'));

    verify(() => repo.delete('mae')).called(1);
    verify(() => repo.delete('filha')).called(1);
    verify(() => repo.delete('neta')).called(1);
    verifyNever(() => repo.delete('outra'));
  });

  test('atualiza hasChildren do pai quando ele fica sem filhas', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('mae', hasChildren: true),
          t('unica', parentId: 'mae'),
        ]));

    await DeleteTaskUseCase(repo)(const DeleteTaskParams(taskId: 'unica'));

    verify(() => repo.delete('unica')).called(1);
    verify(() => repo.setHasChildren('mae', false)).called(1);
  });
}
