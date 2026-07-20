---
paths:
  - "lib/features/*/presentation/bloc/**"
---

# State Template (sealed)

Arquivo: `{feature}_state.dart` (separado do bloc e do event).

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/task_entity.dart';

sealed class TaskListState extends Equatable {
  const TaskListState();
  @override
  List<Object?> get props => [];
}

class TaskListInitial extends TaskListState {
  const TaskListInitial();
}

class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

class TaskListLoaded extends TaskListState {
  final List<TaskEntity> tasks;
  const TaskListLoaded(this.tasks);
  @override
  List<Object?> get props => [tasks];
}

class TaskListEmpty extends TaskListState {
  const TaskListEmpty();
}

class TaskListError extends TaskListState {
  final String message;
  const TaskListError(this.message);
  @override
  List<Object?> get props => [message];
}
```

## Uso na UI (switch exaustivo)

```dart
BlocBuilder<TaskListBloc, TaskListState>(
  builder: (context, state) => switch (state) {
    TaskListInitial()             => const SizedBox.shrink(),
    TaskListLoading()             => const AppLoadingIndicator(),
    TaskListLoaded(:final tasks)  => TaskListView(tasks: tasks),
    TaskListEmpty()               => const AppEmptyState(),
    TaskListError(:final message) => AppErrorWidget(message: message),
  },
);
```

## Rules
- base `sealed` + `Equatable`; sem campos herda `props`, com campos sobrescreve.
- NUNCA contém `Either` — o Either morre no Bloc.
- Só tipos Entity nos campos (nunca Model/Map).
