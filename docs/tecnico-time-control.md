# Questionário técnico — Meu Tempo (time_control)

Versão: 1.0 | Data: 07/10/2026
Respondido por: Leandro — eu mesmo (dono e único dev)
Status: [x] Em coleta  [ ] Respondido  [ ] Congelado para desenvolvimento

**Motivação:** o cronômetro na tela bloqueada (`docs/entrevista-tela-bloqueio.md`)
exige código nativo. Com isso, o app ganha os alvos Flutter Android + iOS; o PWA
continua.

**Legenda:** 💰 = impacta orçamento · ⛔ = bloqueia o início do desenvolvimento

---

## 1. Backend e integrações

| # | Pergunta | Resposta |
|---|---|---|
| 1.1 💰 ⛔ | O backend já existe ou vai ser construído? Por quem? | Já existe: Firebase (Auth + Cloud Firestore) |
| 1.2 💰 | Qual a stack do backend? | Firebase; sem backend próprio |
| 1.3 ⛔ | Tem documentação de API? | Não se aplica (acesso via SDK do Firestore) |
| 1.4 | O contrato da API está estável? | Não se aplica |
| 1.5 ⛔ | Ambiente de homologação separado? | Não: um projeto Firebase só |
| 1.6 ⛔ | Como o app obtém credenciais? | Configuração do Firebase por plataforma (a gerar para Android/iOS) |
| 1.7 💰 | Integra com terceiros? | Não |
| 1.8 | Formato de erro padronizado da API? | Não se aplica (exceções do SDK → `Failure`) |
| 1.9 | Paginação | Não se aplica |
| 1.10 | Rate limit | Não se aplica |
| 1.11 | Tempo real | Streams do Firestore |

**Pendências de acesso:**

| Item | Responsável | Prazo |
|---|---|---|
| Registrar apps Android e iOS no projeto Firebase | Leandro | Antes do início |

---

## 2. Autenticação e autorização

| # | Pergunta | Resposta |
|---|---|---|
| 2.1 💰 ⛔ | Tipo de autenticação | Firebase Auth |
| 2.2 | Login social? Quais provedores? | **Google**. Hoje: `signInWithPopup`/`signInWithRedirect` (só web). No nativo: `signInWithProvider(GoogleAuthProvider())` ou `google_sign_in`; exige SHA-1 do app no Firebase (Android) e URL scheme com o reversed client id (iOS) |
| 2.3 | Token | Gerenciado pelo Firebase Auth |
| 2.4 | Onde o token é guardado | Gerenciado pelo Firebase Auth |
| 2.5 | Token expira com app aberto | Renovação automática do Firebase Auth |
| 2.6 💰 | Perfis de usuário | Um perfil; vários usuários, sem número fixo; **cadastro aberto** a qualquer conta Google; dados isolados por `uid` |
| 2.7 | Logout remoto | Não |
| 2.8 💰 | Biometria | Não |
| 2.9 | Múltiplos dispositivos simultâneos | Permitido, sem regra extra; os dados sincronizam pelo Firestore. A tela bloqueada não sincroniza entre os aparelhos; ao abrir o app, cada aparelho reconcilia a própria notificação/Live Activity com o estado do Firestore (sem push remoto) |

---

## 3. Arquitetura e stack Flutter

