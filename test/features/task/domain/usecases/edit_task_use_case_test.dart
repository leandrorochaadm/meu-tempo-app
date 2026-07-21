import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/edit_task_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

class _FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  late _MockTaskRepo repo;
  final today = DateTime(2026, 7, 20);

  setUpAll(() => registerFallbackValue(_FakeTaskEntity()));

  setUp(() {
    repo = _MockTaskRepo();
    when(() => repo.update(any())).thenAnswer((_) async => const Right(unit));
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          TaskEntity(
            id: 't1',
            title: 'Antigo',
            listId: 'inbox',
            createdAt: today,
            estimatedMinutes: 30,
            importance: ImportanceEnum.min,
          ),
        ]));
  });

  test('título vazio retorna EmptyTitleFailure', () async {
    final r = await EditTaskUseCase(repo)(
      const EditTaskParams(taskId: 't1', title: '  '),
    );
    expect(r, isA<Left<Failure, Unit>>());
    verifyNever(() => repo.update(any()));
  });

  test('atualiza os campos informados preservando os demais', () async {
    await EditTaskUseCase(repo)(
      EditTaskParams(
        taskId: 't1',
        title: 'Novo',
        estimatedMinutes: 60,
        importance: ImportanceEnum.max,
        dueDate: today,
      ),
    );

    final captured =
        verify(() => repo.update(captureAny())).captured.single as TaskEntity;
    expect(captured.title, 'Novo');
    expect(captured.estimatedMinutes, 60);
    expect(captured.importance, ImportanceEnum.max);
    expect(captured.listId, 'inbox'); // preservado
  });

  group('propagação de lista para descendentes', () {
    // Árvore: mãe (m1) → filha (f1) → neta (n1), todas em 'inbox'.
    void seedTree() {
      when(() => repo.getTasks()).thenAnswer((_) async => Right([
            TaskEntity(
              id: 'm1',
              title: 'Mãe',
              listId: 'inbox',
              createdAt: today,
              hasChildren: true,
            ),
            TaskEntity(
              id: 'f1',
              title: 'Filha',
              listId: 'inbox',
              createdAt: today,
              parentId: 'm1',
              hasChildren: true,
            ),
            TaskEntity(
              id: 'n1',
              title: 'Neta',
              listId: 'inbox',
              createdAt: today,
              parentId: 'f1',
              estimatedMinutes: 30,
              importance: ImportanceEnum.min,
            ),
          ]));
    }

    test('trocar a lista da mãe propaga para filha e neta', () async {
      seedTree();
      await EditTaskUseCase(repo)(
        const EditTaskParams(taskId: 'm1', title: 'Mãe', listId: 'work'),
      );

      final captured = verify(() => repo.update(captureAny())).captured
          .cast<TaskEntity>();
      // mãe + 2 descendentes = 3 escritas, todas na nova lista.
      expect(captured.length, 3);
      expect(captured.every((t) => t.listId == 'work'), isTrue);
      expect(captured.map((t) => t.id), containsAll(['m1', 'f1', 'n1']));
    });

    test('não propaga quando a lista não muda', () async {
      seedTree();
      await EditTaskUseCase(repo)(
        const EditTaskParams(taskId: 'm1', title: 'Mãe', listId: 'inbox'),
      );
      // Só a própria mãe é reescrita (sem varrer descendentes).
      verify(() => repo.update(any())).called(1);
    });

    test('folha nunca dispara varredura de descendentes', () async {
      seedTree();
      await EditTaskUseCase(repo)(
        const EditTaskParams(taskId: 'n1', title: 'Neta', listId: 'work'),
      );
      verify(() => repo.update(any())).called(1);
    });
  });
}
