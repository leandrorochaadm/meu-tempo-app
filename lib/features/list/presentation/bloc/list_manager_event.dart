part of 'list_manager_bloc.dart';

sealed class ListManagerEvent extends Equatable {
  const ListManagerEvent();

  @override
  List<Object?> get props => const [];
}

class ListManagerStarted extends ListManagerEvent {
  const ListManagerStarted();
}

class ListManagerUpdated extends ListManagerEvent {
  const ListManagerUpdated(this.result);
  final Either<Failure, List<TaskListEntity>> result;

  @override
  List<Object?> get props => [result];
}

class ListCreated extends ListManagerEvent {
  const ListCreated(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

class ListRenamed extends ListManagerEvent {
  const ListRenamed({required this.listId, required this.name});
  final String listId;
  final String name;

  @override
  List<Object?> get props => [listId, name];
}

class ListDeleted extends ListManagerEvent {
  const ListDeleted({required this.listId, this.moveToListId});
  final String listId;
  final String? moveToListId;

  @override
  List<Object?> get props => [listId, moveToListId];
}
