---
paths:
  - "lib/features/*/data/**"
  - "lib/core/**"
---

# Firebase Rules (Auth + Cloud Firestore)

O backend do Meu Tempo é **Firebase**: autenticação de usuário + persistência na nuvem.
App **sempre online** (sem modo offline explícito nesta versão).

## Isolamento por usuário (regra de ouro)

São **2 usuários independentes**, cada um vê **apenas os próprios dados**. Modelo de
dados **por usuário**, com tudo aninhado sob o `uid`:

```
users/{uid}/
  tasks/{taskId}            # tarefas (mãe/filha/neta via parentId)
  lists/{listId}            # listas (categorias); "Entrada" criada por padrão
  appointments/{apptId}     # compromissos (data + hora início + duração)
  timeEntries/{entryId}     # registros de tempo (folha ou compromisso)
  settings/config           # horas disponíveis/dia; padrões de criação rápida
  activeTimer/current       # no máx. 1 cronômetro ativo por usuário
```

- **NUNCA** consultar coleção raiz sem o `uid` na frente.
- O `uid` vem da camada de auth e é passado até o DataSource — o domínio não conhece
  Firebase, mas os UseCases podem receber o `uid` (ou uma abstração `AuthRepository`)
  como parâmetro/dependência.

## Firestore Security Rules (obrigatório antes de produção)

Regra base: só o dono acessa o próprio ramo.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

> A segurança real mora **nas Security Rules**, não no app. Filtrar por `uid` no
> cliente é UX; as rules são o que impede um usuário de ler dados do outro.

## Auth

- Login por usuário via Firebase Auth. Uma feature `auth` expõe `AuthRepository`
  (contrato no domínio) com `currentUid`, `signIn`, `signOut`, stream de estado.
- A `presentation` reage a mudança de auth para redirecionar (ver `navigation.md`).
- Ao **logout**, resetar o estado dos Blocs dependentes (fechar/reabrir o `MultiBlocProvider`
  ou disparar evento de reset) — não deixar dado do usuário anterior em memória.

## Acesso ao Firestore

- Injetar `FirebaseFirestore` e `FirebaseAuth` (nunca `.instance` direto no DataSource) —
  registrar como dependência única no boot do app. Facilita teste com `fake_cloud_firestore`.
- Datas: `Timestamp` no Firestore ↔ `DateTime` no Model (converter no `fromMap`/`toMap`).
- **Tempo agregado da mãe/avó é derivado** (soma das folhas) — não persistir em
  duplicidade no Firestore (evita divergência). Calcular ao montar a Entity/relatório.

## Streams vs. leitura pontual

- Listas que precisam refletir mudanças em tempo real (listagem de tarefas do dia,
  cronômetro ativo) podem usar `snapshots()` (stream) → o Bloc escuta e emite estados.
- Cancelar as `StreamSubscription` no `close()` do Bloc (ver `bloc.md`).

## Custo/volumetria

Uso pessoal, 2 usuários, sem concorrência relevante. Não há necessidade de otimização
agressiva de leituras nesta versão — priorizar simplicidade e correção.
