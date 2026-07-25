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
    when(() => repo.updateAll(any())).thenAnswer((_) async => const Right(unit));
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

    test('trocar a lista da mãe propaga para filha e neta num só commit',
        () async {
      seedTree();
      await EditTaskUseCase(repo)(
        const EditTaskParams(taskId: 'm1', title: 'Mãe', listId: 'work'),
      );

      final captured = verify(() => repo.updateAll(captureAny()))
          .captured
          .single as List<TaskEntity>;
      // mãe + 2 descendentes na MESMA escrita atômica, todas na nova lista.
      expect(captured.length, 3);
      expect(captured.every((t) => t.listId == 'work'), isTrue);
      expect(captured.map((t) => t.id), containsAll(['m1', 'f1', 'n1']));
      // Nada de escrita solta por descendente.
      verifyNever(() => repo.update(any()));
    });

    test('não propaga quando a lista não muda', () async {
      seedTree();
      await EditTaskUseCase(repo)(
        const EditTaskParams(taskId: 'm1', title: 'Mãe', listId: 'inbox'),
      );
      // Só a própria mãe é reescrita (sem varrer descendentes).
      verify(() => repo.update(any())).called(1);
      verifyNever(() => repo.updateAll(any()));
    });
  });

  group('a lista pertence à árvore', () {
    // Árvore: mãe (m1) em 'work' → filha (f1) → neta (n1), todas em 'work'.
    void seedTree() {
      when(() => repo.getTasks()).thenAnswer((_) async => Right([
            TaskEntity(
              id: 'm1',
              title: 'Mãe',
              listId: 'work',
              createdAt: today,
              hasChildren: true,
            ),
            TaskEntity(
              id: 'f1',
              title: 'Filha',
              listId: 'work',
              createdAt: today,
              parentId: 'm1',
              hasChildren: true,
            ),
            TaskEntity(
              id: 'n1',
              title: 'Neta',
              listId: 'work',
              createdAt: today,
              parentId: 'f1',
              estimatedMinutes: 30,
            ),
          ]));
    }

    TaskEntity written() =>
        verify(() => repo.update(captureAny())).captured.single as TaskEntity;

    test('filha ignora a lista pedida e herda a da mãe', () async {
      seedTree();

      await EditTaskUseCase(repo)(
        const EditTaskParams(taskId: 'f1', title: 'Filha', listId: 'inbox'),
      );

      expect(written().listId, 'work');
    });

    test('neta ignora a lista pedida e herda a da mãe (filha)', () async {
      seedTree();

      await EditTaskUseCase(repo)(
        const EditTaskParams(taskId: 'n1', title: 'Neta', listId: 'inbox'),
      );

      expect(written().listId, 'work');
    });

    test('folha com pai nunca dispara propagação de subárvore', () async {
      seedTree();

      await EditTaskUseCase(repo)(
        const EditTaskParams(taskId: 'n1', title: 'Neta', listId: 'inbox'),
      );

      verify(() => repo.update(any())).called(1);
      verifyNever(() => repo.updateAll(any()));
    });

    test('tarefa mãe (raiz) segue escolhendo a lista', () async {
      seedTree();

      await EditTaskUseCase(repo)(
        const EditTaskParams(taskId: 'm1', title: 'Mãe', listId: 'inbox'),
      );

      final captured = verify(() => repo.updateAll(captureAny()))
          .captured
          .single as List<TaskEntity>;
      expect(captured.every((t) => t.listId == 'inbox'), isTrue);
    });

    test('salvar filha legada divergente a realinha com a mãe', () async {
      // Dado legado: filha ficou em 'inbox' enquanto a mãe está em 'work'.
      when(() => repo.getTasks()).thenAnswer((_) async => Right([
            TaskEntity(
              id: 'm1',
              title: 'Mãe',
              listId: 'work',
              createdAt: today,
              hasChildren: true,
            ),
            TaskEntity(
              id: 'f1',
              title: 'Filha',
              listId: 'inbox',
              createdAt: today,
              parentId: 'm1',
              estimatedMinutes: 30,
            ),
          ]));

      // Sem pedir troca de lista nenhuma (`listId: null`).
      await EditTaskUseCase(repo)(
        const EditTaskParams(taskId: 'f1', title: 'Filha'),
      );

      expect(written().listId, 'work');
    });
  });
}
