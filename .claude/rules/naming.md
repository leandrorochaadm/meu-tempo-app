---
paths:
  - "lib/**"
---

# Naming Conventions

## Regra fundamental

**Todo código — classes, variáveis, métodos, arquivos e constantes — em inglês.**
Comentários e documentação em português. Termos de domínio exibidos na UI ficam em
português (`Tarefa`, `Lista`, `Compromisso`), mas o **código** que os representa é em
inglês (`TaskEntity`, `ListEntity`, `AppointmentEntity`).

> Convenção de nomes de domínio (código → UI):
> `Task` → "Tarefa", `TaskList` → "Lista", `Appointment` → "Compromisso",
> `TimeEntry` → "Registro de tempo", `Timer` → "Cronômetro".

## Arquivos (snake_case)

| Tipo | Padrão | Exemplo |
|---|---|---|
| Entity | `{entity}_entity.dart` | `task_entity.dart` |
| Model | `{entity}_model.dart` | `task_model.dart` |
| Repository (contrato) | `{entity}_repository.dart` | `task_repository.dart` |
| Repository (impl) | `{entity}_repository_impl.dart` | `task_repository_impl.dart` |
| UseCase | `{action}_{entity}_use_case.dart` | `start_timer_use_case.dart` |
| DataSource (abstrato) | `{entity}_remote_data_source.dart` | `task_remote_data_source.dart` |
| DataSource (impl) | `{entity}_remote_data_source_impl.dart` | `task_remote_data_source_impl.dart` |
| Enum | `{entity}_{topic}_enum.dart` | `task_status_enum.dart` |
| Bloc | `{feature}_bloc.dart` | `task_list_bloc.dart` |
| Event | `{feature}_event.dart` | `task_list_event.dart` |
| State | `{feature}_state.dart` | `task_list_state.dart` |
| Page | `{feature}_page.dart` | `task_list_page.dart` |
| Widget | `{description}_widget.dart` | `task_card_widget.dart` |
| Failures (feature) | `{feature}_failures.dart` | `task_failures.dart` |

## Classes (PascalCase + sufixo obrigatório)

| Tipo | Sufixo | Exemplo |
|---|---|---|
| Entity | `Entity` | `TaskEntity` |
| Model | `Model` | `TaskModel` |
| Repository contrato | `Repository` | `TaskRepository` |
| Repository impl | `RepositoryImpl` | `TaskRepositoryImpl` |
| UseCase | `UseCase` | `StartTimerUseCase` |
| UseCase Params | `Params` | `StartTimerParams` |
| DataSource abstrato | `RemoteDataSource` | `TaskRemoteDataSource` |
| DataSource impl | `RemoteDataSourceImpl` | `TaskRemoteDataSourceImpl` |
| Enum | `Enum` | `TaskStatusEnum` |
| Bloc | `Bloc` | `TaskListBloc` |
| Event (base) | `Event` | `TaskListEvent` |
| State (base) | `State` | `TaskListState` |
| Page | `Page` | `TaskListPage` |
| Widget | `Widget` | `TaskCardWidget` |
| Failure | `Failure` | `TaskNotFoundFailure` |

## UseCases — verbo no infinitivo + sufixo `UseCase`

```
CreateTaskUseCase        # Criar tarefa
StartTimerUseCase        # Iniciar cronômetro (pausa o ativo)
RegisterManualTimeUseCase
CalculatePriorityUseCase
CompleteTaskUseCase
MigrateTasksUseCase
CheckFitsInDayUseCase    # "cabe no dia"
DeleteTaskUseCase
MoveTaskUseCase
CreateAppointmentUseCase
DeleteListUseCase
```

## Failures (PascalCase + sufixo `Failure`)

| Categoria | Exemplo |
|---|---|
| Negócio (feature) | `TaskNotFoundFailure`, `ActiveTimerConflictFailure`, `DayOverbookedFailure` |
| Infra (core) | `ServerFailure`, `NetworkFailure`, `PermissionDeniedFailure` |
| Auth (core) | `UnauthenticatedFailure`, `AuthFailure` |

## Regra geral: o sufixo deixa o papel imediatamente claro

```dart
// ❌ Ambíguo
class Task { ... }
class StartTimer { ... }

// ✅ Claro — papel arquitetural visível
class TaskEntity { ... }
class StartTimerUseCase { ... }
class TaskStatusEnum { ... }
```
