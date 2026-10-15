import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/usecases/watch_lists_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/add_recurring_task_today_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/create_recurring_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/delete_recurring_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/restore_recurring_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/update_recurring_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_recurring_tasks_use_case.dart';
import 'package:meu_tempo/features/task/presentation/bloc/recurring_task_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchRecurring extends Mock implements WatchRecurringTasksUseCase {}

class _MockWatchLists extends Mock implements WatchListsUseCase {}

class _MockCreate extends Mock implements CreateRecurringTaskUseCase {}

class _MockUpdate extends Mock implements UpdateRecurringTaskUseCase {}

class _MockDelete extends Mock implements DeleteRecurringTaskUseCase {}

class _MockRestore extends Mock implements RestoreRecurringTaskUseCase {}

class _MockAddToday extends Mock implements AddRecurringTaskTodayUseCase {}

class _FakeNoParams extends Fake implements NoParams {}

class _FakeCreateParams extends Fake implements CreateRecurringTaskParams {}

class _FakeUpdateParams extends Fake implements UpdateRecurringTaskParams {}

class _FakeDeleteParams extends Fake implements DeleteRecurringTaskParams {}

class _FakeRestoreParams extends Fake implements RestoreRecurringTaskParams {}

class _FakeAddTodayParams extends Fake implements AddRecurringTaskTodayParams {}

