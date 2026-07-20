# Diagramas de Fluxo — Meu Tempo · Gerenciador de Tarefas (v1)

_Gerado a partir de `requisitos-time-control.md` (aprovado em 2026-07-19). Apenas
fluxogramas dos casos de uso com lógica de decisão._

---

## Cenários e Critérios de Aceite (fonte: requisitos aprovados)

> IDs estáveis usados como referência em todos os fluxos abaixo. Os critérios são
> os "pronto quando" do documento de requisitos.

### Cenários

| ID | Cenário | Descrição (do documento) |
|----|---------|--------------------------|
| `CEN-01` | Criar tarefa em 3 níveis | "Tarefas em 3 níveis (mãe → filha → neta); campos e cronômetro só na folha; mãe/avó herdam a soma" |
| `CEN-02` | Registrar tempo | "Cronômetro (só folha/compromisso) e manual; 1 ativo por vez com pausa automática; tempo acumula na mãe/avó" |
| `CEN-03` | Migração de pendências | "No dia seguinte, o app mostra as tarefas não feitas para migrar ou descartar" |
| `CEN-04` | Cabe no dia | "Avisar se a soma das durações estimadas (tarefas + compromissos) passa das horas disponíveis" |
| `CEN-06` | Listagem por prioridade | "Lista plana só das folhas, ordenada por tempoEstimado × (5 − importância) × urgênciaDoPrazo" |
| `CEN-10` | Conclusão e progresso | "Concluir folha; mãe conclui sozinha quando todas as filhas terminam; barra de progresso" |
| `CEN-11` | Editar, excluir e mover | "Editar campos; excluir em cascata com confirmação; mover na hierarquia reatribui o tempo" |
| `CEN-12` | Criação rápida (sem fricção) | "Criar só com o título; nasce com valores padrão e já entra na listagem" |
| `CEN-13` | Desfazer (usuário leigo) | "Após concluir, excluir ou migrar, oferecer desfazer para reverter" |
| `CEN-14` | Agenda e compromissos | "Compromisso com hora de início + duração; agenda do dia; ocupa o cabe-no-dia; lista; cronômetro" |

### Critérios de Aceite

| ID | Cenário | Critério de Aceite (do documento) |
|----|---------|-----------------------------------|
| `CA-01` | `CEN-01` | "Crio mãe → filha → neta e só na neta (folha) informo tempo estimado, data e importância" |
| `CA-01b` | `CEN-01` | "A mãe e a avó herdam a soma dos tempos das folhas (calculado, não digitado)" |
| `CA-02` | `CEN-02` | "Dou start numa folha; ao dar start em outra, a primeira pausa sozinha; o tempo soma na mãe e na avó" |
| `CA-02b` | `CEN-02` | "Consigo digitar o tempo manualmente (ex.: 1h30) numa folha" |
| `CA-03` | `CEN-03` | "Deixo uma tarefa sem concluir hoje e amanhã o app pergunta migrar ou descartar" |
| `CA-04` | `CEN-04` | "Defino 8h disponíveis; ao planejar 9h entre tarefas e compromissos, o app avisa que passou" |
| `CA-06` | `CEN-06` | "Importante(1) de 2h vencendo hoje pontua 48 e fica acima da mesma vencendo em 4 dias (32)" |
| `CA-06b` | `CEN-06` | "Cada folha exibe subtítulo com a mãe e a avó" |
| `CA-10a` | `CEN-10` | "Marco uma folha como feita e ela sai da listagem de prioridade" |
| `CA-10b` | `CEN-10` | "Marco as 5 folhas de uma mãe e a mãe fica concluída sozinha (barra 100%); 3 de 5 → 60%" |
| `CA-11a` | `CEN-11` | "Mudo a data de uma tarefa e a prioridade dela se recalcula" |
| `CA-11b` | `CEN-11` | "Movo uma neta para virar filha de outra mãe e o tempo passa a acumular na nova mãe" |
| `CA-11c` | `CEN-11` | "Excluo uma tarefa com filhas e o app apaga tudo, pedindo confirmação antes" |
| `CA-12` | `CEN-12` | "Crio uma tarefa só com o título; ela nasce com padrões (imp. 4, hoje, 30min, Entrada) e entra na listagem" |
| `CA-13` | `CEN-13` | "Ao excluir uma tarefa por engano, um desfazer a traz de volta" |
| `CA-14` | `CEN-14` | "Crio 'Reunião hoje 15h, 1h' na lista Profissional; aparece na agenda às 15h, desconta 1h do dia e soma no relatório da lista" |

