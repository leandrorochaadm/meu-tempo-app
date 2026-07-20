part of 'migration_bloc.dart';

sealed class MigrationState extends Equatable {
  const MigrationState();

  @override
  List<Object?> get props => const [];
}

class MigrationLoading extends MigrationState {
  const MigrationLoading();
}

class MigrationLoaded extends MigrationState {
  const MigrationLoaded(this.pending);
  final List<TaskEntity> pending;

  @override
  List<Object?> get props => [pending];
}

class MigrationError extends MigrationState {
  const MigrationError();
}
