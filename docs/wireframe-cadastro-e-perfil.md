# Wireframe — Criar conta e trocar senha

Esboço das telas dos req. 16 (Criar conta) e 17 (Editar o perfil, parte de trocar senha).
Mostra a disposição dos elementos e o comportamento; cores, fontes e espaçamentos seguem o
tema do app (`.claude/rules/design.md`). Regras e cenários: `specs/sign_up.md` e
`specs/profile.md`.

Legenda: `✓` critério atendido (verde) · `○` critério pendente (cinza) · `⚠` aviso do
campo · `[ botão ]` ativo · `[ ░░░ ]` desativado.

## 1. Tela de entrada

Muda só o rodapé: o texto "Sem conta? Fale com quem cuida do app." vira o link para criar
conta.

```
┌──────────────────────────────┐
│                              │
│  Meu Tempo                   │
│  Seu Bullet Journal digital  │
│  com cronômetro por tarefa.  │
│                              │
│  ┌────────────────────────┐  │
│  │ E-mail                 │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │ Senha               👁  │  │
│  └────────────────────────┘  │
│                              │
│  [         Entrar         ]  │
│                              │
│   Não tem conta? Criar conta │  ← link
└──────────────────────────────┘
```

## 2. Criar conta — ao abrir

Caixa da política desmarcada, checklist todo cinza e botão desativado (REQ-004, REQ-012).

```
┌──────────────────────────────┐
│ ←  Criar conta               │
│                              │
│  ┌────────────────────────┐  │
│  │ Nome                   │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │ E-mail                 │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │ Senha               👁  │  │
│  └────────────────────────┘  │
│   ○ Pelo menos 8 caracteres  │
│   ○ Pelo menos 1 número      │
│   ○ Pelo menos 1 letra       │
│     maiúscula                │
│   ○ Pelo menos 1 letra       │
│     minúscula                │
│                              │
│  ☐ Li e aceito a política    │
│    de privacidade            │  ← "política de privacidade" é link
│                              │
│  [ ░░░░░ Criar conta ░░░░░ ] │  ← desativado
│                              │
│   Já tem conta? Entrar       │
└──────────────────────────────┘
```

## 3. Criar conta — digitando a senha

Cada critério fica verde a cada letra digitada. Com "abcd1234" falta a maiúscula, então o
botão continua desativado, mesmo com os outros campos certos (REQ-003, REQ-012).

```
┌──────────────────────────────┐
│ ←  Criar conta               │
│                              │
│  ┌────────────────────────┐  │
│  │ Nome          Ana      │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │ E-mail ana@exemplo.com │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │ Senha     abcd1234  👁  │  │
│  └────────────────────────┘  │
│   ✓ Pelo menos 8 caracteres  │
│   ✓ Pelo menos 1 número      │
│   ○ Pelo menos 1 letra       │  ← falta
│     maiúscula                │
│   ✓ Pelo menos 1 letra       │
│     minúscula                │
│                              │
│  ☑ Li e aceito a política    │
│    de privacidade            │
│                              │
│  [ ░░░░░ Criar conta ░░░░░ ] │  ← desativado
└──────────────────────────────┘
```

## 4. Criar conta — tudo certo

Com "Abcd1234" os 4 critérios ficam verdes; com nome, e-mail e aceite certos, o botão ativa.

```
│  ┌────────────────────────┐  │
│  │ Senha     Abcd1234  👁  │  │
│  └────────────────────────┘  │
│   ✓ Pelo menos 8 caracteres  │
│   ✓ Pelo menos 1 número      │
│   ✓ Pelo menos 1 letra       │
│     maiúscula                │
│   ✓ Pelo menos 1 letra       │
│     minúscula                │
│                              │
│  ☑ Li e aceito a política    │
│    de privacidade            │
│                              │
│  [       Criar conta       ] │  ← ativo
```

## 5. Criar conta — avisos de nome e e-mail

O aviso aparece quando a pessoa sai do campo, não enquanto digita. Vários avisos ficam
visíveis ao mesmo tempo (REQ-002, REQ-010, REQ-011, REQ-012). Senha acima de 71 caracteres
mostra "Use no máximo 71 caracteres." abaixo do campo.

