---
paths:
  - "lib/features/*/data/**"
  - "lib/core/**"
  - "pocketbase/**"
---

# PocketBase Rules (Auth + banco)

O backend do Meu Tempo é **PocketBase 0.40.5** na VPS (SDK Dart `pocketbase ^0.25.2`):
autenticação de usuário + persistência. App **sempre online** (sem modo offline nesta versão).
A URL vem de `POCKETBASE_URL` em `config/<ambiente>.json` (`AppConfig.pocketBaseUrl`).
Local: `tool/pb.sh serve` (`127.0.0.1:8095`).

## Isolamento por usuário (regra de ouro)

São **2 usuários independentes**, cada um vê **apenas os próprios dados**. Coleções
**planas**, todas com o campo `user` (relation → `users`, obrigatório, `cascadeDelete`):

| Coleção | O que guarda | Constante |
|---|---|---|
| `task_lists` | listas (categorias); "Entrada" criada por padrão | `PbCollections.taskLists` |
| `tasks` | tarefas (mãe/filha/neta via `parent`) | `PbCollections.tasks` |
| `appointments` | compromissos (data + hora início + duração) | `PbCollections.appointments` |
| `time_entries` | registros de tempo (folha ou compromisso) | `PbCollections.timeEntries` |
| `recurring_tasks` | modelos de tarefa recorrente | `PbCollections.recurringTasks` |
| `recurring_task_claims` | marcador "já gerei este dia" (id `<modeloId>-<AAAA-MM-DD>`) | `PbCollections.recurringTaskClaims` |
| `day_configs` | horas disponíveis/dia; padrões de criação rápida | `PbCollections.dayConfigs` |
| `active_timers` | no máx. 1 cronômetro ativo por usuário | `PbCollections.activeTimers` |

- `day_configs` e `active_timers`: 1 registro por usuário (`UNIQUE (user)`; "atualiza ou cria").
- Referências: `tasks.list`, `tasks.parent`, `recurring_tasks.list` e
  `recurring_task_claims.recurring_task` são `relation`. `tasks.recurring_task_id`,
  `time_entries.target_id`/`list_id`, `active_timers.target_id`/`list_id` e
  `appointments.list_id` são `text` (o histórico sobrevive à exclusão do alvo; o
  compromisso fica com lista órfã, como antes).
- Nomes só por `PbCollections`/`PbFields` (`lib/core/constants/pb_schema.dart`); nunca literal.

## API Rules (obrigatório)

Schema e regras vêm **só de migration** em `pocketbase/pb_migrations/` — nunca pelo painel.
Regras padrão (de `1792900000_init_schema.js`):

```
list / view / delete:  user = @request.auth.id
create:                @request.auth.id != "" && @request.body.user = @request.auth.id
update:                user = @request.auth.id && @request.body.user:isset = false
```

Relação com outra coleção, somada ao create **e** ao update (a opcional, `parent`, aceita vazio):

```
obrigatória (create):  @request.body.list.user = @request.auth.id
obrigatória (update):  (@request.body.list:isset = false || @request.body.list.user = @request.auth.id)
opcional (create):     (@request.body.parent = "" || @request.body.parent.user = @request.auth.id)
opcional (update):     (@request.body.parent:isset = false || @request.body.parent = "" || @request.body.parent.user = @request.auth.id)
```

- `users`: cadastro fechado (`createRule = null`), demais regras `id = @request.auth.id`,
  senha mínima 8, token de 30 dias.
- **Coleção nova**: nasce travada, ganha a regra de dono e passa no
  `uv run ~/.claude/skills/pocketbase-db/scripts/pb_check.py` sem FAIL (sem login nada passa;
  B não lista, lê, cria em nome de A, altera, apaga nem aponta para registro de A).
  Ver `~/.claude/rules/backend-record-ownership.md`.
- A segurança real mora **nas API Rules**; filtrar por `user` no app é só consulta.
- **Nenhuma regra de negócio no servidor**: lá só schema, autorização e integridade (`UNIQUE`).