| # | Pergunta | Resposta |
|---|---|---|
| 3.1 ⛔ | Projeto novo ou base existente? | Base existente: Clean Architecture feature-first |
| 3.2 | Arquitetura | Clean Architecture (domain / data / presentation) |
| 3.3 | Gerência de estado | BLoC event → state (`flutter_bloc`), não Riverpod |
| 3.4 | Navegação | `go_router` |
| 3.5 | Injeção de dependência | `get_it` + `injectable` |
| 3.6 | Cliente HTTP | Não se aplica (SDK do Firebase) |
| 3.7 | Modelagem | `json_serializable` + `TimestampConverter` |
| 3.8 ⛔ | Versão do Flutter e do Dart | Dart `^3.11.5` · Flutter: _a registrar_ (`flutter --version` no início da implementação) |
| 3.9 | Flavors | Não |
| 3.10 | Design system | Próprio, tema escuro único (`.claude/rules/design.md`) |
| 3.11 | Tratamento de erro | `Either<Failure, T>` (`fpdart`) |
| 3.12 | Log e observabilidade | `.claude/rules/logging.md` |
| 3.13 | Lint | `flutter analyze` com zero issues |
| 3.14 | **Tela bloqueada (novo)** | Plugin ou platform channel nativo; no web, implementação vazia. **Android:** foreground service com tipo `specialUse` e `stopWithTask=false` (sobrevive ao app ser encerrado) + notificação contínua com ações. **iOS:** Live Activity (ActivityKit) + App Intents nos botões; limitada pelo sistema a 8 h ativa (+ até 4 h parada na tela bloqueada), limite aceito |

---

## 4. Dados locais, offline e sincronização

| # | Pergunta | Resposta |
|---|---|---|
| 4.1 💰 | Funciona offline? | Não: sempre online (decisão da v1) |
| 4.2 | Persistência local | Nenhuma própria |
| 4.3 | Cache de rede | Só o cache padrão do Firestore |
| 4.4 💰 | Escrita offline com fila | Não |
| 4.5 💰 | Resolução de conflito | Não se aplica |
| 4.6 | Volume local | Não se aplica |
| 4.7 | Dados locais no logout | Não se aplica |
| 4.8 | Migração de schema local | Não se aplica |

---

## 5. Serviços de plataforma

| # | Pergunta | Resposta |
|---|---|---|
| 5.1 💰 ⛔ | Gateway de pagamento | Não se aplica |
| 5.2 💰 | Assinatura recorrente | Não se aplica |
| 5.3 💰 | Push notification | Sem push remoto. Aviso de estouro (desejável, a cada 1 h): **notificação local** no nativo; no **web**, só aviso dentro do app quando aberto |
| 5.4 | Deep link | Sim: tocar na notificação/Live Activity (fora dos botões) abre o app na tarefa ou compromisso que está rodando, via rota do `go_router` |
| 5.5 | Analytics | Não |
| 5.6 | Crash reporting | Firebase Crashlytics (`firebase_crashlytics`), no mesmo projeto Firebase, só no **nativo** (Android e iOS). Captura via `FlutterError.onError` e `PlatformDispatcher.instance.onError`; o `logError` do `AppLogger` envia o erro como não fatal. Sem dado do usuário nos relatos (título de tarefa, humor/energia), só o `uid` como identificador. Símbolos: script de upload do dSYM no Xcode (iOS) e plugin Gradle do Crashlytics (Android). O Crashlytics não tem versão web: no **PWA** a chamada fica atrás da abstração com implementação vazia (`kIsWeb`) e o erro vai só para o console do navegador (risco 9) |
| 5.7 | Remote config | Não |
| 5.8 💰 | Mapa | Não se aplica |
| 5.9 💰 | Upload de arquivo | Não se aplica |

---

## 6. Build, distribuição e publicação

| # | Pergunta | Resposta |
|---|---|---|
| 6.1 💰 ⛔ | Contas das lojas | Sem conta da Play Store; Apple ID **gratuito** |
| 6.2 ⛔ | Quem publica nas lojas | Sem publicação: instalação direta |
| 6.3 ⛔ | Keystore Android e certificados iOS | Keystore: `.jks` fora do repositório, senhas no gerenciador de senhas, `key.properties` no `.gitignore` (o SHA-1 dela vai para o Firebase). iOS: assinatura automática do Xcode (personal team) |
| 6.4 | Bundle id / application id | `br.com.tekton.meutempo` (iOS e Android) |
| 6.5 | CI/CD | Não |
| 6.6 | Distribuição de build de teste | Android: APK direto. iOS: Xcode no aparelho |
| 6.7 | Versionamento | Conventional commits |
| 6.8 | Atualização forçada | Não |
| 6.9 | Ficha das lojas | Não se aplica |

