---
paths:
  - "test/**"
---

# Testing Rules

## Ferramentas
- `flutter_test` + `bloc_test` + `mocktail`.
- Para DataSource/Firestore: `fake_cloud_firestore` (não mockar Firestore na mão).
- A estrutura de `test/` espelha `lib/`.

## Estrutura

```
test/features/{feature}/
  data/
    datasources/{feature}_remote_data_source_test.dart
    models/{feature}_model_test.dart
    repositories/{feature}_repository_impl_test.dart
  domain/
    usecases/{action}_use_case_test.dart
  presentation/
    bloc/{feature}_bloc_test.dart
    pages/{feature}_page_test.dart
```

## Pirâmide (teste no nível mais barato possível)

| Nível | O que testa | Como |
|---|---|---|
| Unitário | Entity (getters `isLeaf`, `prioridade`, soma), UseCase, `Either` | `flutter_test` + `mocktail` |
| Bloc | Transições de estado com UseCases mockados | `bloc_test` |
| Page | Renderização/interação (`find`/`tap`/`enterText`) | `flutter_test` |
| E2E | App real ponta a ponta (poucos) | `integration_test` |

## Regras por camada

- **Mocke a dependência direta, não a da dependência.** No teste de Bloc, mocke os
  **UseCases**; nunca `FirebaseFirestore` (isso é teste de `data`).
- **UseCase**: mocke Repository, verifique delegação e Params corretos, cubra
  `Left(Failure)` e `Right(Entity)`.
- **Repository**: use `fake_cloud_firestore`, verifique Model→Entity e Exception→Failure.
- **Bloc** (`bloc_test`): `build` → `act` (add event) → `expect` (sequência de estados).
  Cobrir Initial→Loading→Loaded **e** →Error.

```dart
blocTest<TaskListBloc, TaskListState>(
  'emite [Loading, Loaded] quando busca com sucesso',
  build: () {
    when(() => getTasks(any())).thenAnswer((_) async => Right(tasks));
    return TaskListBloc(getTasks);
  },
  act: (bloc) => bloc.add(TaskListStarted()),
  expect: () => [isA<TaskListLoading>(), isA<TaskListLoaded>()],
);
```

## Higiene

- `registerFallbackValue` no `setUpAll` para tipos usados em `any()`.
- `setUp()` recria mocks/bloc a cada teste (isolamento).
- Nomes descritivos: `'mostra empty state quando não há tarefas'` > `'test 1'`.
- Viewport de celular no page test:
  `tester.view.physicalSize = const Size(390, 844);` + `addTearDown(...resetPhysicalSize)`.
- No page test, preferir `find.text`/`find.byIcon` a `find.byType(WidgetInterno)`.
