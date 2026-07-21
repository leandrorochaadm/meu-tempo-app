part of 'migration_bloc.dart';

sealed class MigrationEvent extends Equatable {
  const MigrationEvent();

  @override
  List<Object?> get props => const [];
}

class MigrationStarted extends MigrationEvent {
  const MigrationStarted();
}

class MigrationTasksUpdated extends MigrationEvent {
  const MigrationTasksUpdated(this.result);
  final Either<Failure, List<TaskEntity>> result;

  @override
  List<Object?> get props => [result];
}

class TaskMigrated extends MigrationEvent {
  const TaskMigrated(this.task);
  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

class TaskUnmigrated extends MigrationEvent {
  const TaskUnmigrated(this.task);
  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

class TaskDiscarded extends MigrationEvent {
  const TaskDiscarded(this.taskId);
  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Desfaz o último descarte (recria a subárvore removida).
class TaskDiscardUndone extends MigrationEvent {
  const TaskDiscardUndone();
}
