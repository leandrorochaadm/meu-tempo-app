import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/add_subtask_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

class _FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  late _MockTaskRepository repository;
  late AddSubtaskUseCase useCase;
  final today = DateTime(2026, 7, 20);

  setUpAll(() => registerFallbackValue(_FakeTaskEntity()));

  setUp(() {
    repository = _MockTaskRepository();
    useCase = AddSubtaskUseCase(repository);
  });

  AddSubtaskParams params(int parentLevel) => AddSubtaskParams(
        parentId: 'p1',
        parentLevel: parentLevel,
        listId: 'inbox',
        title: 'Fazer telas',
        today: today,
      );

  test('bloqueia filha de neta (nível 2) com MaxLevelExceededFailure', () async {
    final result = await useCase(params(2));

    expect(result, isA<Left<Failure, TaskEntity>>());
    result.getLeft().fold(() => fail('esperava Left'),
        (f) => expect(f, isA<MaxLevelExceededFailure>()));
    verifyNever(() => repository.create(any()));
  });

  test('título vazio retorna EmptyTitleFailure', () async {
    final result = await useCase(
      AddSubtaskParams(
        parentId: 'p1',
        parentLevel: 0,
        listId: 'inbox',
        title: '   ',
        today: today,
      ),
    );
    expect(result, isA<Left<Failure, TaskEntity>>());
  });

  test('cria a filha e marca o pai como tendo filhas', () async {
    final child = TaskEntity(
      id: 'c1',
      title: 'Fazer telas',
      listId: 'inbox',
      createdAt: today,
      parentId: 'p1',
    );
    when(() => repository.create(any())).thenAnswer((_) async => Right(child));
    when(() => repository.setHasChildren(any(), any()))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(params(0));

    expect(result.getRight().toNullable(), child);
    verify(() => repository.create(any())).called(1);
    verify(() => repository.setHasChildren('p1', true)).called(1);
  });
}
