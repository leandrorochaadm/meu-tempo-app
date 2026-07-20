---
paths:
  - "lib/features/*/presentation/bloc/**"
---

# Bloc Template (`flutter_bloc`, event → state)

Arquivo: `{feature}_bloc.dart`.

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_tasks_use_case.dart';
import '../../domain/usecases/create_task_use_case.dart';
import 'task_list_event.dart';
import 'task_list_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  final GetTasksUseCase _getTasks;
  final CreateTaskUseCase _createTask;

  TaskListBloc(this._getTasks, this._createTask)
      : super(const TaskListInitial()) {
    on<TaskListStarted>(_onStarted);
    on<TaskCreated>(_onCreated);
  }

  Future<void> _onStarted(
    TaskListStarted event,
    Emitter<TaskListState> emit,
  ) async {
    emit(const TaskListLoading());
    final result = await _getTasks(const NoParams());
    result.fold(
      (failure) => emit(TaskListError(_mapFailure(failure))),
      (tasks) => emit(tasks.isEmpty
          ? const TaskListEmpty()
          : TaskListLoaded(tasks)),
    );
  }

  Future<void> _onCreated(
    TaskCreated event,
    Emitter<TaskListState> emit,
  ) async {
    final result = await _createTask(CreateTaskParams(title: event.title));
    await result.fold(
      (failure) async => emit(TaskListError(_mapFailure(failure))),
      (_) async => add(const TaskListStarted()), // recarrega
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
        // failures de feature primeiro (dados -> mensagem)
        DayOverbookedFailure(:final plannedMinutes, :final availableMinutes) =>
          'Planejou $plannedMinutes min; cabem $availableMinutes min no dia.',
        // infra — todos explícitos, fallback por último
        NetworkFailure()          => AppMessages.network,
        PermissionDeniedFailure() => AppMessages.permission,
        UnauthenticatedFailure()  => AppMessages.unauthenticated,
        NotFoundFailure()         => AppMessages.notFound,
        _                         => AppMessages.unknown,
      };
}
```

## Provisionamento (na entrada da feature)

```dart
BlocProvider(
  create: (_) => sl<TaskListBloc>()..add(const TaskListStarted()),
  child: const TaskListPage(),
);
```

## Rules
- Recebe **UseCases** por construtor (nunca Repository/DataSource).
- `on<Event>` para cada evento; nenhuma regra de negócio aqui.
- `_mapFailure` com `switch` exaustivo (feature primeiro, infra depois, `_` por último).
- Disparar evento inicial no `create` do provider (`..add`), não no `build`.
- Streams/timers: cancelar no `close()` (ver `bloc.md`).
