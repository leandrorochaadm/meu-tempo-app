---
paths:
  - "lib/features/*/presentation/**"
---

# Presentation Layer Rules (BLoC)

Gerência de estado com **`flutter_bloc`**, no estilo **event → state** (Bloc clássico
com eventos, **não** Cubit). Três arquivos por feature: `_bloc.dart`, `_event.dart`,
`_state.dart`. Regras detalhadas de BLoC em `@.claude/rules/bloc.md`.

## States (sealed + Equatable)

- Base: `sealed class {Feature}State extends Equatable` com `props => [hashCode]`.
- Estados: `{Feature}Initial`, `{Feature}Loading`, `{Feature}Loaded` /
  `{Feature}sLoaded` (lista), `{Feature}Error` (`String message`).
- Opcionais: `{Feature}Empty`, `{Feature}Submitting`.
- Subclasses **sem campos** herdam `props` da base; **com campos** sobrescrevem.
- **NUNCA** contém `Either` — o Either morre no Bloc.

## Events (sealed + Equatable)

- Base: `sealed class {Feature}Event extends Equatable`.
- Um event por intenção do usuário: `{Feature}Started`, `{Feature}Created`,
  `{Feature}Deleted`, `TimerToggled`, etc. Verbos no passado (fato ocorrido na UI).

## Bloc

- **MUST** usar UseCases (nunca injetar Repository direto).
- Registrar handlers no construtor com `on<Event>(_handler)`.
- **MUST** ter `_mapFailure(Failure)` com `switch` exaustivo (Failure → mensagem).
- **NEVER** hardcodar mensagem de erro fora do `_mapFailure`.
- **NENHUMA** regra de negócio no Bloc — só orquestra UseCase e emite estado.

```dart
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  final GetTasksUseCase _getTasks;

  TaskListBloc(this._getTasks) : super(TaskListInitial()) {
    on<TaskListStarted>(_onStarted);
  }

  Future<void> _onStarted(TaskListStarted event, Emitter<TaskListState> emit) async {
    emit(TaskListLoading());
    final result = await _getTasks(NoParams());
    result.fold(
      (failure) => emit(TaskListError(_mapFailure(failure))),
      (tasks) => emit(tasks.isEmpty ? TaskListEmpty() : TaskListLoaded(tasks)),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
        // failures de feature (dados → mensagem)
        DayOverbookedFailure(:final plannedMinutes, :final availableMinutes) =>
          'Você planejou $plannedMinutes min, mas só cabem $availableMinutes min no dia.',
        // infra — todos explícitos
        NetworkFailure()          => AppMessages.network,
        PermissionDeniedFailure() => AppMessages.permission,
        UnauthenticatedFailure()  => AppMessages.unauthenticated,
        NotFoundFailure()         => AppMessages.notFound,
        _                         => AppMessages.unknown,
      };
}
```

## UI — `BlocBuilder` + `switch` exaustivo

- Usar `switch` do Dart 3 para todos os estados. NUNCA `if (state is ...)` em cadeia.
- `BlocBuilder` para renderizar; `BlocListener` para side-effects (snackbar, navegação);
  `BlocConsumer` quando precisa dos dois.

```dart
BlocBuilder<TaskListBloc, TaskListState>(
  builder: (context, state) => switch (state) {
    TaskListInitial()            => const SizedBox.shrink(),
    TaskListLoading()            => const AppLoadingIndicator(),
    TaskListLoaded(:final tasks) => TaskListView(tasks: tasks),
    TaskListEmpty()              => const AppEmptyState(),
    TaskListError(:final message) => AppErrorWidget(message: message),
  },
);
```

## Type Safety

- **ONLY** Entity (nunca Model, nunca `Map<String, dynamic>`).
- Construtores de Page/Widget e campos de State: apenas Entity.

## Styling

- **MUST** usar `AppColors` e `AppStyles` exclusivamente.
- **NEVER** hardcodar cor (`Color(0xFF...)`, `Colors.blue`) ou `TextStyle` inline.
- Se a cor/estilo não existe, adicionar em `AppColors`/`AppStyles` primeiro.
- Mobile-first: alvos de toque grandes, layout flexível (ver `@.claude/rules/layout.md`).

## Formatters

- Formatação (hora, duração, data) é feita **apenas na UI** — nunca na Entity, UseCase
  ou Bloc. Formatters reutilizáveis em `lib/core/formatters/`.

```dart
// CERTO
Text(DurationFormatter.format(entity.totalEstimatedMinutes)) // "1h30"
// ERRADO — formatação na Entity
class TaskEntity { String get formatted => ...; } // NÃO
```

## Templates
- State: `@.claude/rules/templates/state_template.md`
- Event: `@.claude/rules/templates/event_template.md`
- Bloc: `@.claude/rules/templates/bloc_template.md`
