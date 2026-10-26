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

### Enum ↔ PocketBase (na camada data)
O enum é do **domínio**; a persistência é responsabilidade do **Model**. O enum carrega o
texto externo em `apiValue` e a conversão inversa é o `fromApi` — nunca `.name`, `.index`
nem `@JsonValue`:

```dart
@JsonEnum(valueField: 'apiValue')
enum TimeEntryOriginEnum {
  timer('timer'),
  manual('manual');

  const TimeEntryOriginEnum(this.apiValue);
  final String apiValue;

  /// Ausente ou desconhecido → `null`.
  static TimeEntryOriginEnum? fromApi(String? raw) {
    for (final origin in values) {
      if (origin.apiValue == raw) return origin;
    }
    return null;
  }
}
```
Quem decide o que fazer com `null` (falhar ou usar padrão) é o Model, no `toEntity()`.
Quando a tela precisa seguir funcionando, o enum pode ter um valor `unknown`/padrão.

## Quando usar constante nomeada (não-enum)

Valores que **não** são conjunto fechado mas também não podem ser literais soltas:

- **Coleções e campos do PocketBase** → `lib/core/constants/pb_schema.dart`
  (`PbCollections.tasks`, `PbFields.isDone`), nunca `'tasks'`/`'due_date'` espalhados
  (ver `pocketbase.md`).
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
| `client.collection('tasks')` | `client.collection(PbCollections.tasks)` |
| `data['due_date']` na query | `PbFields.dueDate` |
| `context.go('/login')` | `context.go(Routes.login)` |
| enum gravado por `.name`/`.index` | `apiValue` / `fromApi` |
