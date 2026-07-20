---
paths:
  - "lib/features/*/presentation/**"
  - "lib/core/ui/**"
  - "lib/core/theme/**"
---

# Design System — Identidade Visual (Meu Tempo)

Objetivo: visual **moderno, premium e com personalidade** — que **não pareça template
nem "gerado por IA"**. Regras de estrutura/fricção estão em `layout.md`; aqui é a
**identidade** (cor, tipografia, superfície, movimento). Tokens vivem em
`lib/core/theme/` e **nunca** hard-coded na UI (regra `enums.md` vale para cores/raios também).

## Direção (decidida com o cliente)
- **Tema escuro único** (sem tema claro na v1) — combina com o ritual noturno do app.
- **Superfície soft/arredondada:** cantos 16–20px, sombras **sutis e difusas** (não
  sombra pesada de card padrão), superfícies levemente elevadas por cor.
- **Cor rica e categórica** (não monocromático): uma paleta de acentos usada para dar
  significado — cada lista, estado e nível de importância tem sua cor.

## Tokens de cor (`lib/core/theme/app_colors.dart`)

Neutros (base escura, levemente fria):
```
bgBase        #101216   // fundo do app
surface       #181B21   // cards, sheets
surfaceHigh   #212530   // elevado (input, item ativo)
border        #2A2F3A   // divisórias 1px
textPrimary   #ECEEF3
textSecondary #A2A9B8
textMuted      #6B7280
```

Acento principal (ações primárias, foco, cronômetro parado):
```
primary       #7C8CF8   // periwinkle/índigo — não é o roxo padrão do Material
onPrimary     #0F1220
```

**Paleta categórica** (cor por lista/tag/série de gráfico — dá a variação que faltava):
```
indigo #7C8CF8 · teal #4FD1C5 · green #5FD0A0 · amber #F5B84E
coral  #FB7185 · violet #B98CF0 · sky   #56C7E0 · rose  #F472B6
```
Listas recebem uma cor dessa paleta (round-robin ou escolha do usuário depois);
os relatórios usam a mesma paleta para as séries — consistência entre tela e gráfico.

Semânticas:
```
success #4ADE80 · warning #FBBF24 · danger #F87171 · info #60A5FA
```

**Importância → cor** (semântica de urgência). O mapa vive na **camada de tema**
(ex.: `context.colors.forImportance(e)`) — o `ImportanceEnum` é domain (Dart puro) e
**não** carrega `Color`:
```
max (1) #F87171 (danger) · high (2) #FBBF24 (amber)
low (3) #60A5FA (info)   · min  (4) #6B7280 (muted)
```

**Cronômetro ativo:** teal `#4FD1C5` com leve glow/pulso — estado "vivo" bem visível.

## Escala de espaçamento e raio (tokens, não números mágicos)
```
space: 4 · 8 · 12 · 16 · 20 · 24 · 32
radius: sm 10 · md 16 · lg 20 · pill 999
```
Cards/sheets usam `radius.lg` (20). Chips e botões usam `pill`. Padding generoso
(mín. 16 nas bordas de tela).

## Tipografia (`lib/core/theme/app_typography.dart`)
- Família com personalidade (geométrica humanista), **empacotada como asset em
  `assets/fonts/`** e declarada no `pubspec.yaml`: sugestão **Manrope** (ou Sora para
  display). Fallback: system.
- **PROIBIDO `google_fonts`** (ou qualquer fetch de fonte em runtime). A fonte é asset
  local — sem dependência de rede, sem FOUT.
- Hierarquia forte (o que mais afasta do "cara de template"):
  - `display` 28/700 · `headline` 22/700 · `title` 17/600 · `body` 15/400 ·
    `label` 13/600 · `caption` 12/500.
  - Headings com `letterSpacing` levemente negativo (-0.3 a -0.5); body neutro.
- Números (tempo, cronômetro) com `fontFeatures: [FontFeature.tabularFigures()]` —
  dígitos alinhados, cara de app de tempo sério.

