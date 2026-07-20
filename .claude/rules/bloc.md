---
paths:
  - "lib/features/*/presentation/bloc/**"
  - "lib/core/di/**"
---

# BLoC Rules (`flutter_bloc`)

Padrão de gerência de estado do Meu Tempo. Substitui o Riverpod do projeto-base.

## Estilo: Bloc com eventos (não Cubit)

Todo estado passa por um **Event** explícito. Isso dá rastreabilidade (cada mudança de
estado tem um evento nomeado) e casa com os fluxogramas em `docs/` (cada ação do usuário
→ um evento → um UseCase).

```
UI dispara Event  →  Bloc.on<Event>  →  chama UseCase  →  fold(Either)  →  emit(State)
```

## Injeção de dependências — get_it + injectable (fixado)

DI com **`get_it`** (service locator) + **`injectable`** (geração de código via
anotações). Configuração central em `lib/core/di/injector.dart`:

```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injector.config.dart';

final sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => sl.init(); // sl.init() é gerado por injectable
```

Gerar o `injector.config.dart` com:
`dart run build_runner build --delete-conflicting-outputs`

Cadeia por camada, montada uma vez no boot (`await configureDependencies()` no `main`):

```
FirebaseFirestore / FirebaseAuth   (@module — singletons)
      → RemoteDataSource   (@LazySingleton(as: ...))
      → RepositoryImpl     (@LazySingleton(as: ...))
      → UseCases           (@injectable)
      → Bloc               (@injectable — factory, novo por tela)
```

- DataSource/Repository/UseCase: **`@LazySingleton(as: Contrato)`** (registra pela interface).
- Bloc: **`@injectable`** → factory (instância nova por tela, descartada no `close()`).
- Blocs recebem **UseCases** por construtor, nunca Repository/DataSource.
- Objetos externos (Firebase) entram por um `@module`:

```dart
@module
abstract class FirebaseModule {
  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  @lazySingleton
  FirebaseAuth get auth => FirebaseAuth.instance;
}
```

- Obter no provider da feature: `BlocProvider(create: (_) => sl<TaskListBloc>()..add(...))`.

## Providência na árvore de widgets

- `BlocProvider(create: (_) => sl<TaskListBloc>()..add(TaskListStarted()))` na entrada
  da feature. Disparar o evento inicial no `create` (`..add(...)`), não no `build`.
- Blocs compartilhados por várias telas (ex.: `AuthBloc`, `ActiveTimerBloc`) ficam num
  `MultiBlocProvider` alto na árvore.

## `context.read` vs `context.watch` vs `BlocListener`

| Uso | Onde | Propósito |
|---|---|---|
| `context.read<B>().add(Event)` | callbacks (`onPressed`) | disparar evento, sem rebuild |
| `BlocBuilder` / `context.watch` | `build()` | reconstruir ao mudar o estado |
| `BlocListener` | `build()` | side-effects: snackbar, navegação (não reconstrói) |
| `BlocConsumer` | `build()` | precisa de builder + listener juntos |

```dart
// ❌ ERRADO — read no build para renderizar (não reconstrói)
Widget build(context) { final s = context.read<TaskListBloc>().state; ... }

// ✅ CERTO — watch/BlocBuilder no build
Widget build(context) => BlocBuilder<TaskListBloc, TaskListState>(builder: ...);

// ✅ CERTO — read em callback
onPressed: () => context.read<TaskListBloc>().add(TaskCreated(title)),
```

## Regra do cronômetro único (específica do Meu Tempo)

Só **1 cronômetro ativo por usuário**. O estado do timer ativo é global → um
`ActiveTimerBloc` no topo da árvore. Iniciar outro dispara o UseCase que pausa o
anterior; a regra de pausar mora no **UseCase**, não no Bloc.

## Streams do Firestore

Quando o Bloc escuta `snapshots()`:

```dart
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  StreamSubscription? _sub;

  TaskListBloc(this._watchTasks) : super(TaskListInitial()) {
    on<TaskListStarted>((event, emit) {
      _sub?.cancel();
      _sub = _watchTasks().listen((tasks) => add(_TasksUpdated(tasks)));
    });
    on<_TasksUpdated>((event, emit) => emit(TaskListLoaded(event.tasks)));
  }

  @override
  Future<void> close() {
    _sub?.cancel();   // SEMPRE cancelar no close — evita memory leak
    return super.close();
  }
}
```

> Para emitir a partir de uma stream **dentro do handler**, preferir `emit.forEach`/
> `emit.onEach` (mantém o handler vivo) OU converter a emissão da stream num evento
> interno (`_TasksUpdated`) como acima. Nunca chamar `emit` após o handler terminar.

## Anti-Patterns

1. Regra de negócio no Bloc → mover para UseCase/Entity.
2. `emit` depois que o handler retornou → usar evento interno ou `emit.forEach`.
3. Não cancelar `StreamSubscription`/`Timer` no `close()` → memory leak.
4. `Either` vazando para o State → resolver com `fold` no Bloc.
5. Bloc criado dentro do `build()` sem `BlocProvider` → recriado a cada rebuild.
6. Disparar evento inicial no `build()` → usar `..add()` no `create` do provider.
7. Injetar Repository no Bloc → sempre via UseCase.
