---
paths:
  - "lib/**/*.dart"
---

# Logging Rules

## NUNCA usar `print()` ou `debugPrint()` — SEMPRE um logger central

Criar `lib/core/logging/` com um `AppLogger` (ou `LoggerMixin`) e usar em todo lugar.
Motivo: `print` não tem nível, tag nem controle por ambiente; polui o console do PWA.

### Níveis

| Método | Usar para |
|--------|-----------|
| `logDebug(msg)` | Info de desenvolvimento/depuração |
| `logInfo(msg)` | Mudanças de estado importantes, marcos |
| `logWarning(msg)` | Problemas potenciais que não param a execução |
| `logError(msg, {error, stackTrace})` | Erros reais que precisam de atenção |

### Onde logar

- **RepositoryImpl**: logar `error`+`stackTrace` no `catch` antes de virar `Left(Failure)`.
- **Bloc**: opcional logar transições relevantes; não logar dado sensível do usuário.
- **DataSource**: logar a origem do erro do Firestore (code) para diagnóstico.