## Movimento (micro-interações)
- Durações 150–250ms, curva `Curves.easeOutCubic`.
- Tap: leve `scale`/opacidade no toque (feedback tátil visual).
- Transição de página: fade + slide curto (não o slide padrão bruto).
- Cronômetro: pulso suave; skeleton com shimmer; undo via snackbar animado.
- Sem exagero — movimento serve à percepção de velocidade, não decoração.

## Ícones
- **Material Symbols Rounded** (`Icons.*_rounded`) — coeso e menos genérico que o sharp
  padrão. **Nunca emoji como ícone de UI.**

## O que EVITA a "cara de IA" (do / don't)
| ✅ Faça | ❌ Evite |
|---|---|
| Seed/paleta custom (índigo + categórica) | `ColorScheme.fromSeed(Colors.deepPurple)` padrão |
| Hierarquia tipográfica forte, alinhada à esquerda | Tudo centralizado, um tamanho de fonte só |
| Sombra sutil difusa + superfície por cor | Card com `elevation` alta e sombra dura |
| Empty-state com 1 ícone/ilustração sóbria + texto útil | Emoji gigante + "Nada aqui 🎉" |
| Espaçamento 8pt consistente, respiro | Widgets colados, padding aleatório |
| Cor com significado (lista/estado/importância) | Cinza monocromático sem variação |
| Ícones rounded coerentes | Mix de emojis e ícones aleatórios |
| Gradiente sutil e pontual (1 CTA) | Gradientes por toda parte |

## Centralização no `core` + acesso via `context` (OBRIGATÓRIO)

**Tudo de UI é centralizado em `lib/core/`.** As telas (`features/*/presentation`)
**consomem** os tokens/componentes pelo `context` — nunca declaram valores próprios.

- **Tokens de design** em `lib/core/theme/` (cores, espaços, raios, tipografia, durações),
  expostos via `ThemeData` + `ThemeExtension`. A tela lê **só** do `context`:
  `Theme.of(context).colorScheme...`, `context.colors.teal`, `context.space.md`,
  `context.text.title` (extensões sobre `BuildContext`).
- **Componentes/widgets compartilhados** (botões, chips, empty-state, snackbar de undo,
  skeleton, card base) em `lib/core/ui/`. A feature reusa; **não** recria estilo local.
- **Formatadores** (data, hora, duração, número) centralizados em
  `lib/core/utils/formatters/` (ex.: `DurationFormatter.hm(minutes)`,
  `DateFormatter.short(d)`), usando o pacote `intl` (`DateFormat`, locale pt-BR).
  Formatação de data/duração **não** é regra de negócio — mas também **não** pode ser
  literal espalhada na tela.

### PROIBIDO formatação hard-coded na `presentation`
| ❌ Proibido (literal na tela) | ✅ Obrigatório (via core/context) |
|---|---|
| `Color(0xFF7C8CF8)` / `Colors.indigo` | `context.colors.primary` (token do tema) |
| `TextStyle(fontSize: 17, ...)` | `context.text.title` (`Theme.of(context).textTheme...`) |
| `EdgeInsets.all(16)` / `SizedBox(height: 20)` | `context.space.md` / `context.space.lg` |
| `BorderRadius.circular(20)` | `context.radius.lg` |
| `Duration(milliseconds: 200)` (animação) | `context.motion.fast` |
| `'${d.day}/${d.month}'` inline | `DateFormatter.short(d)` (core) |
| `TextStyle`/cor definidos dentro do widget da feature | Componente de `lib/core/ui/` ou token do tema |

> Regra prática: se você digitou um número/hex/`TextStyle` dentro de
> `features/*/presentation`, está errado — vem do `core` via `context`. Sem exceção.

## Regras técnicas
- Tokens em `lib/core/theme/` (`app_colors.dart`, `app_spacing.dart`, `app_radius.dart`,
  `app_typography.dart`, `app_motion.dart`) expostos via `ThemeData`/`ThemeExtension`.
- `MaterialApp(themeMode: ThemeMode.dark, darkTheme: AppTheme.dark)`; **não** definir
  `theme` claro (v1 é escuro-único).
- Contraste mínimo AA (texto ≥ 4.5:1 sobre o fundo) — validar os acentos sobre `bgBase`.