---

## 7. Compatibilidade

| # | Pergunta | Resposta |
|---|---|---|
| 7.1 💰 | Versão mínima | **iOS 17** (Live Activity com botões) · **Android 13 / API 33** (pede permissão de notificação) |
| 7.2 💰 | Tablet / paisagem | Não: só celular, retrato |
| 7.3 | Web ou desktop | Web: sim, o PWA continua (sem o cronômetro na tela bloqueada; código de plataforma atrás de abstração com implementação vazia no web). Desktop: não |
| 7.4 💰 | Idioma e fuso | pt-BR, `America/Sao_Paulo` |
| 7.5 | Acessibilidade | Alvos de toque grandes (`.claude/rules/layout.md`) |
| 7.6 | Aparelhos de referência | iPhone e Android pessoais do Leandro |

---

## 8. Qualidade e testes

| # | Pergunta | Resposta |
|---|---|---|
| 8.1 | Cobertura esperada | `.claude/rules/testing.md` |
| 8.2 | Stack de teste | `flutter_test` + `bloc_test` + `mocktail` |
| 8.3 💰 | QA do cliente | Não: o próprio Leandro homologa |
| 8.4 | Critério de aceite | "Pronto quando" de `docs/entrevista-tela-bloqueio.md` |
| 8.5 | Ambiente de teste | Projeto Firebase único + aparelhos pessoais |
| 8.6 | Code review | Não se aplica (dev único) |

---

## 9. Segurança, dados sensíveis e LGPD

| # | Pergunta | Resposta |
|---|---|---|
| 9.1 💰 | Dado pessoal sensível | Possivelmente: humor/energia pode contar como dado de saúde (LGPD art. 5º, II). Decisão adiada (risco 8) |
| 9.2 | Política de privacidade | Adiada (risco 8); obrigatória pela LGPD com cadastro aberto, mesmo sem loja |
| 9.3 | Consentimento | Só a permissão de notificação do sistema (Android 13+: `POST_NOTIFICATIONS`; iOS: notificações + Live Activities). Negada → faixa no app a cada start com atalho para os Ajustes do sistema |
| 9.4 | Exclusão de conta | Adiada (risco 8); direito do titular pela LGPD |
| 9.5 | Criptografia | Padrão do Firebase |
| 9.6 | Pinning / ofuscação | Não |
| 9.7 | Retenção de log | Não se aplica |
| 9.8 | Compliance | Não se aplica |

Regras do Firestore isolam os dados por `uid` (`firestore.rules`).

---

## 10. Pessoas e comunicação

| # | Pergunta | Resposta |
|---|---|---|
| 10.1 ⛔ | Dono técnico | Leandro |
| 10.2 ⛔ | Canal de comunicação | Não se aplica |
| 10.3 | Quem aprova entregas | Leandro |
| 10.4 | Dúvida de API | Não se aplica |
| 10.5 | Cadência de reunião | Não se aplica |
| 10.6 | Onde ficam as tarefas | `docs/handoff-time-control.md`, como na v1 |
| 10.7 | Quem assume depois | Leandro |

---

## 11. Riscos técnicos identificados

