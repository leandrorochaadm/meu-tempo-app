# Meu Tempo

Bullet Journal digital (metodologia Ryder Carroll) com **cronômetro por tarefa**,
hierarquia de tarefas e agenda pessoal. Para uso no celular: PWA (navegador) e app
nativo Android/iOS.

## Ambiente de desenvolvimento

| Ferramenta | Versão |
|---|---|
| **Flutter** | 3.41.9 (channel stable) |
| **Dart** | 3.11.5 |
| **DevTools** | 2.54.2 |

> ⚠️ As versões de `build_runner` e `injectable_generator` estão travadas por serem as
> últimas compatíveis com o Dart 3.11.5 (ver `pubspec.yaml`). Ao atualizar o Flutter para
> um Dart ≥3.12, essas travas podem ser soltas.

## Stack

- **Flutter** — PWA (web) + Android + iOS, do mesmo código (mobile-first, sempre online)
- **Firebase** — Auth + Cloud Firestore (dados isolados por usuário)
- **BLoC** (`flutter_bloc`) — gerência de estado (event → state)
- **fpdart** — `Either<Failure, T>` no domínio
- **get_it + injectable** — injeção de dependências
- **go_router** — navegação
- Arquitetura: **Clean Architecture**, feature-first

## Documentação

- `docs/` — requisitos, handoff técnico e diagramas de fluxo (fonte da verdade)
- `CLAUDE.md` — convenções do projeto
- `.claude/rules/` — regras detalhadas por camada (índice em `.claude/rules/README.md`)

## Comandos

```bash
flutter pub get                                    # instalar dependências
dart run build_runner build --delete-conflicting-outputs   # gerar código (injectable)
make run                                           # rodar no Chrome mantendo o login entre execuções
flutter run -d chrome                              # rodar sem perfil fixo (pede login a cada run)
flutter test                                       # testes
flutter analyze                                    # análise estática (manter zero issues)
flutter run -d <device>                            # rodar no celular (Android ou iPhone)
flutter build web --release                        # build de produção do PWA
flutter build apk --release                        # APK para instalação direta no Android
```
