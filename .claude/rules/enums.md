# Enums e Constantes — evitar strings hard-coded

## Princípio (OBRIGATÓRIO)

**Prefira `enum` a strings soltas. Toda string que representa um valor de um conjunto
fixo, uma chave ou um caminho DEVE virar `enum` ou constante nomeada.** String literal
espalhada pelo código é proibida — é fonte de typo silencioso, sem autocomplete e sem
`switch` exaustivo.

> Regra prática: se você digitou a mesma string em dois lugares, ou ela pertence a um
> conjunto conhecido de valores, ela **não** pode ser literal — vira `enum` ou constante.

## Quando usar `enum`

Todo conjunto **fixo e conhecido** de valores é `enum` (sufixo `Enum`, ver `naming.md`):

- Estados/categorias de domínio: `TaskStatusEnum { pending, done }`,
  `TimeEntryOriginEnum { timer, manual }`, `ImportanceEnum` (se fizer sentido nomear
  1–4), `UrgencyBandEnum`, `GoalDirectionEnum { increase, limit }`.
- Discriminadores de tipo: tarefa vs compromisso, tipo de medição.
- Qualquer valor que hoje seria `String status == 'done'`.

Vantagens: `switch` **exaustivo** (o analyzer cobra todos os casos), autocomplete, sem typo.

```dart
enum TaskStatusEnum { pending, done }

// UI decide o texto (PT) — o enum é o valor
String label(TaskStatusEnum s) => switch (s) {
  TaskStatusEnum.pending => 'Pendente',
  TaskStatusEnum.done => 'Concluída',
};
```

### Enum ↔ Firestore (na camada data)
O enum é do **domínio**; a persistência é responsabilidade do **Model**. Serializar o
enum por **nome** (`.name`) — nunca por índice (`.index`), que quebra ao reordenar:

```dart
@JsonEnum()                       // json_serializable cuida do enum
enum TaskStatusEnum { pending, done }

// no Model: @JsonKey(...) usa o .name automaticamente com json_serializable
```
Se precisar de valor customizado no Firestore, usar `@JsonValue('...')` no membro do enum.

## Quando usar constante nomeada (não-enum)

Valores que **não** são conjunto fechado mas também não podem ser literais soltas:

- **Caminhos/coleções do Firestore** → `lib/core/constants/firestore_paths.dart`
  (ex.: `FirestorePaths.tasks(uid)`), nunca `'users'`/`'tasks'` espalhados (ver `firebase.md`).
- **Chaves de campo do documento** → centralizar constantes por Model
  (ex.: `class TaskFields { static const title = 'title'; }`) — evita typo em query
  (`where(TaskFields.isDone, ...)`).
- **Nomes de rota** → constantes em `app_router.dart` (ex.: `Routes.login = '/login'`),
  nunca `context.go('/login')` com literal espalhada.
- **Defaults de negócio** (ex.: importância padrão 4, 30 min, "Entrada") → constantes
  nomeadas no domínio, não números/strings mágicos no meio do código.

## Exceções (onde string literal é aceitável)

- Texto de UI exibido ao usuário em PT (`Text('Pendente')`) — mas prefira derivar de um
  `switch` sobre enum quando o texto depende de um estado.
- Mensagens de log.
- Strings usadas **uma única vez** e sem significado de "conjunto" (ex.: label de um
  `Semantics` pontual). Na dúvida, nomeie.

## Anti-patterns

| ❌ Errado | ✅ Certo |
|---|---|
| `if (task.status == 'done')` | `if (task.status == TaskStatusEnum.done)` |
| `origin: 'manual'` | `origin: TimeEntryOriginEnum.manual` |
| `_firestore.collection('tasks')` | `_firestore.collection(FirestorePaths.tasksSegment)` |
| `data['dueDate']` na query | `data[TaskFields.dueDate]` |
| `context.go('/login')` | `context.go(Routes.login)` |
| `enum` serializado por `.index` | serializar por `.name` / `@JsonValue` |