---

## 1. Diagrama de Fluxo — CriarTarefaUseCase · CEN-01, CEN-12, CEN-13

> Cenário(s): `CEN-01` (criar em 3 níveis), `CEN-12` (criação rápida) — critérios `CA-01`, `CA-01b`, `CA-12`.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B[[Recebe dados da tarefa]]
  B --> C{Título preenchido?}
  C -- Não --> D([❌ TituloVazioFailure]):::error
  C -- Sim --> E{Tem tarefa pai?}

  E -- Não --> F[[Cria como tarefa mãe]]:::process
  E -- Sim --> G{Pai já é neta?}
  G -- Sim --> H([❌ NivelMaximoExcedidoFailure]):::error
  G -- Não --> I[[Cria como filha ou neta]]:::process

  F --> J{Criação rápida só com título?}
  I --> J
  J -- Sim --> K[["Aplica padrões — imp. 4, hoje, 30min, lista Entrada"]]:::process
  J -- Não --> L[[Usa campos informados]]:::process

  K --> M[[Salva tarefa]]:::process
  L --> M
  M --> N{Salvou com sucesso?}
  N -- Não --> O([❌ ServerFailure]):::error
  N -- Sim --> P([✅ Retorna Tarefa]):::success
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Título preenchido? | `TituloVazioFailure` | `CriarTarefaUseCase` (validação de entrada) | — (regra técnica: título é obrigatório mesmo na criação rápida) |
| Tem tarefa pai? | — (desvio, não é erro) | `CriarTarefaUseCase` | `CA-01` |
| Pai já é neta? | `NivelMaximoExcedidoFailure` | `CriarTarefaUseCase` (limite de 3 níveis) | `CA-01` |
| Criação rápida só com título? | — (desvio para padrões) | `CriarTarefaUseCase` | `CA-12` |
| Salvou com sucesso? | `ServerFailure` | `TarefaRepository.criar` (try/catch) | `CA-12` |

---

## 2. Diagrama de Fluxo — IniciarCronometroUseCase · CEN-02

> Cenário(s): `CEN-02` (registrar tempo) — critério `CA-02`.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B[[Recebe alvo do cronômetro]]
  B --> C{Alvo é folha ou compromisso?}
  C -- Não --> D([❌ CronometroEmTarefaComFilhasFailure]):::error
  C -- Sim --> E{Já há cronômetro ativo?}

  E -- Sim --> F[[Pausa o cronômetro ativo e salva o tempo]]:::process
  E -- Não --> G[[Segue sem pausar nada]]:::process

  F --> H[[Inicia cronômetro no novo alvo]]:::process
  G --> H
  H --> I{Iniciou com sucesso?}
  I -- Não --> J([❌ ServerFailure]):::error
  I -- Sim --> K([✅ Cronômetro ativo no alvo]):::success
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Alvo é folha ou compromisso? | `CronometroEmTarefaComFilhasFailure` | `IniciarCronometroUseCase` (só folha/compromisso tem cronômetro) | `CA-02` |
| Já há cronômetro ativo? | — (desvio: pausa o anterior) | `IniciarCronometroUseCase` (estado global "cronômetro ativo") | `CA-02` |
| Iniciou com sucesso? | `ServerFailure` | `TempoRepository.iniciar` (try/catch) | `CA-02` |

---

## 3. Diagrama de Fluxo — RegistrarTempoManualUseCase · CEN-02

> Cenário(s): `CEN-02` (registrar tempo) — critério `CA-02b`.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B[[Recebe alvo e duração informada]]
  B --> C{Alvo é folha ou compromisso?}
  C -- Não --> D([❌ CronometroEmTarefaComFilhasFailure]):::error
  C -- Sim --> E{Duração é positiva?}
  E -- Não --> F([❌ DuracaoInvalidaFailure]):::error
  E -- Sim --> G[[Soma a duração ao tempo do alvo]]:::process
  G --> H([✅ Tempo registrado]):::success
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Alvo é folha ou compromisso? | `CronometroEmTarefaComFilhasFailure` | `RegistrarTempoManualUseCase` | `CA-02b` |
| Duração é positiva? | `DuracaoInvalidaFailure` | `RegistrarTempoManualUseCase` | — (regra técnica: duração manual > 0) |