void main() {
  late _MockWatchRecurring watchRecurring;
  late _MockWatchLists watchLists;
  late _MockCreate create;
  late _MockUpdate update;
  late _MockDelete delete;
  late _MockRestore restore;
  late _MockAddToday addToday;

  final academia = RecurringTaskEntity(
    id: 'r1',
    title: 'Academia',
    listId: 'inbox',
    estimatedMinutes: 60,
    importance: ImportanceEnum.low,
    weekdays: {WeekdayEnum.monday},
    createdAt: DateTime(2026, 10, 1),
  );
  final reuniao = RecurringTaskEntity(
    id: 'r2',
    title: 'Reunião',
    listId: 'inbox',
    estimatedMinutes: 30,
    importance: ImportanceEnum.min,
    weekdays: {},
    createdAt: DateTime(2026, 10, 2),
  );
  const list = TaskListEntity(id: 'inbox', name: 'Entrada', isDefault: true);
  final task = TaskEntity(
    id: 't1',
    title: 'Academia',
    listId: 'inbox',
    createdAt: DateTime(2026, 10, 12),
    recurringTaskId: 'r1',
  );

  final loadedAll = RecurringTaskLoaded([academia, reuniao], const [list]);
  final loadedWithoutFirst = RecurringTaskLoaded([reuniao], const [list]);

  setUpAll(() {
    registerFallbackValue(_FakeNoParams());
    registerFallbackValue(_FakeCreateParams());
    registerFallbackValue(_FakeUpdateParams());
    registerFallbackValue(_FakeDeleteParams());
    registerFallbackValue(_FakeRestoreParams());
    registerFallbackValue(_FakeAddTodayParams());
  });

  setUp(() {
    watchRecurring = _MockWatchRecurring();
    watchLists = _MockWatchLists();
    create = _MockCreate();
    update = _MockUpdate();
    delete = _MockDelete();
    restore = _MockRestore();
    addToday = _MockAddToday();
    when(
      () => watchRecurring(any()),
    ).thenAnswer((_) => Stream.value(Right([academia, reuniao])));
    when(
      () => watchLists(any()),
    ).thenAnswer((_) => Stream.value(const Right([list])));
  });

  RecurringTaskBloc build() => RecurringTaskBloc(
    watchRecurring,
    watchLists,
    create,
    update,
    delete,
    restore,
    addToday,
  );

  Future<void> start(RecurringTaskBloc bloc) async {
    bloc.add(const RecurringTasksStarted());
    await Future<void>.delayed(Duration.zero);
  }

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'should emit Loaded with templates and lists',
    build: build,
    act: start,
    expect: () => [const RecurringTaskLoading(), loadedAll],
  );

  test('should not emit Loaded until lists arrive', () async {
    final listsController =
        StreamController<Either<Failure, List<TaskListEntity>>>();
    when(() => watchLists(any())).thenAnswer((_) => listsController.stream);
    final bloc = build();
    final states = <RecurringTaskState>[];
    final sub = bloc.stream.listen(states.add);

    await start(bloc);
    expect(states, [const RecurringTaskLoading()]);
    expect(bloc.state, const RecurringTaskLoading());

    listsController.add(const Right([list]));
    await Future<void>.delayed(Duration.zero);
    expect(states, [const RecurringTaskLoading(), loadedAll]);

    await sub.cancel();
    await listsController.close();
    await bloc.close();
  });

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'should emit Error when templates stream fails',
    build: () {
      when(
        () => watchRecurring(any()),
      ).thenAnswer((_) => Stream.value(const Left(NetworkFailure())));
      return build();
    },
    act: start,
    expect: () => [
      const RecurringTaskLoading(),
      const RecurringTaskError('Sem conexão. Verifique a internet.'),
    ],
  );

  test(
    'should keep Error when lists update after templates stream fails',
    () async {
      final listsController =
          StreamController<Either<Failure, List<TaskListEntity>>>();
      when(() => watchRecurring(any())).thenAnswer(
        (_) => Stream.fromIterable([
          Right([academia]),
          const Left(ServerFailure()),
        ]),
      );
      when(() => watchLists(any())).thenAnswer((_) => listsController.stream);
      final bloc = build();

      await start(bloc);
      listsController.add(const Right([list]));
      await Future<void>.delayed(Duration.zero);
      listsController.add(
        const Right([list, TaskListEntity(id: 'b', name: 'B')]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        bloc.state,
        const RecurringTaskError('Algo deu errado. Tente novamente.'),
      );

      await listsController.close();
      await bloc.close();
    },
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'addToday should emit AddedTodayDone then Loaded',
    build: () {
      when(() => addToday(any())).thenAnswer((_) async => Right(task));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(RecurringTaskAddedToday(academia));
    },
    expect: () => [
      const RecurringTaskLoading(),
      loadedAll,
      const RecurringTaskAddedTodayDone(1),
      loadedAll,
    ],
    verify: (_) {
      final params =
          verify(() => addToday(captureAny())).captured.single
              as AddRecurringTaskTodayParams;
      expect(params.template, academia);
      expect(params.confirmed, isFalse);
    },
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'two addToday in a row should emit two effects',
    build: () {
      when(() => addToday(any())).thenAnswer((_) async => Right(task));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(RecurringTaskAddedToday(academia));
      await Future<void>.delayed(Duration.zero);
      bloc.add(RecurringTaskAddedToday(academia));
    },
    expect: () => [
      const RecurringTaskLoading(),
      loadedAll,
      const RecurringTaskAddedTodayDone(1),
      loadedAll,
      const RecurringTaskAddedTodayDone(2),
      loadedAll,
    ],
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'should emit ConfirmRequested when instance is pending',
    build: () {
      when(
        () => addToday(any()),
      ).thenAnswer((_) async => const Left(PendingRecurringInstanceFailure()));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(RecurringTaskAddedToday(academia));
    },
    expect: () => [
      const RecurringTaskLoading(),
      loadedAll,
      RecurringTaskConfirmRequested(academia, 1),
      loadedAll,
    ],
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'confirmed addToday should pass confirmed true',
    build: () {
      when(() => addToday(any())).thenAnswer((_) async => Right(task));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(RecurringTaskAddedToday(academia, confirmed: true));
    },
    expect: () => [
      const RecurringTaskLoading(),
      loadedAll,
      const RecurringTaskAddedTodayDone(1),
      loadedAll,
    ],
    verify: (_) {
      final params =
          verify(() => addToday(captureAny())).captured.single
              as AddRecurringTaskTodayParams;
      expect(params.confirmed, isTrue);
    },
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'addToday failure should emit ActionFailed',
    build: () {
      when(
        () => addToday(any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(RecurringTaskAddedToday(academia));
    },
    expect: () => [
      const RecurringTaskLoading(),
      loadedAll,
      const RecurringTaskActionFailed('Algo deu errado. Tente novamente.', 1),
      loadedAll,
    ],
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'create should stamp now and forward fields',
    build: () {
      when(() => create(any())).thenAnswer((_) async => Right(academia));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(
        const RecurringTaskCreated(
          title: 'Ler',
          listId: 'inbox',
          estimatedMinutes: 20,
          importance: ImportanceEnum.high,
          weekdays: {WeekdayEnum.friday},
        ),
      );
    },
    expect: () => [const RecurringTaskLoading(), loadedAll],
    verify: (_) {
      final params =
          verify(() => create(captureAny())).captured.single
              as CreateRecurringTaskParams;
      expect(params.title, 'Ler');
      expect(params.listId, 'inbox');
      expect(params.estimatedMinutes, 20);
      expect(params.importance, ImportanceEnum.high);
      expect(params.weekdays, {WeekdayEnum.friday});
      expect(params.now, isNotNull);
    },
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'create failure should emit ActionFailed',
    build: () {
      when(
        () => create(any()),
      ).thenAnswer((_) async => const Left(EmptyTitleFailure()));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(
        const RecurringTaskCreated(
          title: '',
          listId: 'inbox',
          estimatedMinutes: 20,
          importance: ImportanceEnum.high,
          weekdays: {},
        ),
      );
    },
    expect: () => [
      const RecurringTaskLoading(),
      loadedAll,
      const RecurringTaskActionFailed('Digite um título para a tarefa.', 1),
      loadedAll,
    ],
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'edit should forward UpdateRecurringTaskParams',
    build: () {
      when(() => update(any())).thenAnswer((_) async => Right(academia));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(RecurringTaskEdited(_updateParams(academia)));
    },
    verify: (_) {
      verify(() => update(_updateParams(academia))).called(1);
    },
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'delete should hide item and emit DeletedDone',
    build: () {
      when(() => delete(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(RecurringTaskDeleted(academia));
    },
    expect: () => [
      const RecurringTaskLoading(),
      loadedAll,
      loadedWithoutFirst,
      RecurringTaskDeletedDone(academia, 1),
      loadedWithoutFirst,
    ],
    verify: (_) {
      verify(() => delete(const DeleteRecurringTaskParams(id: 'r1'))).called(1);
    },
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'delete failure should bring the item back and emit ActionFailed',
    build: () {
      when(
        () => delete(any()),
      ).thenAnswer((_) async => const Left(UnauthenticatedFailure()));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(RecurringTaskDeleted(academia));
    },
    expect: () => [
      const RecurringTaskLoading(),
      loadedAll,
      loadedWithoutFirst,
      const RecurringTaskActionFailed('Sua sessão expirou. Entre de novo.', 1),
      loadedAll,
    ],
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'restore should call RestoreRecurringTaskUseCase with the same template',
    build: () {
      when(() => restore(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(RecurringTaskRestored(academia));
    },
    expect: () => [const RecurringTaskLoading(), loadedAll],
    verify: (_) {
      verify(
        () => restore(RestoreRecurringTaskParams(template: academia)),
      ).called(1);
    },
  );

  blocTest<RecurringTaskBloc, RecurringTaskState>(
    'restore failure should emit ActionFailed',
    build: () {
      when(
        () => restore(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return build();
    },
    act: (bloc) async {
      await start(bloc);
      bloc.add(RecurringTaskRestored(academia));
    },
    expect: () => [
      const RecurringTaskLoading(),
      loadedAll,
      const RecurringTaskActionFailed('Sem conexão. Verifique a internet.', 1),
      loadedAll,
    ],
  );

  test('close should cancel subscriptions', () async {
    var itemsCancelled = false;
    var listsCancelled = false;
    final itemsController =
        StreamController<Either<Failure, List<RecurringTaskEntity>>>(
          onCancel: () => itemsCancelled = true,
        );
    final listsController =
        StreamController<Either<Failure, List<TaskListEntity>>>(
          onCancel: () => listsCancelled = true,
        );
    when(() => watchRecurring(any())).thenAnswer((_) => itemsController.stream);
    when(() => watchLists(any())).thenAnswer((_) => listsController.stream);
    final bloc = build();

    await start(bloc);
    await bloc.close();

    expect(itemsCancelled, isTrue);
    expect(listsCancelled, isTrue);
  });
}

UpdateRecurringTaskParams _updateParams(RecurringTaskEntity original) =>
    UpdateRecurringTaskParams(
      original: original,
      title: 'Nova',
      listId: 'inbox',
      estimatedMinutes: 45,
      importance: ImportanceEnum.high,
      weekdays: const {WeekdayEnum.tuesday},
    );
