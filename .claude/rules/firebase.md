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

### Login Google no Android (`signInWithProvider`)

- O `android/app/src/main/AndroidManifest.xml` **deve** declarar, dentro de `<queries>`,
  o serviço de Custom Tabs — não remover:
  ```xml
  <intent>
      <action android:name="android.support.customtabs.action.CustomTabsService"/>
  </intent>
  ```
- **Por quê:** no Android 11+ (visibilidade de pacotes) o `firebase_auth` não enxerga o
  Custom Tabs do Chrome sem isso e abre o login no Chrome completo, que não redireciona
  de volta ao app. Sintoma: login funciona no web, mas no Android volta para a tela de
  login (no logcat, `GenericIdpActivity` destruída e `ChromeTabbedActivity` no lugar de
  Custom Tab).
- O **Web client (auto created by Google Service)** no Google Cloud Console
  (Credenciais → IDs do cliente OAuth 2.0) **deve** ter os dois URIs de redirecionamento —
  não remover nenhum:
  - `https://meu-tempo-dev.web.app/__/auth/handler` — web (usa o `authDomain` do
    `firebase_options.dart`, trocado para `web.app` por causa do bloqueio de cookies de
    terceiros no redirect).
  - `https://meu-tempo-dev.firebaseapp.com/__/auth/handler` — Android/iOS: o SDK nativo
    ignora o `authDomain` do web e usa o domínio padrão `<projectId>.firebaseapp.com`.
  - Sem o do `firebaseapp.com`, o login nativo falha com `Erro 400: redirect_uri_mismatch`.
  - Decisão (20/10/2026): manter os dois URIs em vez de unificar via `authDomain` nas
    opções nativas.
- Ao diagnosticar falha de login nativo, nesta ordem: SHA-1/SHA-256 da máquina no
  Firebase (`firebase apps:android:sha:list`); `<queries>` do Custom Tabs; URI do
  `firebaseapp.com` no Web client; só então remover `android:taskAffinity=""` da
  `MainActivity`.

## Acesso ao Firestore

- Injetar `FirebaseFirestore` e `FirebaseAuth` (nunca `.instance` direto no DataSource) —
  registrar como dependência única no boot do app. Facilita teste com `fake_cloud_firestore`.
- Datas: `Timestamp` no Firestore ↔ `DateTime` no Model via `@TimestampConverter()`
  (`lib/core/utils/timestamp_converter.dart`) do `json_serializable`.
- **Tempo agregado da mãe/avó é derivado** (soma das folhas) — não persistir em
  duplicidade no Firestore (evita divergência). Calcular ao montar a Entity/relatório.

## Streams vs. leitura pontual

- Listas que precisam refletir mudanças em tempo real (listagem de tarefas do dia,
  cronômetro ativo) podem usar `snapshots()` (stream) → o Bloc escuta e emite estados.
- Cancelar as `StreamSubscription` no `close()` do Bloc (ver `bloc.md`).

## Custo/volumetria

Uso pessoal, 2 usuários, sem concorrência relevante. Não há necessidade de otimização
agressiva de leituras nesta versão — priorizar simplicidade e correção.
