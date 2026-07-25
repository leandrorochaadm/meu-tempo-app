import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/move_task_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

class _FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  late _MockTaskRepo repo;
  final today = DateTime(2026, 7, 20);

  setUpAll(() => registerFallbackValue(_FakeTaskEntity()));

  setUp(() {
    repo = _MockTaskRepo();
    when(() => repo.moveTask(
          any(),
          newParentId: any(named: 'newParentId'),
          emptiedParentId: any(named: 'emptiedParentId'),
        )).thenAnswer((_) async => const Right(unit));
  });

  /// Captura a chamada atômica: tarefa gravada, novo pai e pai liberado.
  /// `verify` consome as interações, então chame **uma vez** por teste.
  ({List<TaskEntity> subtree, String? newParent, String? emptiedParent})
      captureMove() {
    final captured = verify(() => repo.moveTask(
          captureAny(),
          newParentId: captureAny(named: 'newParentId'),
          emptiedParentId: captureAny(named: 'emptiedParentId'),
        )).captured;
    return (
      subtree: captured[0] as List<TaskEntity>,
      newParent: captured[1] as String?,
      emptiedParent: captured[2] as String?,
    );
  }

  TaskEntity t(
    String id, {
    String? parentId,
    bool hasChildren = false,
    String listId = 'inbox',
  }) =>
      TaskEntity(
        id: id,
        title: id,
        listId: listId,
        createdAt: today,
        parentId: parentId,
        hasChildren: hasChildren,
      );

  test('recusa mover para si mesmo', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([t('a')]));
    final r = await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'a', newParentId: 'a'),
    );
    expect(r, isA<Left<Failure, Unit>>());
  });

  test('recusa mover para um descendente (ciclo)', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('mae', hasChildren: true),
          t('filha', parentId: 'mae'),
        ]));
    final r = await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'mae', newParentId: 'filha'),
    );
    r.getLeft().fold(() => fail('esperava Left'),
        (f) => expect(f, isA<InvalidMoveFailure>()));
  });

  test('recusa quando resultado excede 3 níveis', () async {
    // mover "mae" (que tem filha e neta → altura 2) para dentro de outra mãe.
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('outra'),
          t('mae', hasChildren: true),
          t('filha', parentId: 'mae', hasChildren: true),
          t('neta', parentId: 'filha'),
        ]));
    final r = await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'mae', newParentId: 'outra'),
    );
    r.getLeft().fold(() => fail('esperava Left'),
        (f) => expect(f, isA<MaxLevelExceededFailure>()));
  });

  test('move válido grava tarefa e os dois pais numa escrita atômica',
      () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('destino'),
          t('mae', hasChildren: true),
          t('filha', parentId: 'mae'),
        ]));

    final r = await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'filha', newParentId: 'destino'),
    );

    expect(r.isRight(), isTrue);
    verify(() => repo.moveTask(
          any(),
          newParentId: any(named: 'newParentId'),
          emptiedParentId: any(named: 'emptiedParentId'),
        )).called(1);
    // Nenhuma escrita solta fora do batch.
    verifyNever(() => repo.update(any()));
  });

  test('informa o novo pai e libera o antigo que ficou vazio', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('destino'),
          t('mae', hasChildren: true),
          t('filha', parentId: 'mae'),
        ]));

    await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'filha', newParentId: 'destino'),
    );

    final call = captureMove();
    expect(call.newParent, 'destino');
    expect(call.emptiedParent, 'mae');
  });

  test('não libera o pai antigo quando ainda restam outras filhas', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('destino'),
          t('mae', hasChildren: true),
          t('f1', parentId: 'mae'),
          t('f2', parentId: 'mae'),
        ]));

    await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'f1', newParentId: 'destino'),
    );

    expect(captureMove().emptiedParent, isNull);
  });

  test('mover para raiz (newParentId null) libera o pai antigo', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('mae', hasChildren: true),
          t('filha', parentId: 'mae'),
        ]));

    final r = await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'filha'),
    );

    expect(r.isRight(), isTrue);
    final call = captureMove();
    expect(call.newParent, isNull);
    expect(call.emptiedParent, 'mae');
    expect(call.subtree.single.parentId, isNull);
  });

  test('mover uma raiz para dentro de outra não libera pai nenhum', () async {
    when(() => repo.getTasks())
        .thenAnswer((_) async => Right([t('destino'), t('solta')]));

    await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'solta', newParentId: 'destino'),
    );

    final call = captureMove();
    expect(call.newParent, 'destino');
    expect(call.emptiedParent, isNull);
  });

  test('preserva os campos da tarefa ao mover (só o parentId muda)', () async {
    final filha = TaskEntity(
      id: 'filha',
      title: 'Fazer telas',
      listId: 'inbox',
      createdAt: today,
      parentId: 'mae',
      estimatedMinutes: 45,
      dueDate: today,
      spentMinutes: 20,
      isDone: true,
    );
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('destino'),
          t('mae', hasChildren: true),
          filha,
        ]));

    await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'filha', newParentId: 'destino'),
    );

    final moved = captureMove().subtree.first;
    expect(moved.parentId, 'destino');
    expect(moved.title, 'Fazer telas');
    expect(moved.estimatedMinutes, 45);
    expect(moved.spentMinutes, 20);
    expect(moved.isDone, isTrue);
  });

  test('tarefa inexistente retorna TaskNotFoundFailure sem escrever', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([t('a')]));

    final r = await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'sumiu', newParentId: 'a'),
    );

    r.getLeft().fold(() => fail('esperava Left'),
        (f) => expect(f, isA<TaskNotFoundFailure>()));
    verifyNever(() => repo.moveTask(
          any(),
          newParentId: any(named: 'newParentId'),
          emptiedParentId: any(named: 'emptiedParentId'),
        ));
  });

  test('novo pai inexistente retorna TaskNotFoundFailure', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([t('a')]));

    final r = await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'a', newParentId: 'fantasma'),
    );

    r.getLeft().fold(() => fail('esperava Left'),
        (f) => expect(f, isA<TaskNotFoundFailure>()));
  });

  test('propaga o Failure da escrita atômica', () async {
    when(() => repo.getTasks())
        .thenAnswer((_) async => Right([t('destino'), t('solta')]));
    when(() => repo.moveTask(
          any(),
          newParentId: any(named: 'newParentId'),
          emptiedParentId: any(named: 'emptiedParentId'),
        )).thenAnswer((_) async => const Left(NetworkFailure()));

    final r = await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'solta', newParentId: 'destino'),
    );

    expect(r.getLeft().toNullable(), isA<NetworkFailure>());
  });

  group('a lista pertence à árvore', () {
    test('a tarefa movida herda a lista da nova mãe', () async {
      when(() => repo.getTasks()).thenAnswer((_) async => Right([
            t('destino', listId: 'work'),
            t('solta', listId: 'inbox'),
          ]));

      await MoveTaskUseCase(repo)(
        const MoveTaskParams(taskId: 'solta', newParentId: 'destino'),
      );

      expect(captureMove().subtree.single.listId, 'work');
    });

    test('os descendentes acompanham a lista da nova mãe', () async {
      when(() => repo.getTasks()).thenAnswer((_) async => Right([
            t('destino', listId: 'work'),
            t('mae', hasChildren: true, listId: 'inbox'),
            t('filha', parentId: 'mae', hasChildren: true, listId: 'inbox'),
            t('neta', parentId: 'filha', listId: 'inbox'),
          ]));

      await MoveTaskUseCase(repo)(
        const MoveTaskParams(taskId: 'filha', newParentId: 'destino'),
      );

      final subtree = captureMove().subtree;
      expect(subtree.map((t) => t.id), containsAll(['filha', 'neta']));
      expect(subtree.every((t) => t.listId == 'work'), isTrue);
    });

    test('a subárvore inteira vai no mesmo commit', () async {
      when(() => repo.getTasks()).thenAnswer((_) async => Right([
            t('destino', listId: 'work'),
            t('mae', hasChildren: true, listId: 'inbox'),
            t('filha', parentId: 'mae', listId: 'inbox'),
          ]));

      await MoveTaskUseCase(repo)(
        const MoveTaskParams(taskId: 'mae', newParentId: 'destino'),
      );

      verify(() => repo.moveTask(
            any(),
            newParentId: any(named: 'newParentId'),
            emptiedParentId: any(named: 'emptiedParentId'),
          )).called(1);
      verifyNever(() => repo.updateAll(any()));
      verifyNever(() => repo.update(any()));
    });

    test('mover dentro da mesma lista não reescreve os descendentes', () async {
      when(() => repo.getTasks()).thenAnswer((_) async => Right([
            t('destino', listId: 'inbox'),
            t('mae', hasChildren: true, listId: 'inbox'),
            t('filha', parentId: 'mae', listId: 'inbox'),
          ]));

      await MoveTaskUseCase(repo)(
        const MoveTaskParams(taskId: 'mae', newParentId: 'destino'),
      );

      // Só a própria tarefa — a lista não mudou, nada a propagar.
      expect(captureMove().subtree.map((t) => t.id), ['mae']);
    });

    test('mover para raiz mantém a lista atual da tarefa', () async {
      when(() => repo.getTasks()).thenAnswer((_) async => Right([
            t('mae', hasChildren: true, listId: 'work'),
            t('filha', parentId: 'mae', listId: 'work'),
          ]));

      await MoveTaskUseCase(repo)(const MoveTaskParams(taskId: 'filha'));

      expect(captureMove().subtree.single.listId, 'work');
    });
  });
}
