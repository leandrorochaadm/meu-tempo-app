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

- `docs/requisitos-time-control.md` — requisitos de negócio (14 essenciais da v1).
- `docs/handoff-time-control.md` — histórias de usuário H1–H14 com critérios de aceite.
- `docs/gerenciador_tarefas_v1_diagrams.md` — fluxogramas dos UseCases (CEN/CA, Failures).

Nunca invente requisito. Se algo não está nos documentos, **pergunte** (ver skill
`validate-requirements`).

## Stack

- **Flutter Web** compilado como **PWA** — uso **exclusivo em celular**. Projete
  **mobile-first, tela pequena, alvos de toque grandes**. Não desenhe layouts de desktop.
- **Sempre online** — sem modo offline nesta versão.
- **Backend: Firebase** — Auth (login por usuário) + Cloud Firestore (persistência na
  nuvem). **Dados isolados por usuário**: toda query filtra pelo `uid` do usuário logado.
- **Estado: BLoC** (`flutter_bloc`) no estilo **event → state** (Bloc clássico com
  eventos, não Cubit). Um Bloc por feature/fluxo.
- **Erros no domínio: `Either<Failure, T>`** (via `fpdart`). UseCase retorna
  `Right(Entity)` no sucesso e `Left(Failure)` no erro — espelha os fluxogramas.

## Regras detalhadas

As convenções completas vivem em `.claude/rules/` (carregar sob demanda). Índice em
`.claude/rules/README.md`. Principais: `architecture.md`, `domain-layer.md`,
`data-layer.md`, `presentation-layer.md`, `bloc.md`, `firebase.md`, `navigation.md`,
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
      domain/                # regra de negócio pura — sem Flutter, sem Firebase
        entities/
        repositories/        # contratos (interfaces abstratas)
        usecases/
      data/                  # implementação
        models/              # DTOs <-> Firestore (json_serializable + TimestampConverter)
        datasources/         # acesso ao Firebase
        repositories/        # implementa o contrato do domain
      presentation/
        bloc/                # <feature>_bloc.dart, _event.dart, _state.dart
        pages/
        widgets/
```

**Regra de dependência:** `presentation → domain ← data`. O domínio não conhece
Flutter nem Firebase. A UI (widget/page) fala com o **Bloc**, nunca chama Repository
ou DataSource direto.

## Regras do domínio (obrigatórias)

- **Entity** é imutável e pura: sem `copyWith`, sem importar pacote externo (nada de
  Firebase na entity). Conversão de/para Firestore (`Map`) vive no **Model** (camada
  data), via `json_serializable` (`@JsonSerializable`, `fromJson`/`toJson` gerados) com
  um `TimestampConverter` central para as datas do Firestore; o `id` vem do `doc.id`,
  não do corpo do documento.
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
- **Prioridade** = `tempoEstimado × (5 − importância) × urgênciaDoPrazo`
  (importância 1 = máxima). Recalcular na abertura da lista (depende da data atual).
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
make run                         # rodar no Chrome com perfil persistente (mantém login)
flutter run -d chrome            # rodar sem perfil fixo (pede login a cada run)
flutter test                     # testes
flutter analyze                  # análise estática (manter zero issues)
flutter build web --release      # build de produção do PWA
```