## Sessão e login

- Login por e-mail e senha (`authWithPassword` em `PbCollections.users`); sem cadastro nem
  recuperação de senha no app.
- `PocketBaseClientFactory.create` monta o cliente com `AsyncAuthStore` gravado em
  `flutter_secure_storage` (`SecureStorageKeys.pocketBaseAuth`; iOS `first_unlock`).
  É o único lugar que cria `PocketBase(` ou usa `flutter_secure_storage`.
- `PocketBaseSession`: `client`, `isSignedIn`, `userId` (sem sessão →
  `UnauthenticatedException`) e `refreshSession()` no boot (401/403/404 limpam a sessão;
  rede e 5xx mantêm).
- 2º engine da tela de bloqueio: `initializeAppServices(refreshSession: false)`; sem sessão
  → avisa `backgroundFailed`.
- Ao **logout**, `authStore.clear()` (apaga o token salvo) e reset dos Blocs dependentes
  (fechar/reabrir o `MultiBlocProvider` ou evento de reset) — não deixar dado do usuário
  anterior em memória. A `presentation` reage à mudança de auth (ver `navigation.md`).

## Acesso nos DataSources

- Recebem `PocketBaseSession` (e `RecordWatcher` quando têm `watch*`) por injeção; nunca
  criam cliente nem leem o armazenamento.
- Ler `_session.userId` antes de todo pedido; `create` envia `PbFields.user`; `update`
  nunca envia `user`.
- `update` substitui com **todas** as chaves do `toJson()` (`includeIfNull: true`: `null` limpa).
- Listas por `getFullList(...)` (`getList` sem `perPage` devolve só 30); registro único por
  `getList(perPage: 1, skipTotal: true)`.
- Filtro com parâmetro (`client.filter('${PbFields.targetId} = {:t}', {'t': id})`), nunca
  concatenação.
- Erros: `on ClientException catch (e) { throw mapPocketBaseError(e); }`; 404 em `delete`
  é ignorado quando o contrato aceita.
- Datas: instante por `InstantCodec`/`@InstantConverter()`; dia por
  `CalendarDateCodec`/`@CalendarDateConverter()` (meia-noite UTC no servidor = dia local no
  app); nunca `DateTime.parse` direto.
- Id gerado no app (para encadear num lote): `RecordIdGenerator.next()`.
- **Tempo agregado da mãe/avó é derivado** (soma das folhas) — não persistir em duplicidade
  no servidor (evita divergência). Calcular ao montar a Entity/relatório.

## Tempo real

`RecordWatcher.watch(collection: PbCollections.x, load: () => ...)` emite o `load()` ao
assinar, recarrega a cada evento (rajada vira um só recarregamento) e ao reconectar
(`RealtimeTopics.connect`). Erro vira `addError(AppException)` sem fechar o stream; cancelar
a assinatura faz `unsubscribe`. O Bloc cancela a `StreamSubscription` no `close()` (ver `bloc.md`).

## Atomicidade (sem transação)

- `client.createBatch()`: até 500 pedidos; cria o alvo antes de quem aponta para ele e apaga
  na ordem inversa (`orderParentsFirst` em `lib/features/task/data/task_batch_order.dart`);
  lote vazio não envia pedido.
- Contador: `update(id, body: {PbFields.increment(PbFields.spentMinutes): n})`.
- Disputa de registro único: ler, decidir no repository/domain e apagar ou gravar em lote;
  `delete` de registro já apagado (404) ou `validation_not_unique` (`ConflictException`) =
  outro chamador venceu. Exemplos: `claimActive`, `replaceActiveIf`, `clearActiveIf`
  (cronômetro) e `claimGeneration` (marcador `recurring_task_claims`).
- "Atualiza ou cria" com `UNIQUE (user)`: `ConflictException` no `create` → reler uma vez e `update`.

## Custo/volumetria

Uso pessoal, 2 usuários, sem concorrência relevante. Não há necessidade de otimização
agressiva de leituras nesta versão — priorizar simplicidade e correção.
