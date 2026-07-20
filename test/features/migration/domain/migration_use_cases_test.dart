import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/features/migration/domain/usecases/get_pending_migrations_use_case.dart';
import 'package:meu_tempo/features/migration/domain/usecases/migrate_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

class _FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  final today = DateTime(2026, 7, 20);

  setUpAll(() => registerFallbackValue(_FakeTaskEntity()));

  TaskEntity leaf(
    String id, {
    required DateTime due,
    bool done = false,
    bool hasChildren = false,
  }) =>
      TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        dueDate: due,
        isDone: done,
        hasChildren: hasChildren,
      );

  group('GetPendingMigrationsUseCase', () {
    const useCase = GetPendingMigrationsUseCase();

    test('inclui folhas não concluídas vencidas antes de hoje', () {
      final result = useCase([
        leaf('ontem', due: today.subtract(const Duration(days: 1))),
        leaf('hoje', due: today),
        leaf('feita', due: today.subtract(const Duration(days: 2)), done: true),
        leaf('mae',
            due: today.subtract(const Duration(days: 1)), hasChildren: true),
      ], today);

      expect(result.map((t) => t.id), ['ontem']);
    });
  });

  group('MigrateTaskUseCase', () {
    late _MockTaskRepo repo;
    setUp(() => repo = _MockTaskRepo());

    test('leva o prazo para hoje e persiste', () async {
      when(() => repo.update(any())).thenAnswer((_) async => const Right(unit));
      final task = leaf('t1', due: today.subtract(const Duration(days: 3)));

      await MigrateTaskUseCase(repo)(
        MigrateTaskParams(task: task, today: today),
      );

      final captured =
          verify(() => repo.update(captureAny())).captured.single as TaskEntity;
      expect(captured.dueDate, today);
      expect(captured.id, 't1');
    });
  });
}
