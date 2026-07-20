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
    when(() => repo.update(any())).thenAnswer((_) async => const Right(unit));
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

  test('move válido reatribui pai e ajusta hasChildren', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('destino'),
          t('mae', hasChildren: true),
          t('filha', parentId: 'mae'),
        ]));

    final r = await MoveTaskUseCase(repo)(
      const MoveTaskParams(taskId: 'filha', newParentId: 'destino'),
    );

    expect(r.isRight(), isTrue);
    verify(() => repo.update(any())).called(1);
    verify(() => repo.setHasChildren('destino', true)).called(1);
    verify(() => repo.setHasChildren('mae', false)).called(1);
  });
}