---

## 4. Diagrama de Fluxo — CalcularPrioridadeUseCase · CEN-06

> Cenário(s): `CEN-06` (listagem por prioridade) — critério `CA-06`.
> Este fluxo calcula a `urgênciaDoPrazo` (faixas) e a prioridade final de cada folha.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B[["Recebe folha com data, importância e tempo"]]
  B --> C{Atrasada ou vence hoje?}
  C -- Sim --> U6[[urgência = 6]]:::process
  C -- Não --> D{Vence em 1 a 2 dias?}
  D -- Sim --> U5[[urgência = 5]]:::process
  D -- Não --> E{Vence em 3 a 5 dias?}
  E -- Sim --> U4[[urgência = 4]]:::process
  E -- Não --> F{Vence em 6 a 9 dias?}
  F -- Sim --> U3[[urgência = 3]]:::process
  F -- Não --> G{Vence em 10 a 14 dias?}
  G -- Sim --> U2[[urgência = 2]]:::process
  G -- Não --> U1[[urgência = 1]]:::process

  U6 --> H
  U5 --> H
  U4 --> H
  U3 --> H
  U2 --> H
  U1 --> H
  H[["prioridade = tempo × (5 − importância) × urgência"]]:::process
  H --> I([✅ Retorna prioridade da folha]):::success
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Faixas de vencimento (hoje…+14 dias) | — (sem erro: define o multiplicador de urgência) | `CalcularPrioridadeUseCase` (função de faixas) | `CA-06` |

> Observação: este fluxo **não tem caminho de erro** — é um cálculo puro em memória
> (sem I/O), portanto é uma **exceção consciente** à regra de "todo fluxo tem um nó
> de erro". A ordenação da lista aplica esta prioridade a cada folha e ordena do
> maior para o menor.

---

## 5. Diagrama de Fluxo — ConcluirTarefaUseCase · CEN-10

> Cenário(s): `CEN-10` (conclusão e progresso) — critérios `CA-10a`, `CA-10b`.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B[[Recebe folha a concluir]]
  B --> C{Alvo é uma folha?}
  C -- Não --> D([❌ SoFolhaConcluiFailure]):::error
  C -- Sim --> E[[Marca folha como feita e remove da listagem]]:::process

  E --> F{Tem tarefa pai?}
  F -- Não --> K([✅ Folha concluída]):::success
  F -- Sim --> G{Todas as filhas do pai estão feitas?}
  G -- Não --> H[[Atualiza barra de progresso do pai]]:::process
  H --> K
  G -- Sim --> I[[Conclui o pai automaticamente]]:::process
  I --> F
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Alvo é uma folha? | `SoFolhaConcluiFailure` | `ConcluirTarefaUseCase` | `CA-10a` |
| Todas as filhas do pai estão feitas? | — (desvio: conclui o pai ou só atualiza progresso) | `ConcluirTarefaUseCase` (sobe recursivamente até a avó) | `CA-10b` |

> A volta de `I` para `F` representa a **subida recursiva**: ao concluir o pai, o
> mesmo teste é aplicado ao avô.

---

## 6. Diagrama de Fluxo — MigrarTarefasUseCase · CEN-03

> Cenário(s): `CEN-03` (migração) — critério `CA-03`.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B[[Busca folhas não concluídas de dias anteriores]]
  B --> B2{Busca teve sucesso?}
  B2 -- Não --> B3([❌ ServerFailure]):::error
  B2 -- Sim --> C{Há pendências?}
  C -- Não --> D([✅ Nada a migrar]):::success
  C -- Sim --> E[[Apresenta pendências uma a uma]]:::process
  E --> F{Decisão do usuário para a pendência}
  F -- Migrar --> G[[Move a tarefa para hoje]]:::process
  F -- Descartar --> H[[Marca como descartada]]:::process
  G --> I{Ainda há pendências?}
  H --> I
  I -- Sim --> E
  I -- Não --> J([✅ Migração concluída]):::success
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Busca teve sucesso? | `ServerFailure` | `TarefaRepository.buscarPendencias` (try/catch) | `CA-03` |
| Há pendências? | — (sem erro: se não houver, encerra) | `MigrarTarefasUseCase` | `CA-03` |
| Decisão do usuário (migrar/descartar) | — (dois desvios válidos) | `MigrarTarefasUseCase` | `CA-03` |