```
┌──────────────────────────────┐
│ ←  Criar conta               │
│                              │
│  ┌────────────────────────┐  │
│  │ Nome          A        │  │
│  └────────────────────────┘  │
│  ⚠ Use de 2 a 50 caracteres. │
│  ┌────────────────────────┐  │
│  │ E-mail        ana@     │  │
│  └────────────────────────┘  │
│  ⚠ Confira o e-mail.         │
│            ...               │
│  [ ░░░░░ Criar conta ░░░░░ ] │  ← desativado
└──────────────────────────────┘
```

## 6. Criar conta — erro vindo do servidor

Os campos estavam certos, mas o servidor recusou (REQ-005, REQ-011).

```
┌──────────────────────────────┐
│ ←  Criar conta               │
│  ┌────────────────────────┐  │
│  │ E-mail ana@exemplo.com │  │
│  └────────────────────────┘  │
│  ⚠ Este e-mail já tem conta. │
│    Entre com ele.            │
│            ...               │
├──────────────────────────────┤
│ Sem internet. Tente de novo. │  ← barra de aviso (sem internet)
└──────────────────────────────┘
```

Falha do servidor: "Não foi possível criar a conta. Tente de novo."

## 7. Depois de criar a conta

Entra direto, sem confirmar o e-mail, no primeiro acesso guiado: lista "Entrada" com a
tarefa de exemplo (REQ-001, req. 13).

```
┌──────────────────────────────┐
│  Entrada                  ⚙  │
│                              │
│  ┌────────────────────────┐  │
│  │ ▶  Bem-vindo! Toque no │  │
│  │    ▶ para cronometrar  │  │
│  │    esta tarefa         │  │
│  │    Hoje · 30 min       │  │
│  └────────────────────────┘  │
│                              │
│                       ┌───┐  │
│                       │ + │  │
│                       └───┘  │
└──────────────────────────────┘
```

## 8. Perfil — trocar senha

A senha nova usa o mesmo checklist do cadastro. O botão só ativa com a senha atual
preenchida e a nova atendendo aos 4 critérios e diferente da atual (REQ-008, REQ-012).
Quem tem senha antiga fora das regras continua entrando; a regra vale só para a nova.

```
┌──────────────────────────────┐
│ ←  Configurações             │
│  Perfil                      │
│            ...               │
│  Trocar senha                │
│  ┌────────────────────────┐  │
│  │ Senha atual ••••••• 👁  │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │ Senha nova  ••••••• 👁  │  │
│  └────────────────────────┘  │
│   ✓ Pelo menos 8 caracteres  │
│   ✓ Pelo menos 1 número      │
│   ✓ Pelo menos 1 letra       │
│     maiúscula                │
│   ✓ Pelo menos 1 letra       │
│     minúscula                │
│                              │
│  [      Trocar senha       ] │  ← ativo
└──────────────────────────────┘
```

Senha nova igual à atual: botão desativado e o aviso "É igual à senha atual." abaixo do
campo.

## Textos dos avisos

Sugestão de texto para cada Erro de campo (`AccountFieldErrorEnum`), na tela:

| Erro de campo | Texto na tela |
|---|---|
| `displayNameLength` | Use de 2 a 50 caracteres. |
| `sameDisplayName` | Esse já é o seu nome. |
| `invalidEmail` | Confira o e-mail. |
| `sameEmail` | Esse já é o seu e-mail. |
| `passwordTooShort` | Pelo menos 8 caracteres (item do checklist) |
| `passwordMissingDigit` | Pelo menos 1 número (item do checklist) |
| `passwordMissingUppercase` | Pelo menos 1 letra maiúscula (item do checklist) |
| `passwordMissingLowercase` | Pelo menos 1 letra minúscula (item do checklist) |
| `passwordTooLong` | Use no máximo 71 caracteres. |
| `samePassword` | É igual à senha atual. |
| `privacyPolicyNotAccepted` | Marque para continuar. |
| `EmailAlreadyInUseFailure` | Este e-mail já tem conta. Entre com ele. |
| `WrongCurrentPasswordFailure` | Senha atual incorreta. |
| `NetworkFailure` | Sem internet. Tente de novo. |
| `ServerFailure` | Não foi possível salvar. Tente de novo. |
