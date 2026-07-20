# Regras do projeto — Meu Tempo

Regras de arquitetura e convenções, adaptadas do projeto `limit_spending` para a stack
do **Meu Tempo**: **Flutter Web (PWA mobile)** + **Firebase** + **BLoC** + **fpdart**.

Carregar sob demanda via `@.claude/rules/<arquivo>.md`.

| Arquivo | Assunto |
|---|---|
| `architecture.md` | Clean Architecture, regra de dependência, fluxo de dados |
| `naming.md` | Nomenclatura de arquivos, classes e sufixos |
| `enums.md` | Preferir `enum`/constantes; proibir strings hard-coded |
| `domain-layer.md` | Entities, UseCases, Repositories (contratos), Failures |
| `data-layer.md` | Models, DataSources, RepositoryImpl (Firestore) |
| `presentation-layer.md` | BLoC (event→state), Pages, widgets, switch exaustivo |
| `bloc.md` | Padrões de BLoC (`flutter_bloc`): Bloc, Event, State, DI |
| `firebase.md` | Firebase Auth + Cloud Firestore: coleções, isolamento por usuário |
| `navigation.md` | `go_router` + `BlocListener` para navegação reativa |
| `layout.md` | UI mobile-first, chips em vez de dropdown, sem fricção |
| `design.md` | Identidade visual: tema escuro, paleta rica, tipografia, movimento |
| `logging.md` | Logging sem `print` |
| `testing.md` | Testes com `bloc_test` + `mocktail` |
| `templates/` | Modelos de código por camada |

> Fonte da verdade dos requisitos: `docs/` (ver `CLAUDE.md`). As regras aqui dizem
> **como** implementar; os `docs/` dizem **o que** implementar.
