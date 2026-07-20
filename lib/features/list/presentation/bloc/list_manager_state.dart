part of 'list_manager_bloc.dart';

sealed class ListManagerState extends Equatable {
  const ListManagerState();

  @override
  List<Object?> get props => const [];
}

class ListManagerLoading extends ListManagerState {
  const ListManagerLoading();
}

class ListManagerLoaded extends ListManagerState {
  const ListManagerLoaded(this.lists);
  final List<TaskListEntity> lists;

  @override
  List<Object?> get props => [lists];
}

class ListManagerError extends ListManagerState {
  const ListManagerError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
