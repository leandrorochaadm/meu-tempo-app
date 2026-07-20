import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/constants/app_defaults.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

class _FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  late _MockTaskRepository repository;
  late CreateTaskUseCase useCase;
  final today = DateTime(2026, 7, 20);

  setUpAll(() => registerFallbackValue(_FakeTaskEntity()));

  setUp(() {
    repository = _MockTaskRepository();
    useCase = CreateTaskUseCase(repository);
  });

  test('retorna EmptyTitleFailure quando o título é vazio', () async {
    final result = await useCase(
      CreateTaskParams(title: '   ', listId: 'inbox', today: today),
    );

    expect(result, isA<Left<Failure, TaskEntity>>());
    result.getLeft().fold(() => fail('esperava Left'),
        (f) => expect(f, isA<EmptyTitleFailure>()));
    verifyNever(() => repository.create(any()));
  });

  test('aplica os defaults da criação rápida quando só o título é informado',
      () async {
    when(() => repository.create(any())).thenAnswer(
      (inv) async => Right(inv.positionalArguments.first as TaskEntity),
    );

    await useCase(
      CreateTaskParams(title: 'Estudar', listId: 'inbox', today: today),
    );

    final captured =
        verify(() => repository.create(captureAny())).captured.single
            as TaskEntity;
    expect(captured.title, 'Estudar');
    expect(captured.estimatedMinutes, AppDefaults.defaultEstimatedMinutes);
    expect(captured.importance, ImportanceEnum.min);
    expect(captured.dueDate, today);
    expect(captured.listId, 'inbox');
  });

  test('propaga Right do repositório no sucesso', () async {
    final task = TaskEntity(
      id: 't1',
      title: 'Estudar',
      listId: 'inbox',
      createdAt: today,
    );
    when(() => repository.create(any())).thenAnswer((_) async => Right(task));

    final result = await useCase(
      CreateTaskParams(title: 'Estudar', listId: 'inbox', today: today),
    );

    expect(result.getRight().toNullable(), task);
  });
}