> As saídas "Migrar"/"Descartar" são caminhos válidos escolhidos pelo usuário, não
> erros; o único `Failure` é a falha ao buscar as pendências.

---

## 7. Diagrama de Fluxo — VerificarCabeNoDiaUseCase · CEN-04

> Cenário(s): `CEN-04` (cabe no dia) — critério `CA-04`.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B[[Soma durações estimadas de tarefas e compromissos do dia]]
  B --> C[[Lê horas disponíveis configuradas]]:::process
  C --> D{Soma maior que o disponível?}
  D -- Sim --> E([⚠️ Avisa que passou do dia]):::error
  D -- Não --> F([✅ Cabe no dia]):::success
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Soma maior que o disponível? | Aviso "não cabe no dia" (não bloqueia, só alerta) | `VerificarCabeNoDiaUseCase` | `CA-04` |

> O "erro" aqui é um **aviso**, não um bloqueio: o usuário ainda pode planejar
> além do dia; o app apenas sinaliza.

---

## 8. Diagrama de Fluxo — ExcluirTarefaUseCase · CEN-11

> Cenário(s): `CEN-11` (editar/excluir/mover) — critério `CA-11c`.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B[[Recebe tarefa a excluir]]
  B --> C{Tarefa tem filhas?}
  C -- Não --> G[[Exclui a tarefa]]:::process
  C -- Sim --> D{Usuário confirma exclusão em cascata?}
  D -- Não --> E([❌ ExclusaoCanceladaFailure]):::error
  D -- Sim --> F[[Exclui a tarefa e todas as filhas/netas]]:::process
  F --> H
  G --> H
  H([✅ Excluída - com opção de desfazer]):::success
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Tarefa tem filhas? | — (desvio: com filhas exige confirmação) | `ExcluirTarefaUseCase` | `CA-11c` |
| Usuário confirma cascata? | `ExclusaoCanceladaFailure` | `ExcluirTarefaUseCase` / camada de UI | `CA-11c` |

> O sucesso oferece **desfazer** (ver fluxo 10), conforme `CEN-13`.

---

## 9. Diagrama de Fluxo — MoverTarefaUseCase · CEN-11

> Cenário(s): `CEN-11` (mover na hierarquia) — critério `CA-11b`.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B[[Recebe tarefa e novo pai destino]]
  B --> C{Novo pai é a própria tarefa ou descendente dela?}
  C -- Sim --> D([❌ MovimentoInvalidoFailure]):::error
  C -- Não --> E{Resultado respeita o limite de 3 níveis?}
  E -- Não --> F([❌ NivelMaximoExcedidoFailure]):::error
  E -- Sim --> G[[Reatribui a tarefa ao novo pai]]:::process
  G --> H[[Recalcula tempo acumulado do pai antigo e do novo]]:::process
  H --> I([✅ Tarefa movida]):::success
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Novo pai é a própria tarefa ou descendente? | `MovimentoInvalidoFailure` | `MoverTarefaUseCase` | — (regra técnica: evita ciclo na hierarquia) |
| Resultado respeita 3 níveis? | `NivelMaximoExcedidoFailure` | `MoverTarefaUseCase` | `CA-01` |
| (sucesso) recalcula tempo dos dois pais | — | `MoverTarefaUseCase` | `CA-11b` |

---

## 10. Diagrama de Fluxo — DesfazerUseCase · CEN-13

> Cenário(s): `CEN-13` (usuário leigo) — critério `CA-13`.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B{Há ação recente para desfazer?}
  B -- Não --> C([❌ NadaParaDesfazerFailure]):::error
  B -- Sim --> D{Tipo da última ação}
  D -- Concluir --> E[[Reabre a tarefa]]:::process
  D -- Excluir --> F[[Restaura a tarefa e filhas]]:::process
  D -- Migrar --> G[[Volta a tarefa ao dia original]]:::process
  E --> H([✅ Ação desfeita]):::success
  F --> H
  G --> H
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Há ação recente para desfazer? | `NadaParaDesfazerFailure` | `DesfazerUseCase` (pilha da última ação) | `CA-13` |
| Tipo da última ação | — (três desvios de reversão) | `DesfazerUseCase` | `CA-13` |

