# Meu Tempo

App pessoal de **controle de tempo** — um Bullet Journal digital (metodologia Ryder
Carroll) com cronômetro por tarefa, hierarquia de tarefas e agenda. Codinome técnico
do repositório: `time_control`; nome do produto: **Meu Tempo**; pacote Dart: `meu_tempo`.

## 🛑 Regra Crítica — regra de negócio SEMPRE em `domain` (OBRIGATÓRIA)

**Toda regra de negócio DEVE morar na camada `domain`. Nunca em `data` nem em
`presentation`.** Sem exceção.

- Regra **intrínseca ao objeto** (validação, cálculo, estado derivado) → getter na
  **Entity** (ex.: `isLeaf`, `totalEstimatedMinutes`).
- Regra de **fluxo / cálculo que cruza dados / "pode fazer X"** → **UseCase**
  (ex.: prioridade que depende da data de hoje, "cabe no dia", pausar cronômetro ativo).
- `presentation` (Bloc/State/Page): só orquestra UI, formata exibição e traduz
  `Failure` → estado. **Nenhuma** decisão de negócio.
- `data` (Model/DataSource/Repository): só I/O e conversão. **Nenhuma** decisão de negócio.

Se pedirem para colocar regra de negócio fora de `domain`, **PARE e confronte** antes de
implementar. Detalhes e anti-patterns em `.claude/rules/architecture.md`.

## Fonte da verdade dos requisitos

Os documentos em `docs/` são a **fonte da verdade** do que o app faz. Leia antes de
implementar qualquer funcionalidade e cite o requisito/critério de origem:

- `docs/requisitos-time-control.md` — requisitos de negócio (15 essenciais da v1).
- `docs/handoff-time-control.md` — histórias de usuário H1–H15 com critérios de aceite.
- `docs/gerenciador_tarefas_v1_diagrams.md` — fluxogramas dos UseCases (CEN/CA, Failures).

Nunca invente requisito. Se algo não está nos documentos, **pergunte** (ver skill
`validate-requirements`).

## Stack

- **Flutter multiplataforma — Web (PWA) + Android + iOS**, do mesmo código — uso
  **exclusivo em celular**. Projete **mobile-first, tela pequena, alvos de toque
  grandes**. Não desenhe layouts de desktop.
  - **Alvos nativos** (decisão de 07/10/2026): o cronômetro na tela bloqueada exige
    código nativo, por isso entram Android e iOS; o **PWA continua**. Mínimo **iOS 17** e
    **Android 12 (API 31)**; bundle/application id `br.com.tekton.meutempo`; instalação
    direta, sem lojas. Detalhes e riscos em `docs/tecnico-time-control.md`.
  - **Recurso só nativo:** cronômetro na tela bloqueada/notificação. No web, o código de
    plataforma fica atrás de uma abstração com implementação vazia (`kIsWeb`).
  - **Alvos nativos criados:** `android/` e `ios/` sem configuração de backend própria; o
    login por e-mail e senha é igual nas três plataformas. Builds Android/iOS só num Mac;
    a VPS gera só o PWA.
- **Sempre online** — sem modo offline nesta versão.
- **Backend: PocketBase** (0.40.5, na VPS, atrás do Caddy) — login por e-mail e senha
  (cadastro fechado) + coleções planas. **Dados isolados por usuário**: todo registro tem
  o campo `user`, e as API Rules de dono no servidor garantem que só o dono acessa.
  Tempo real por `subscribe` (`RecordWatcher`). Schema e regras em
  `pocketbase/pb_migrations/`. Detalhes em `.claude/rules/pocketbase.md` e
  `~/.claude/rules/backend-record-ownership.md`.
- **Estado: BLoC** (`flutter_bloc`) no estilo **event → state** (Bloc clássico com
  eventos, não Cubit). Um Bloc por feature/fluxo.
- **Erros no domínio: `Either<Failure, T>`** (via `fpdart`). UseCase retorna
  `Right(Entity)` no sucesso e `Left(Failure)` no erro — espelha os fluxogramas.

## Regras detalhadas

As convenções completas vivem em `.claude/rules/` (carregar sob demanda). Índice em
`.claude/rules/README.md`. Principais: `architecture.md`, `domain-layer.md`,
`data-layer.md`, `presentation-layer.md`, `bloc.md`, `pocketbase.md`, `navigation.md`,
`layout.md`, `enums.md`, `testing.md` + `templates/` por camada.

**Enums sobre strings (obrigatório):** todo conjunto fixo de valores é `enum`; caminhos,
chaves de campo, rotas e defaults viram `enum`/constante nomeada. **Nada de string
hard-coded** para valores de conjunto conhecido. Detalhes em `.claude/rules/enums.md`.

**Identidade visual (obrigatório):** tema **escuro único**, superfícies soft/arredondadas
(raio ~20, sombra sutil), **paleta rica e categórica** (cor por lista/estado/importância),
tipografia com hierarquia forte e micro-interações. Deve parecer **premium, não template
nem "gerado por IA"**. Detalhes em `.claude/rules/design.md`.

