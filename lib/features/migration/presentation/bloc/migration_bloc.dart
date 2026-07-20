import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/usecases/delete_task_use_case.dart';
import '../../../task/domain/usecases/edit_task_use_case.dart';
import '../../../task/domain/usecases/watch_tasks_use_case.dart';
import '../../domain/usecases/get_pending_migrations_use_case.dart';
import '../../domain/usecases/migrate_task_use_case.dart';

part 'migration_event.dart';
part 'migration_state.dart';

/// Migração de pendências: folhas não concluídas de dias anteriores, decididas
/// uma a uma (migrar → hoje, ou descartar).
@injectable
class MigrationBloc extends Bloc<MigrationEvent, MigrationState> {
  MigrationBloc(
    this._watchTasks,
    this._getPending,
    this._migrateTask,
    this._deleteTask,
    this._editTask,
  ) : super(const MigrationLoading()) {
    on<MigrationStarted>(_onStarted);
    on<MigrationTasksUpdated>(_onUpdated);
    on<TaskMigrated>(_onMigrated);
    on<TaskUnmigrated>(_onUnmigrated);
    on<TaskDiscarded>(_onDiscarded);
  }

  final WatchTasksUseCase _watchTasks;
  final GetPendingMigrationsUseCase _getPending;
  final MigrateTaskUseCase _migrateTask;
  final DeleteTaskUseCase _deleteTask;
  final EditTaskUseCase _editTask;

  StreamSubscription<Either<Failure, List<TaskEntity>>>? _sub;
  late DateTime _today;

  Future<void> _onStarted(
    MigrationStarted e,
    Emitter<MigrationState> emit,
  ) async {
    emit(const MigrationLoading());
    _today = DateTime.now();
    await _sub?.cancel();
    _sub = _watchTasks(const NoParams())
        .listen((r) => add(MigrationTasksUpdated(r)));
  }

  void _onUpdated(MigrationTasksUpdated e, Emitter<MigrationState> emit) {
    e.result.match(
      (f) => emit(const MigrationError()),
      (tasks) => emit(MigrationLoaded(_getPending(tasks, _today))),
    );
  }

  Future<void> _onMigrated(
    TaskMigrated e,
    Emitter<MigrationState> emit,
  ) async {
    await _migrateTask(MigrateTaskParams(task: e.task, today: _today));
  }

  /// Desfaz a migração: devolve o prazo original (a tarefa volta às pendências).
  Future<void> _onUnmigrated(
    TaskUnmigrated e,
    Emitter<MigrationState> emit,
  ) async {
    final t = e.task;
    await _editTask(EditTaskParams(
      taskId: t.id,
      title: t.title,
      estimatedMinutes: t.estimatedMinutes,
      dueDate: t.dueDate,
      importance: t.importance,
    ));
  }

  Future<void> _onDiscarded(
    TaskDiscarded e,
    Emitter<MigrationState> emit,
  ) async {
    await _deleteTask(DeleteTaskParams(taskId: e.taskId));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
