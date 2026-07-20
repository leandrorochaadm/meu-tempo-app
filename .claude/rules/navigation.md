---
paths:
  - "lib/features/*/presentation/**"
  - "lib/core/router/**"
---

# Navigation Rules (`go_router` + BLoC)

Navegação pertence **exclusivamente** à Presentation. Domain e Data NUNCA navegam.
Como é **Flutter Web/PWA**, `go_router` é obrigatório (URL, deep link, botão voltar do
navegador). O Bloc **atualiza estado**; o widget **reage e navega**.

```
Bloc → emite estado → BlocListener detecta → context.go/push
UseCase / Repository → NUNCA navegam
```

## Métodos

| Método | Stack | URL Web | Caso de uso |
|--------|-------|---------|-------------|
| `context.go()` | Reconstrói | Atualiza | Troca de contexto (login → home), redirects |
| `context.push()` | Empilha | Não atualiza | Detalhe, modal, sub-tela (voltar relevante) |
| `context.pushReplacement()` | Substitui topo | Não atualiza | Wizard/multi-step |
| `context.pop()` | Remove topo | — | Voltar (checar `context.canPop()` antes) |

## Navegação reativa com BLoC (padrão)

Usar `BlocListener` para side-effect de navegação — nunca navegar dentro do Bloc.

```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthAuthenticated) context.go(AppRoutes.home);
    if (state is AuthUnauthenticated) context.go(AppRoutes.login);
  },
  child: ...,
);
```

## Guards de autenticação (redirect global)

O `redirect` do `GoRouter` protege rotas. Ponte entre o `AuthBloc` e o
`refreshListenable` via um `Listenable` que dispara no stream do bloc.

```dart
GoRouter(
  refreshListenable: authRefresh,        // notifica ao mudar auth
  redirect: (context, state) {
    final loggedIn = authBloc.state is AuthAuthenticated;
    final onLogin = state.matchedLocation == AppRoutes.login;
    if (!loggedIn && !onLogin) return AppRoutes.login;
    if (loggedIn && onLogin) return AppRoutes.home;
    return null;
  },
);
```

Condições de redirect **mutuamente exclusivas** (o `redirectLimit` padrão é 5 — loop
infinito derruba o app).

## Regras

- **NUNCA** hardcodar path. Centralizar em `AppRoutes` (`lib/core/router/app_routes.dart`).
- **NUNCA** `Navigator.push(MaterialPageRoute(...))` para rotas — usar `go_router`.
  Exceção: `Navigator.pop()` para fechar dialog/bottom sheet é aceitável.
- **NUNCA** lógica de negócio na definição de rota — o router só roteia.
- **NUNCA** criar `GoRouter` dentro do `build()` — instância única (via DI/topo da árvore).
- `state.extra` **não sobrevive a refresh de página no web** — sempre ter fallback por id.
- Verificar `mounted` antes de navegar após operação async.

## Memory leaks

`ScrollController`, `TextEditingController`, `AnimationController`, `StreamSubscription`,
`Timer` e `addListener` → disposed/cancelados no `dispose()`/`close()`.