**UI centralizada no `core` + acesso via `context` (obrigatório):** todos os tokens
(cor, espaço, raio, tipografia, duração) vivem em `lib/core/theme/` e os componentes
compartilhados em `lib/core/ui/`; formatadores em `lib/core/utils/formatters/`. As telas
**consomem via `context`/`Theme`** — **PROIBIDA formatação hard-coded** na
`presentation` (nada de `Color(0x…)`, `TextStyle(...)`, `EdgeInsets`/`SizedBox` numérico,
`BorderRadius.circular(n)`, data formatada inline). **Fonte em asset — proibido
`google_fonts`.**

## Arquitetura — Clean Architecture, feature-first

```
lib/
  core/                      # compartilhado entre features
    error/failures.dart      # Failures reutilizáveis (ServerFailure, etc.)
    usecase/usecase.dart      # contrato base do UseCase
  features/
    <feature>/
      domain/                # regra de negócio pura — sem Flutter, sem backend
        entities/
        repositories/        # contratos (interfaces abstratas)
        usecases/
      data/                  # implementação
        models/              # DTOs <-> PocketBase (json_serializable + InstantConverter/CalendarDateConverter)
        datasources/         # acesso ao PocketBase (PocketBaseSession)
        repositories/        # implementa o contrato do domain
      presentation/
        bloc/                # <feature>_bloc.dart, _event.dart, _state.dart
        pages/
        widgets/
```

**Regra de dependência:** `presentation → domain ← data`. O domínio não conhece
Flutter nem o PocketBase. A UI (widget/page) fala com o **Bloc**, nunca chama Repository
ou DataSource direto.

## Regras do domínio (obrigatórias)

- **Entity** é imutável e pura: sem `copyWith`, sem importar pacote externo (nada de
  PocketBase na entity). Conversão de/para o registro do PocketBase (`RecordModel`) vive
  no **Model** (camada data), via `json_serializable` (`@JsonSerializable(includeIfNull:
  true, fieldRename: FieldRename.snake)`, `fromRecord`/`fromJson`/`toJson`) com
  `InstantConverter` (instante) e `CalendarDateConverter` (dia) de `lib/core/utils/`; o
  `id` vem do `record.id`, não do corpo do registro.
- **Regras intrínsecas da entity** viram getters (ex.: `bool get isFolha`,
  `int get prioridade`) — não espalhe cálculo pela UI.
- **Failure** não recebe `message` no construtor. Cada Failure é um tipo próprio
  (ex.: `TarefaNaoEncontradaFailure`); o texto exibido é decidido na `presentation`,
  mapeando Failure → estado de erro.
- **UseCase** tem um único método `call(...)` e retorna `Either<Failure, T>`. Ele
  orquestra a regra de negócio; não valida só formato local — valida a regra completa.

## Convenções do produto (não trocar)

- Na UI, manter os termos **"tarefa mãe / filha / neta"** (decisão do cliente — não
  usar "tarefa/subtarefa").
- **Folha** = tarefa sem filhas: única com cronômetro, tempo, data e importância
  próprios, e única que aparece na listagem por prioridade.
- Tempo da mãe/avó é **sempre derivado** (soma das folhas), nunca editável direto.
- **Prioridade** = `faixaDeEsforço × (5 − importância) × urgênciaDoPrazo`
  (importância 1 = máxima). A `faixaDeEsforço` é o tempo estimado traduzido em peso
  1–5 (`EffortBandEnum`: até 15 min, 16–30 min, 31–60 min, 1–3 h, +3 h) — em minutos
  crus o tempo dominava os outros fatores. Recalcular na abertura da lista (depende da
  data atual).
- **Só 1 cronômetro ativo** por usuário (vale para folhas e compromissos): dar start
  em outro pausa o anterior automaticamente.

## Idioma e comunicação

- Responder **sempre em português do Brasil**, com acentuação correta.
- Nomes de código (classes, variáveis, arquivos) em inglês; termos de domínio de UI
  em português (`Tarefa`, `Lista`, `Compromisso`).
- Antes de implementar, validar entendimento e perguntar quando houver dúvida
  (skill `validate-requirements`). Simplicidade > complexidade; sem over-engineering.

## Git

- Usar `git mv` / `git rm` (nunca `mv` / `rm`) para preservar histórico.
- Só commitar/push quando o usuário pedir.

## Comandos úteis

```bash
cp config/dev.json.example config/dev.json   # configuração local (aponta para http://127.0.0.1:8095)
tool/pb.sh serve                 # PocketBase local descartável em 127.0.0.1:8095
tool/pb.sh superuser <email>     # superusuário local (senha pedida no terminal)
make run                         # web: Chrome com perfil persistente, usando config/dev.json
flutter run -d chrome            # web: rodar sem perfil fixo (pede login a cada run)
flutter run -d <device>          # nativo: rodar no celular (Android ou iPhone conectado)
flutter test                     # testes
flutter analyze                  # análise estática (manter zero issues)
uv run tool/pb_permissions_test.py                          # permissões de dono e provas P1–P8
uv run ~/.claude/skills/pocketbase-db/scripts/pb_check.py   # valida migrations e regras
make build                       # build de produção do PWA (config/prod.json)
flutter build web --release      # build de produção do PWA
flutter build apk --release      # APK para instalação direta no Android (num Mac; a VPS gera só o PWA)
```
