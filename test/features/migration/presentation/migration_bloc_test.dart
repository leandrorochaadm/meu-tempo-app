import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart' show ServerFailure;
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/migration/domain/usecases/get_pending_migrations_use_case.dart';
import 'package:meu_tempo/features/migration/domain/usecases/migrate_task_use_case.dart';
import 'package:meu_tempo/features/migration/presentation/bloc/migration_bloc.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/delete_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/edit_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchTasks extends Mock implements WatchTasksUseCase {}

class _MockMigrate extends Mock implements MigrateTaskUseCase {}

class _MockDelete extends Mock implements DeleteTaskUseCase {}

class _MockEdit extends Mock implements EditTaskUseCase {}

class _FakeNoParams extends Fake implements NoParams {}

class _FakeMigrateParams extends Fake implements MigrateTaskParams {}

class _FakeDeleteParams extends Fake implements DeleteTaskParams {}

class _FakeEditParams extends Fake implements EditTaskParams {}

void main() {
  late _MockWatchTasks watchTasks;
  late _MockMigrate migrate;
  late _MockDelete deleteTask;
  late _MockEdit editTask;
  const getPending = GetPendingMigrationsUseCase();

  final overdue = TaskEntity(
    id: 't1',
    title: 'atrasada',
    listId: 'inbox',
    createdAt: DateTime(2026, 7, 10),
    dueDate: DateTime(2000), // bem no passado → sempre pendente
  );

  setUpAll(() {
    registerFallbackValue(_FakeNoParams());
    registerFallbackValue(_FakeMigrateParams());
    registerFallbackValue(_FakeDeleteParams());
    registerFallbackValue(_FakeEditParams());
  });

  setUp(() {
    watchTasks = _MockWatchTasks();
    migrate = _MockMigrate();
    deleteTask = _MockDelete();
    editTask = _MockEdit();
  });

  MigrationBloc build() =>
      MigrationBloc(watchTasks, getPending, migrate, deleteTask, editTask);

  blocTest<MigrationBloc, MigrationState>(
    'started emite Loaded com as pendências',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(Right([overdue])));
      return build();
    },
    act: (bloc) => bloc.add(const MigrationStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const MigrationLoading(),
      isA<MigrationLoaded>().having((s) => s.pending.length, 'qtde', 1),
    ],
  );

  blocTest<MigrationBloc, MigrationState>(
    'stream com erro emite MigrationError',
    build: () {
      when(() => watchTasks(any())).thenAnswer(
        (_) => Stream.value(const Left(ServerFailure())),
      );
      return build();
    },
    act: (bloc) => bloc.add(const MigrationStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [const MigrationLoading(), const MigrationError()],
  );

  blocTest<MigrationBloc, MigrationState>(
    'TaskMigrated delega ao MigrateTaskUseCase',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(Right([overdue])));
      when(() => migrate(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      bloc.add(const MigrationStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(TaskMigrated(overdue));
    },
    verify: (_) {
      final p = verify(() => migrate(captureAny())).captured.single
          as MigrateTaskParams;
      expect(p.task.id, 't1');
    },
  );

  blocTest<MigrationBloc, MigrationState>(
    'TaskUnmigrated restaura o prazo via EditTaskUseCase',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(Right([overdue])));
      when(() => editTask(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      bloc.add(const MigrationStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(TaskUnmigrated(overdue));
    },
    verify: (_) {
      final p = verify(() => editTask(captureAny())).captured.single
          as EditTaskParams;
      expect(p.taskId, 't1');
      expect(p.dueDate, overdue.dueDate);
    },
  );

  blocTest<MigrationBloc, MigrationState>(
    'TaskDiscarded delega ao DeleteTaskUseCase',
    build: () {
      when(() => watchTasks(any()))
          .thenAnswer((_) => Stream.value(Right([overdue])));
      when(() => deleteTask(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      bloc.add(const MigrationStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const TaskDiscarded('t1'));
    },
    verify: (_) {
      final p = verify(() => deleteTask(captureAny())).captured.single
          as DeleteTaskParams;
      expect(p.taskId, 't1');
    },
  );
}
