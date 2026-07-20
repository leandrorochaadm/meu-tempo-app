import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/list_failures.dart';
import 'package:meu_tempo/features/list/domain/repositories/task_list_repository.dart';
import 'package:meu_tempo/features/list/domain/usecases/create_list_use_case.dart';
import 'package:meu_tempo/features/list/domain/usecases/delete_list_use_case.dart';
import 'package:meu_tempo/features/list/domain/usecases/rename_list_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockListRepo extends Mock implements TaskListRepository {}

class _MockTaskRepo extends Mock implements TaskRepository {}

class _FakeListEntity extends Fake implements TaskListEntity {}

class _FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  late _MockListRepo listRepo;
  late _MockTaskRepo taskRepo;
  final today = DateTime(2026, 7, 20);

  setUpAll(() {
    registerFallbackValue(_FakeListEntity());
    registerFallbackValue(_FakeTaskEntity());
  });

  setUp(() {
    listRepo = _MockListRepo();
    taskRepo = _MockTaskRepo();
  });

  test('CreateList recusa nome vazio', () async {
    final r = await CreateListUseCase(listRepo)(
      const CreateListParams(name: '  '),
    );
    expect(r, isA<Left<Failure, TaskListEntity>>());
    verifyNever(() => listRepo.create(any()));
  });

  test('RenameList delega com nome aparado', () async {
    when(() => listRepo.rename(any(), any()))
        .thenAnswer((_) async => const Right(unit));
    await RenameListUseCase(listRepo)(
      const RenameListParams(listId: 'l1', name: '  Estudo '),
    );
    verify(() => listRepo.rename('l1', 'Estudo')).called(1);
  });

  group('DeleteList', () {
    TaskListEntity list(String id, {bool isDefault = false}) =>
        TaskListEntity(id: id, name: id, isDefault: isDefault);

    test('bloqueia excluir a lista padrão (Entrada)', () async {
      when(() => listRepo.getLists()).thenAnswer(
        (_) async => Right([list('inbox', isDefault: true)]),
      );
      final r = await DeleteListUseCase(listRepo, taskRepo)(
        const DeleteListParams(listId: 'inbox'),
      );
      r.getLeft().fold(() => fail('esperava Left'),
          (f) => expect(f, isA<CannotDeleteInboxFailure>()));
    });

    test('move as tarefas para outra lista e exclui', () async {
      when(() => listRepo.getLists())
          .thenAnswer((_) async => Right([list('a'), list('b')]));
      when(() => taskRepo.getTasks()).thenAnswer((_) async => Right([
            TaskEntity(
                id: 't1', title: 't1', listId: 'a', createdAt: today),
          ]));
      when(() => taskRepo.update(any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => listRepo.delete(any()))
          .thenAnswer((_) async => const Right(unit));

      await DeleteListUseCase(listRepo, taskRepo)(
        const DeleteListParams(listId: 'a', moveToListId: 'b'),
      );

      final moved =
          verify(() => taskRepo.update(captureAny())).captured.single
              as TaskEntity;
      expect(moved.listId, 'b');
      verify(() => listRepo.delete('a')).called(1);
    });

    test('exclui todas as tarefas quando não há destino', () async {
      when(() => listRepo.getLists())
          .thenAnswer((_) async => Right([list('a')]));
      when(() => taskRepo.getTasks()).thenAnswer((_) async => Right([
            TaskEntity(id: 't1', title: 't1', listId: 'a', createdAt: today),
          ]));
      when(() => taskRepo.delete(any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => listRepo.delete(any()))
          .thenAnswer((_) async => const Right(unit));

      await DeleteListUseCase(listRepo, taskRepo)(
        const DeleteListParams(listId: 'a'),
      );

      verify(() => taskRepo.delete('t1')).called(1);
      verify(() => listRepo.delete('a')).called(1);
    });
  });
}
