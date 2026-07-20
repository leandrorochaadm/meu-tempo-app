# Architecture — Clean Architecture (feature-first)

## 🛑 Regra de negócio SEMPRE em `domain` (MANDATÓRIA)

Toda regra de negócio — validação, cálculo, agregação, decisão de fluxo, condição
"pode/não pode" — **DEVE** morar em `domain` (Entity, UseCase ou contrato de Repository).
**NUNCA** na `presentation` (Bloc, State, Page): lá só vivem orquestração de UI,
formatação de exibição e tradução de `Failure` → estado.

- Regra **intrínseca ao objeto** → getter na `Entity` (ex.: `isFolha`, `prioridade`).
- Regra de **fluxo / cálculo / "pode fazer X" / combinar dados** → `UseCase`.
- Se pedirem regra de negócio na `presentation`, **PARE e confronte** antes de implementar.

**Defesa primária (design) — o dado chega PRONTO na `presentation`:**
A melhor forma de não haver regra de negócio na UI é a UI **não ter o que calcular**.
Toda agregação/decisão já vem resolvida antes de chegar lá:
- Cálculo intrínseco → **getter na Entity** (ex.: `totalEstimatedMinutes`, `progresso`,
  `prioridade`). A UI só exibe: `Text('${tarefa.totalEstimatedMinutes} min')`.
- Cálculo que cruza dados / decisão de fluxo → **UseCase**; o Bloc recebe o resultado
  pronto e o traduz em State.
- Assim a `presentation` nunca recebe coleção crua para somar/reduzir — some a tentação,
  sem depender de fiscal. Os itens abaixo são **rede de segurança**, não a defesa principal.

**Travas automáticas** (rede de segurança — não dependem de disciplina):
- **Hook** `PreToolUse` (`.claude/hooks/block_business_logic_in_presentation.py`) —
  bloqueia na hora da escrita qualquer `Write`/`Edit` que introduza agregação/cálculo
  (`fold<num>`, `reduce`, `.sum`, `.average`, acúmulo manual `+= x.campo`, e
  decisão de negócio `.importancia|prioridade|nivel|urgencia ==`) em
  `lib/features/*/presentation/`. Escape hatch por linha: `// ignore: business-logic`.
- **Teste** `test/architecture/presentation_no_business_logic_test.dart` — mesmos
  padrões; falha no `flutter test`/CI se algo passar batido pelo hook.
- **Cobertura textual, não semântica:** ambos pegam os idiomas comuns de agregação,
  não formas disfarçadas (loop sem `+=`, fórmula inline). Para essas, vale a defesa
  primária acima + revisão consciente.

> Exemplos do Meu Tempo: `prioridade` e `isFolha` são getters na `TarefaEntity`;
> "pausar o cronômetro ativo ao iniciar outro" e "cabe no dia" são UseCases.

## Dependency Rule (INVIOLÁVEL)

```
Presentation → depende de → Domain
Data         → depende de → Domain
Domain       → NÃO DEPENDE DE NADA
```

- `domain/` NUNCA importa nada de `data/` ou `presentation/`.
- `domain/` NUNCA importa pacote externo (firebase, json, etc.) — **Dart puro**.
  Exceções permitidas: `equatable` e `fpdart` (tipos de apoio, não infraestrutura).

## Data Flow

```
UI (input do usuário)
    ↓ dispara Event no Bloc
Bloc (event → state)
    ↓ monta Params, chama UseCase
UseCase (Params)
    ↓ chama Repository (contrato no Domain)
RepositoryImpl (Data)
    ↓ chama DataSource com Model
DataSource
    ↓ lê/escreve no Firestore (Map <-> Model)
Firebase
```

## Layer Type Rules

| Camada | Usa | Recebe | Retorna | Pode importar |
|--------|-----|--------|---------|---------------|
| Presentation | Entity | Entity | Entity | Domain |
| Domain | Entity | Entity | Entity | Nada (+ equatable/fpdart) |
| Repository | Ambos* | Model | Entity | Domain |
| DataSource | Model | Map (Firestore) | Model | Nada |

*RepositoryImpl recebe Model do DataSource e converte para Entity antes de retornar.

## Error Handling por camada

| Camada | Trata | Como |
|--------|-------|------|
| Entity | Regras intrínsecas | Getters booleanos/derivados |
| UseCase | Regras de fluxo; transforma erro de infra em domínio | Retorna `Left(Failure)` |
| Repository | Erros de I/O (Firestore, rede, parse) | try/catch → `Left(Failure)` |
| Bloc | Nenhuma regra. Traduz Failure → State | `fold` → estado de erro |
| UI | Exibe estado | `switch` exaustivo |

## Anti-Patterns (NUNCA fazer)

| Anti-pattern | Por quê é errado |
|---|---|
| `class TarefaModel extends TarefaEntity` | Acopla Domain com Data |
| Anotação de serialização na Entity | Entity não conhece Firestore/JSON |
| `copyWith()` na Entity | Entity é imutável — construir novo objeto |
| `final List<X> items;` sem unmodifiable | `final` protege referência, não conteúdo |
| Regra de negócio no Bloc | Pertence ao UseCase ou Entity |
| `Either` no State | Either morre no Bloc — State recebe dado resolvido |
| Bloc chamando DataSource/Firestore direto | Pula UseCase e Repository |
| Mensagem de texto na Failure | Failure carrega dados, não strings de UI |
| Import cruzado entre features | Comunicar via `core/` ou contrato compartilhado |
| Classe sem sufixo arquitetural | O sufixo torna o papel imediato |
| `context.read()` de Bloc no `build()` para renderizar | Usar `BlocBuilder`/`context.watch()` |

## Checklist de criação de feature (nesta ordem)

1. **Domain** — Entity (`Entity`, sem `copyWith`, coleções unmodifiable), Failures
   (dados, não mensagens), contrato Repository, Params, UseCase (`call()`).
2. **Data** — Model (`toEntity()`/`fromEntity()`, `json_serializable`
   `fromJson`/`toJson` + `fromDoc`, nunca extends Entity), DataSource (Firestore),
   RepositoryImpl (try/catch → `Either`).
3. **Presentation** — Event, State (sealed + Equatable), Bloc (`_mapFailure` no `catch`),
   Page (`BlocBuilder` + `switch`), widgets.
4. **Validação** — rodar `flutter analyze` (zero issues) e a checklist de anti-patterns.

## Referência rápida

| O que preciso fazer? | Onde fica? |
|---|---|
| Validar se objeto está válido | Entity (getter bool) |
| Calcular prioridade / tempo somado | Entity (getter) ou UseCase (se cruza dados) |
| Ler/gravar no Firestore | DataSource → RepositoryImpl |
| Verificar se "cabe no dia" | UseCase |
| Pausar cronômetro ativo ao iniciar outro | UseCase |
| Converter Failure em mensagem | Bloc (`_mapFailure`) |
| Formatar hora/duração | UI (formatter) |
| Serializar para Firestore | Model (`json_serializable`: `toJson`/`fromJson`/`fromDoc`) |
