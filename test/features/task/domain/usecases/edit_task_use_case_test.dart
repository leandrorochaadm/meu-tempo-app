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
}