---

## 11. Diagrama de Fluxo — CriarCompromissoUseCase · CEN-14

> Cenário(s): `CEN-14` (agenda e compromissos) — critério `CA-14`.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B[["Recebe data, hora de início, duração e lista"]]
  B --> C{Título preenchido?}
  C -- Não --> D([❌ TituloVazioFailure]):::error
  C -- Sim --> E{Duração é positiva?}
  E -- Não --> F([❌ DuracaoInvalidaFailure]):::error
  E -- Sim --> G[[Define lista - usa Entrada se vazio]]:::process
  G --> H[[Salva compromisso na agenda do dia]]:::process
  H --> I{Salvou com sucesso?}
  I -- Não --> J([❌ ServerFailure]):::error
  I -- Sim --> K[[Recalcula o cabe-no-dia]]:::process
  K --> L([✅ Compromisso criado]):::success
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Título preenchido? | `TituloVazioFailure` | `CriarCompromissoUseCase` | — (regra técnica) |
| Duração é positiva? | `DuracaoInvalidaFailure` | `CriarCompromissoUseCase` | `CA-14` |
| Salvou com sucesso? | `ServerFailure` | `CompromissoRepository.criar` | `CA-14` |
| (sucesso) recalcula cabe-no-dia | — | `VerificarCabeNoDiaUseCase` | `CA-04`, `CA-14` |

---

## 12. Diagrama de Fluxo — ExcluirListaUseCase · CEN-11

> Cenário(s): `CEN-11` (excluir) aplicado a listas — critério derivado do Requisito 5.

```mermaid
flowchart TD
  classDef error fill:#ff6b6b,color:#fff,stroke:#c0392b
  classDef success fill:#51cf66,color:#fff,stroke:#2f9e44
  classDef process fill:#74c0fc,color:#000,stroke:#339af0

  A([Início]) --> B[[Recebe lista a excluir]]
  B --> C{Lista tem tarefas?}
  C -- Não --> D[[Exclui a lista]]:::process
  C -- Sim --> E{O que fazer com as tarefas?}
  E -- Mover --> F[[Move as tarefas para a lista escolhida]]:::process
  E -- Excluir todas --> G[[Exclui as tarefas da lista]]:::process
  E -- Cancelar --> H([❌ ExclusaoCanceladaFailure]):::error
  F --> I[[Exclui a lista]]:::process
  G --> I
  D --> J([✅ Lista excluída - com opção de desfazer]):::success
  I --> J
```

### Decisões mapeadas (losangos)

| Decisão | Failure (caminho Não) | Onde implementar | Ref (CEN/CA) |
|---------|-----------------------|------------------|--------------|
| Lista tem tarefas? | — (desvio: sem tarefas exclui direto) | `ExcluirListaUseCase` | Requisito 5 |
| O que fazer com as tarefas? | `ExclusaoCanceladaFailure` (se cancelar) | `ExcluirListaUseCase` / UI (pergunta ao usuário) | Requisito 5 |

---

## Requisitos SEM fluxograma (sem lógica de decisão)

Para não passar a impressão de que foram esquecidos, os requisitos abaixo são
**lineares** (CRUD simples ou leitura) e não geram fluxograma nesta entrega:

| Requisito | Motivo |
|-----------|--------|
| 6 — Listagem (ordenação) | A ordenação em si é linear; a parte com decisão (cálculo da urgência) está no fluxo 4. |
| 7 — Relatórios | Leitura e agregação; sem ramificação. |
| 8 — Login | Autenticação padrão do Firebase; sem regra de negócio própria. |
| 9 — Backup na nuvem | Persistência automática; sem ramificação. |
| 12 — Cronômetro em 1 toque / +15/+30 / padrões | Atalhos de UI sobre fluxos já cobertos (1 e 2). |
| 13 — Começar simples / telas que ensinam / 1º acesso | Comportamento de UI, sem decisão de negócio (o "desfazer" está no fluxo 10). |

_Nenhuma pendência de decisão em aberto — todos os fluxos têm regra definida._
