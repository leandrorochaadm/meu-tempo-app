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
- **PocketBase** — login por e-mail e senha + banco (cada usuário só acessa os próprios dados, regra no servidor)
- **BLoC** (`flutter_bloc`) — gerência de estado (event → state)
- **fpdart** — `Either<Failure, T>` no domínio
- **get_it + injectable** — injeção de dependências
- **go_router** — navegação
- Arquitetura: **Clean Architecture**, feature-first

## Documentação

- `docs/` — requisitos, handoff técnico e diagramas de fluxo (fonte da verdade)
- `CLAUDE.md` — convenções do projeto
- `.claude/rules/` — regras detalhadas por camada (índice em `.claude/rules/README.md`)

## Rodar localmente

1. `tool/pb.sh serve` — sobe o PocketBase em `http://127.0.0.1:8095` com as migrations de `pocketbase/pb_migrations` (dados em `.pb/`, fora do git).
2. `tool/pb.sh superuser <email>` — cria o superusuário local (pede a senha); a conta de login se cria pelo app, em "Criar conta" na tela de entrada.
3. `cp config/dev.json.example config/dev.json` — aponta o app para `http://127.0.0.1:8095` (`POCKETBASE_URL`). Sem o arquivo, o app abre a tela "O app não foi configurado."
4. `make run` — roda no Chrome com perfil e porta fixos (mantém o login entre execuções).

## Comandos

```bash
flutter pub get                                    # instalar dependências
dart run build_runner build --delete-conflicting-outputs   # gerar código (injectable)
make run                                           # rodar no Chrome mantendo o login entre execuções
flutter run -d chrome                              # rodar sem perfil fixo (pede login a cada run)
flutter test                                       # testes
flutter analyze                                    # análise estática (manter zero issues)
flutter run -d <device> --dart-define-from-file=config/prod.json   # rodar no celular (Android ou iPhone)
make build                                         # build de produção do PWA (usa config/prod.json se existir)
flutter build apk --release --dart-define-from-file=config/prod.json   # APK para instalação direta no Android
make ship                                          # analyze + testes
```

## Instalar no celular Android

O endereço do servidor (`POCKETBASE_URL`) entra no app **na compilação**, pelo
`--dart-define-from-file`. Um APK compilado sem esse parâmetro abre a tela
"O app não foi configurado."

```bash
flutter devices                                    # descobrir o ID do celular
flutter build apk --debug --dart-define-from-file=config/prod.json
flutter install --debug -d <id-do-celular>
```

Atalho: com `ANDROID_DEVICE=<id-do-celular>` no `.env`, o `make run-android` compila,
instala e abre o app já com o `config/prod.json` (`make run-android-release` para o
modo release). Os alvos do Makefile usam `fvm`; sem ele, rode os comandos acima com
`flutter` direto.

## Conta de demonstração (revisão da loja)

Conta usada pelo revisor da Google Play (e para demonstrar o app), no servidor de produção:

- **E-mail:** `demo@meutempo.com`
- **Senha:** `demo1234`

`uv run tool/seed_demo.py` apaga e recria a conta com dados de exemplo (precisa de acesso
`ssh hostinger`). Se o revisor não conseguir entrar, rode o script de novo.
