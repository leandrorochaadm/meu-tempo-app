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
    verifyNever(() => repository.createChild(any(), parentId: any(named: 'parentId')));
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

  test('cria a filha marcando o pai numa única escrita atômica', () async {
    final child = TaskEntity(
      id: 'c1',
      title: 'Fazer telas',
      listId: 'inbox',
      createdAt: today,
      parentId: 'p1',
    );
    when(() => repository.createChild(any(), parentId: any(named: 'parentId')))
        .thenAnswer((_) async => Right(child));

    final result = await useCase(params(0));

    expect(result.getRight().toNullable(), child);
    verify(() => repository.createChild(any(), parentId: 'p1')).called(1);
    // Nenhuma escrita solta: o pai é marcado dentro do mesmo batch.
    verifyNever(() => repository.create(any()));
  });

  test('título vazio não escreve nada', () async {
    await useCase(
      AddSubtaskParams(
        parentId: 'p1',
        parentLevel: 0,
        listId: 'inbox',
        title: '',
        today: today,
      ),
    );

    verifyNever(
      () => repository.createChild(any(), parentId: any(named: 'parentId')),
    );
  });

  test('a filha nasce com parentId, listId e prazo de hoje', () async {
    late TaskEntity captured;
    when(() => repository.createChild(any(), parentId: any(named: 'parentId')))
        .thenAnswer((invocation) async {
      captured = invocation.positionalArguments.first as TaskEntity;
      return Right(captured);
    });

    await useCase(params(0));

    expect(captured.parentId, 'p1');
    expect(captured.listId, 'inbox');
    expect(captured.dueDate, today);
    expect(captured.title, 'Fazer telas');
    expect(captured.id, isEmpty); // id é gerado na camada data
  });

  test('propaga o Failure do repositório sem inventar sucesso', () async {
    when(() => repository.createChild(any(), parentId: any(named: 'parentId')))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(params(0));

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
  });

  test('aceita filha de mãe (nível 0) e de filha (nível 1)', () async {
    final child = TaskEntity(
      id: 'c1',
      title: 'Fazer telas',
      listId: 'inbox',
      createdAt: today,
      parentId: 'p1',
    );
    when(() => repository.createChild(any(), parentId: any(named: 'parentId')))
        .thenAnswer((_) async => Right(child));

    expect((await useCase(params(0))).isRight(), isTrue);
    expect((await useCase(params(1))).isRight(), isTrue);
  });
}
