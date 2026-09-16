import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/quick_add_target_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/add_subtask_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/create_task_and_start_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/start_timer_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateTask extends Mock implements CreateTaskUseCase {}

class _MockAddSubtask extends Mock implements AddSubtaskUseCase {}

class _MockStartTimer extends Mock implements StartTimerUseCase {}

class _FakeCreateParams extends Fake implements CreateTaskParams {}

class _FakeSubtaskParams extends Fake implements AddSubtaskParams {}

class _FakeStartParams extends Fake implements StartTimerParams {}

void main() {
  late _MockCreateTask createTask;
  late _MockAddSubtask addSubtask;
  late _MockStartTimer startTimer;
  late CreateTaskAndStartTimerUseCase useCase;

  final now = DateTime(2026, 9, 15, 9);
  final created = TaskEntity(
    id: 't1',
    title: 'Estudar',
    listId: 'inbox',
    createdAt: now,
  );

  setUpAll(() {
    registerFallbackValue(_FakeCreateParams());
    registerFallbackValue(_FakeSubtaskParams());
    registerFallbackValue(_FakeStartParams());
  });

  setUp(() {
    createTask = _MockCreateTask();
    addSubtask = _MockAddSubtask();
    startTimer = _MockStartTimer();
    useCase = CreateTaskAndStartTimerUseCase(createTask, addSubtask, startTimer);
  });

  test('sem alvo: cria tarefa raiz e inicia o cronômetro nela', () async {
    when(() => createTask(any())).thenAnswer((_) async => Right(created));
    when(() => startTimer(any())).thenAnswer((_) async => const Right(unit));

    final result = await useCase(CreateTaskAndStartTimerParams(
      title: 'Estudar',
      listId: 'inbox',
      now: now,
    ));

    expect(result.getRight().toNullable(), created);
    final p = verify(() => startTimer(captureAny())).captured.single
        as StartTimerParams;
    expect(p.targetId, 't1');
    expect(p.targetIsLeaf, isTrue); // recém-criada é sempre folha
    verifyNever(() => addSubtask(any()));
  });

  test('com alvo: cria filha herdando a lista e o nível da mãe', () async {
    when(() => addSubtask(any())).thenAnswer((_) async => Right(created));
    when(() => startTimer(any())).thenAnswer((_) async => const Right(unit));

    await useCase(CreateTaskAndStartTimerParams(
      title: 'Fazer telas',
      listId: 'ignorada',
      now: now,
      parent: const QuickAddTargetEntity(
        taskId: 'p1',
        title: 'Lançar app',
        listId: 'trabalho',
        level: 0,
      ),
    ));

    final p = verify(() => addSubtask(captureAny())).captured.single
        as AddSubtaskParams;
    expect(p.parentId, 'p1');
    expect(p.parentLevel, 0);
    expect(p.listId, 'trabalho'); // filha herda a lista da mãe
    verifyNever(() => createTask(any()));
  });

  test('título vazio: falha na criação e o cronômetro nem é chamado', () async {
    when(() => createTask(any()))
        .thenAnswer((_) async => const Left(EmptyTitleFailure()));

    final result = await useCase(CreateTaskAndStartTimerParams(
      title: '   ',
      listId: 'inbox',
      now: now,
    ));

    expect(result.getLeft().toNullable(), isA<EmptyTitleFailure>());
    verifyNever(() => startTimer(any()));
  });

  test('4º nível: devolve MaxLevelExceededFailure sem tocar no cronômetro',
      () async {
    when(() => addSubtask(any()))
        .thenAnswer((_) async => const Left(MaxLevelExceededFailure()));

    final result = await useCase(CreateTaskAndStartTimerParams(
      title: 'Bisneta',
      listId: 'inbox',
      now: now,
      parent: const QuickAddTargetEntity(
        taskId: 'n1',
        title: 'Neta',
        listId: 'inbox',
        level: 2,
      ),
    ));

    expect(result.getLeft().toNullable(), isA<MaxLevelExceededFailure>());
    verifyNever(() => startTimer(any()));
  });

  test('só o cronômetro falha: TimerNotStartedFailure com o id da criada',
      () async {
    when(() => createTask(any())).thenAnswer((_) async => Right(created));
    when(() => startTimer(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(CreateTaskAndStartTimerParams(
      title: 'Estudar',
      listId: 'inbox',
      now: now,
    ));

    expect(
      result.getLeft().toNullable(),
      const TimerNotStartedFailure('t1'),
    );
  });
}