| # | Risco | Impacto | Mitigação | Dono |
|---|---|---|---|---|
| 1 | Apple ID gratuito: app expira a cada 7 dias; a extensão de widget (Live Activity) pode não ser aceita | Alto no iOS | Validar com um protótipo mínimo antes de implementar; se falhar, avaliar a conta paga | Leandro |
| 2 | Live Activity não abre diálogo: "parar com confirmação" não cabe direto na tela bloqueada | Médio | Decidido: 2 toques nas duas plataformas — "parar" vira "confirmar" por 5 s e volta sozinho (estado na notificação/Live Activity) | Leandro |
| 3 | Android: a economia de bateria da fabricante pode encerrar o serviço em primeiro plano | Médio | Foreground service com tipo declarado; testar no aparelho real | Leandro |
| 4 | Login web → nativo pode exigir reconfigurar o provedor (SHA-1, URL scheme) | Médio | Configurar SHA-1 (da keystore de 6.3) e URL scheme ao criar os alvos nativos | Leandro |
| 5 | Botões pausar/parar com o app encerrado precisam gravar no Firestore sem o Flutter rodando | Alto | SDK nativo do Firebase no código da plataforma ou isolate Dart em segundo plano; decidir no protótipo da pendência 4 | Leandro |
| 6 | Ação na tela bloqueada sem internet (app "sempre online") | Baixo | O SDK do Firestore enfileira a escrita e envia ao reconectar; aceitar | Leandro |
| 7 | Limite de 8 h da Live Activity (iOS) não cobre o caso real | 9 | PWA sem crash reporting (Crashlytics não tem versão web) | Baixo | Aceito: o uso principal é o nativo; no web, erro só no console do navegador | Leandro |
de 24 h | Médio | Aceito. O aviso de estouro (desejável) só cobre tarefa com estimado; sem estimado e compromisso ficam sem rede após 8 h — também aceito | Leandro |
| 8 | Cadastro aberto + dados de terceiros (inclusive humor/energia) sem política de privacidade, exclusão de conta nem consentimento — LGPD | Alto se o app for divulgado | Decidir antes de divulgar o app a outras pessoas | Leandro |

---

## 12. Decisões congeladas

| # | Decisão | Data | Quem decidiu |
|---|---|---|---|
| 1 | Flutter nativo (alvos `android/` e `ios/` no mesmo projeto) | 07/10/2026 | Leandro |
| 2 | PWA mantido junto com Android e iOS (mesmo código) | 07/10/2026 | Leandro |
| 3 | Instalação direta, sem lojas | 07/10/2026 | Leandro |
| 4 | Mínimo iOS 17 e Android 13 (API 33) | 07/10/2026 | Leandro |
| 5 | Bundle id `br.com.tekton.meutempo` | 07/10/2026 | Leandro |
| 6 | Login Google mantido, adaptado ao nativo | 07/10/2026 | Leandro |
| 7 | Crash reporting com Firebase Crashlytics, só no nativo (substitui o Sentry) | 07/10/2026 | Leandro |
| 8 | Limite de 8 h da Live Activity aceito | 07/10/2026 | Leandro |
| 9 | Dois aparelhos: reconciliar a tela bloqueada ao abrir o app | 07/10/2026 | Leandro |
| 10 | Vários usuários, cadastro aberto a qualquer conta Google | 07/10/2026 | Leandro |

---

## 13. Pendências que bloqueiam o início

| # | Pendência | Responsável | Prazo | Status |
|---|---|---|---|---|
| 1 | Método de login atual e configuração nativa | Leandro | Antes do início | Resolvida: Google (ver 2.2); falta só a configuração (SHA-1 e URL scheme) na implementação |
| 2 | Bundle id / application id | Leandro | Antes do início | Resolvida: `br.com.tekton.meutempo` |
| 3 | Atualizar `CLAUDE.md` e `docs/requisitos-time-control.md` (passa a ser Web + Android + iOS) | Leandro | Primeiro passo da implementação | Resolvida em 07/10/2026 |
| 4 | Validar os riscos 1 (Apple ID gratuito + extensão) e 5 (gravar no Firestore com o app encerrado) | Leandro | Antes do início | Aberta: protótipo mínimo com Live Activity instalado pelo Xcode no iPhone e botão que grava no Firestore com o app encerrado; se o risco 1 falhar, decidir sobre a conta paga |
