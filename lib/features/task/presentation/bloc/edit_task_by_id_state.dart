part of 'edit_task_by_id_bloc.dart';

sealed class EditTaskByIdState extends Equatable {
  const EditTaskByIdState();

  @override
  List<Object?> get props => const [];
}

class EditTaskByIdLoading extends EditTaskByIdState {
  const EditTaskByIdLoading();
}

/// Context ready: the screen opens the edit form.
class EditTaskByIdReady extends EditTaskByIdState {
  const EditTaskByIdReady(this.target);

  final TaskEditTargetEntity target;

  @override
  List<Object?> get props => [target];
}

/// The task no longer exists (deleted here or on the other phone).
class EditTaskByIdNotFound extends EditTaskByIdState {
  const EditTaskByIdNotFound();
}

class EditTaskByIdError extends EditTaskByIdState {
  const EditTaskByIdError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
