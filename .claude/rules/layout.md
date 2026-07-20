---
paths:
  - "lib/features/*/presentation/**"
  - "lib/core/ui/**"
---

# Layout Rules (mobile-first / PWA de celular)

O Meu Tempo roda como **PWA em celular** — tela pequena, toque, uma coluna. **Nunca**
desenhar layout de desktop. Projetar sempre para viewport estreito primeiro.

## Posicionamento flexível

- Sem valores fixos de posição — o layout se ajusta sozinho.
- Usar `Spacer`, `Expanded`, `Flexible` em vez de `top`/`bottom` fixos.
- `SafeArea` para respeitar áreas seguras do dispositivo.
- Conteúdo rolável em `SingleChildScrollView`/`ListView` — nunca deixar overflow vertical.
- Alvos de toque grandes (mín. ~48dp) — é uso com o dedo, não mouse.

## Seleção de opções — SEMPRE chip, NUNCA dropdown

Para escolher entre opções (lista/categoria, importância, filtro, etc.), **SEMPRE**
`ChoiceChip`/`FilterChip` num `Wrap` — **NUNCA** `DropdownButton`. Chip deixa tudo
visível e resolve em **1 toque** (sem abrir menu), reduzindo fricção — diretriz central
do produto (ver Requisito 12/13 em `docs/`).

Regras de fricção (menos toques no caso comum):
- **0 opções** → não renderiza o seletor (usa o destino implícito, ex.: lista "Entrada").
- **1 opção** → seleciona automaticamente (chip já marcado, sem exigir toque).
- **2+ opções** → exibe chips; pré-marca a sugestão/última usada quando confiável.

`selected: true` no `ChoiceChip` já dá o estado visual — não criar widget novo.
**Exceção:** listas grandes (10+) podem usar busca/seleção — avaliar caso a caso.

## Padrões de UX sem fricção (do produto)

- Criação rápida: só o título já cria a tarefa com padrões (imp. 4, hoje, 30 min, "Entrada").
- Cronômetro em 1 toque direto na listagem, sem abrir a tarefa.
- Atalhos de tempo (+15 / +30 min) no registro manual.
- Telas vazias **ensinam o próximo passo** em vez de ficar em branco.
- Ações destrutivas (excluir/concluir/migrar) têm **desfazer**.

## Nomenclatura de UI (não trocar)

Manter "**tarefa mãe / filha / neta**" nas telas (decisão do cliente).

## Imports

- Imports relativos dentro da feature: `import '../../domain/entities/task_entity.dart';`
