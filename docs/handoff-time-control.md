# Handoff técnico — Meu Tempo

_Gerado em 2026-07-20, a partir de `requisitos-time-control.md` (aprovado em 2026-07-19)_

## Visão geral

Aplicativo pessoal (PWA em **Flutter Web**, backend **Firebase**) que digitaliza a
metodologia Bullet Journal e resolve a dor de "o dia passa e não sei onde foi o
tempo". A **versão 1** é um **gerenciador de tarefas hierárquico com medição de
tempo**: tarefas em 3 níveis, cronômetro nas folhas e compromissos, priorização automática,
listas (categorias), agenda com compromissos por horário, relatórios de tempo por
lista e comparação estimado × real, tudo por usuário com login e persistência na nuvem. As demais funcionalidades
(água, hábitos, humor/energia, sono, rituais, monitoráveis genéricos, etc.) estão
no backlog de próximas versões.

## Histórias de usuário (1ª versão)

### H1 — Tarefas em 3 níveis `(origem: Requisito Essencial 1)`

**Como** usuário, **quero** organizar tarefas em até 3 níveis (mãe → filha → neta),
**para** quebrar projetos grandes em partes executáveis.

**Critérios de aceitação:**
- **Dado** que crio uma tarefa mãe, **quando** adiciono filhas e netas, **então** a
  hierarquia é mantida com no máximo 3 níveis.
- **Dado** uma tarefa **folha** (sem filhas), **quando** a edito, **então** informo
  **tempo estimado**, **data de entrega** e **importância (1–4, 1 = máxima)**.
- **Dado** uma tarefa mãe/avó, **quando** existem folhas abaixo, **então** seu tempo
  estimado é a **soma** das folhas (calculado, não digitado).

**Regras de negócio envolvidas:** Hierarquia de tarefas (3 níveis); Tempo acumulativo.

### H2 — Registro de tempo (cronômetro e manual) `(origem: Requisito Essencial 2)`

**Como** usuário, **quero** medir o tempo real das tarefas, **para** saber quanto
gastei de fato em cada uma.

**Critérios de aceitação:**
- **Dado** uma folha, **quando** inicio o cronômetro e paro depois, **então** o
  tempo é salvo naquela folha.
- **Dado** uma folha, **quando** digito o tempo manualmente (ex.: "1h30"), **então**
  ele é registrado.
- **Dado** que já há um cronômetro ativo, **quando** dou start em outra folha,
  **então** o anterior é **pausado automaticamente** (só 1 ativo por vez).
- **Dado** tempo registrado numa folha, **quando** consulto a mãe/avó, **então** o
  tempo aparece **somado** (acumulativo) nelas.

**Regras de negócio envolvidas:** Cronômetro só na folha; Um cronômetro por vez;
Tempo acumulativo.

**Tratamento de erros:** Cronômetro sem limite e sem aviso; correção manual do
tempo quando o usuário perceber ("Quando dá errado").

### H3 — Migração de pendências `(origem: Requisito Essencial 3)`

**Como** usuário, **quero** decidir o destino das tarefas não feitas, **para**
manter a lista honesta (Bullet Journal).

**Critérios de aceitação:**
- **Dado** uma folha não concluída ao fim do dia, **quando** abro o app no dia
  seguinte, **então** o app lista as pendências e me deixa **migrar** ou
  **descartar** cada uma.

**Regras de negócio envolvidas:** Migração de tarefas (só age sobre folhas **não
concluídas**).

### H4 — Aviso "cabe no dia" `(origem: Requisito Essencial 4)`

**Como** usuário, **quero** ser avisado quando planejo mais do que cabe, **para**
não me frustrar com metas impossíveis.

**Critérios de aceitação:**
- **Dado** que defini "horas disponíveis por dia" (valor fixo), **quando** a soma
  das durações estimadas do dia ultrapassa esse valor, **então** o app me avisa.

**Regras de negócio envolvidas:** Planejamento cabe no dia.

### H5 — Listas (categorias) `(origem: Requisito Essencial 5)`

**Como** usuário, **quero** organizar tarefas em listas, **para** separar contextos
(pessoal, profissional, estudo…) e ter relatório por lista.

**Critérios de aceitação:**
- **Dado** a tela de listas, **quando** crio/edito/apago uma lista, **então** a
  mudança é refletida nas tarefas ligadas.
- **Dado** o primeiro uso, **então** já existe uma lista fixa **"Entrada"**
  (destino padrão da criação rápida).
- **Dado** uma tarefa, **quando** a edito, **então** posso movê-la para outra lista.
- **Dado** uma lista **com tarefas**, **quando** tento excluí-la, **então** o app
  pergunta se **movo as tarefas** para outra lista ou **excluo todas**.

**Regras de negócio envolvidas:** Excluir lista com tarefas.

### H6 — Listagem por prioridade `(origem: Requisito Essencial 6)`

**Como** usuário, **quero** ver as tarefas executáveis ordenadas por prioridade,
**para** saber o que fazer primeiro.

**Critérios de aceitação:**
- **Dado** um conjunto de folhas, **quando** abro a listagem, **então** vejo uma
  **lista plana só das folhas**, ordenada por
  `prioridade = tempoEstimado × (5 − importância) × urgênciaDoPrazo`.
- **urgênciaDoPrazo** (faixas): atrasada/hoje = 6; 1–2 dias = 5; 3–5 dias = 4;
  6–9 dias = 3; 10–14 dias = 2; +14 dias = 1.
- **Dado** cada item da lista, **então** exibe um **subtítulo** com a mãe e a avó
  (ex.: "Lançar app › Fazer telas").
- **Dado** duas folhas de mesma importância, **quando** ordeno, **então** a de
  entrega mais próxima fica no topo.

**Regras de negócio envolvidas:** Prioridade.

### H7 — Relatórios de tarefas e agenda `(origem: Requisito Essencial 7)`

**Como** usuário, **quero** relatórios por dia/semana/mês, **para** enxergar onde
foi meu tempo.

**Critérios de aceitação:**
- **Dado** tempo registrado, **quando** abro os relatórios, **então** vejo **tempo
  por lista** e a comparação **estimado × real**, filtráveis por dia, semana e mês.

### H8 — Login por usuário `(origem: Requisito Essencial 8)`

**Como** usuário, **quero** minha própria conta, **para** que meus dados fiquem
separados do outro usuário.

**Critérios de aceitação:**
- **Dado** dois usuários, **quando** cada um entra com sua conta, **então** vê
  **apenas os próprios dados**.

**Regras de negócio envolvidas:** Dados por usuário.

### H9 — Backup na nuvem `(origem: Requisito Essencial 9)`

**Como** usuário, **quero** meus dados salvos na nuvem, **para** recuperá-los ao
trocar de celular.

**Critérios de aceitação:**
- **Dado** que usei o app num aparelho, **quando** entro com a mesma conta em
  outro, **então** vejo o mesmo histórico.

### H10 — Conclusão e progresso `(origem: Requisito Essencial 10)`

**Como** usuário, **quero** concluir tarefas e ver o progresso, **para** sentir o
avanço dos projetos.

**Critérios de aceitação:**
- **Dado** uma folha, **quando** a marco como feita, **então** ela sai da listagem
  de prioridade e deixa de ser pendência da migração.
- **Dado** que todas as filhas de uma mãe/avó estão feitas, **então** a mãe/avó é
  **concluída automaticamente**.
- **Dado** uma mãe/avó, **então** exibe **barra de progresso** pela proporção de
  folhas concluídas (3 de 5 → 60%).

**Regras de negócio envolvidas:** Conclusão de folha; Conclusão automática da
mãe/avó; Progresso da mãe/avó.

### H11 — CRUD e mover na hierarquia `(origem: Requisito Essencial 11)`

**Como** usuário, **quero** editar, excluir e mover tarefas, **para** corrigir e
reorganizar o que cadastrei.

**Critérios de aceitação:**
- **Dado** uma tarefa, **quando** edito qualquer campo (prazo, importância, lista,
  tempo estimado, título), **então** a mudança é aplicada e a prioridade é
  **recalculada** quando aplicável.
- **Dado** uma tarefa, **quando** a movo na hierarquia (ex.: neta vira filha de
  outra mãe), **então** o tempo acumulado passa a contar na **nova** mãe/avó.
- **Dado** uma tarefa com filhas, **quando** a excluo, **então** o app apaga
  também filhas/netas, **pedindo confirmação** antes.

**Regras de negócio envolvidas:** Mover na hierarquia; Excluir em cascata.

**Tratamento de erros:** Excluir tarefa com filhas → apaga tudo com confirmação
("Quando dá errado").

### H12 — Uso sem fricção `(origem: Requisito Essencial 12)`

**Como** usuário, **quero** registrar com o mínimo de toques, **para** manter o
hábito de usar o app.

**Critérios de aceitação:**
- **Dado** a criação rápida, **quando** digito só o título, **então** a tarefa
  nasce com **padrões** (importância 4, entrega hoje, 30 min, lista "Entrada") e já
  entra na listagem por prioridade.
- **Dado** a listagem, **quando** toco no controle de cronômetro, **então** inicio/
  paro o tempo **sem abrir** a tarefa.
- **Dado** o registro manual, **então** há atalhos de tempo rápido (**+15 / +30 min**).
- **Dado** uma nova tarefa, **então** o app sugere a **última lista usada** e uma
  **importância padrão**.

**Regras de negócio envolvidas:** Valores padrão da criação rápida.

### H13 — Facilidade para usuário leigo `(origem: Requisito Essencial 13)`

**Como** usuário leigo, **quero** um app simples e sem medo de errar, **para**
começar a usar sem curva de aprendizado.

**Critérios de aceitação:**
- **Dado** o uso básico, **quando** crio tarefas comuns, **então** hierarquia,
  importância e prazo **não são exigidos** — recursos avançados só aparecem quando
  eu quiser (revelação progressiva).
- **Dado** que concluí/excluí/migrei uma tarefa, **quando** aciono **"desfazer"**,
  **então** a ação é revertida.
- **Dado** o primeiro acesso, **então** o app traz uma **tarefa e uma lista de
  exemplo**.
- **Dado** uma tela sem dados, **então** ela exibe o **próximo passo** em vez de
  ficar em branco.

**Regras de negócio envolvidas:** Desfazer.

> **Nomenclatura de UI:** manter os termos **"tarefa mãe / filha / neta"** também
> nas telas (decisão do cliente — não substituir por "tarefa/subtarefa").

### H14 — Agenda e compromissos com horário `(origem: Requisito Essencial 14)`

**Como** usuário, **quero** agendar compromissos com horário e vê-los numa agenda,
**para** organizar o dia junto das tarefas.

**Critérios de aceitação:**
- **Dado** um compromisso, **quando** o cadastro, **então** informo **data**,
  **hora de início** e **duração** (o fim é calculado por início + duração).
- **Dado** compromissos do dia, **quando** abro a **agenda do dia**, **então** vejo
  cada um posicionado por horário.
- **Dado** um compromisso com duração, **quando** o app calcula o "cabe no dia",
  **então** essa duração **desconta** das horas disponíveis, junto com as tarefas.
- **Dado** um compromisso, **quando** uso o cronômetro/registro manual, **então**
  o tempo real é medido e comparado com a duração estimada (estimado × real).
- **Dado** um compromisso, **quando** o cadastro, **então** ele pertence a uma
  **lista** (ou "Entrada") e seu tempo entra no **relatório por lista**; na UI é
  exibido com **ícone diferente** do de tarefa.

**Regras de negócio envolvidas:** Planejamento cabe no dia (tarefas + compromissos);
Um cronômetro por vez (inclui compromissos).

## Backlog (Próximas versões / Desejável / Futuro)

**Próximas versões** (já detalhado no documento de requisitos):
- Cadastro genérico de "coisas a monitorar" (4 tipos de medição; metas com direção aumentar/limite) `(origem: Próximas versões)`
- Água (tamanhos de copo via CRUD + meta) `(origem: Próximas versões)`
- Hábitos por tempo, com sequência de dias `(origem: Próximas versões)`
- Humor (1–4) e energia (1–4) com horário `(origem: Próximas versões)`
- Sono (dormir/acordar + qualidade + meta) `(origem: Próximas versões)`
- Revisão de fim de dia + planejamento do dia seguinte (noturno) `(origem: Próximas versões)`
- Calibragem de estimativa `(origem: Próximas versões)`
- Metas por semana e mês `(origem: Próximas versões)`
- Tarefas/compromissos recorrentes `(origem: Próximas versões)`
- Picos de energia `(origem: Próximas versões)`
- Visão de semana e de mês para planejar `(origem: Próximas versões)`
- Lembretes (água, humor/energia, tarefas/compromissos) `(origem: Próximas versões)`

**Desejável:**
- Relatório humor/energia × tempo `(origem: Desejável 1)`
- Anotações livres / captura rápida de ideias / eventos sem tarefa `(origem: Desejável 2)`

**Futuro:**
- Uso no computador com sincronização entre aparelhos `(origem: Futuro 1)`
- Compartilhamento entre usuários (diário conjunto) `(origem: Futuro 2)`

## Fora de escopo

- Não medir uso de tela automaticamente (registro é manual).
- Sem compartilhamento entre os 2 usuários (dados isolados).
- Sem versão de computador nesta versão.
- Sem controle de finanças/dinheiro.

## Dados e volumetria

**Entidades principais (v1):**
- **Usuário** (login; isolamento total de dados por usuário).
- **Lista** (nome; lista fixa "Entrada" criada por padrão).
- **Tarefa** (título, nível mãe/filha/neta, referência ao pai, lista; nas folhas:
  tempo estimado, data de entrega, importância 1–4, status concluída/pendente).
- **Compromisso** (data, hora de início, duração, **lista**; tem registro de tempo
  real e entra no "cabe no dia", na agenda do dia e no relatório por lista; ícone
  distinto na UI).
- **Registro de tempo** (folha **ou compromisso**, duração, origem cronômetro/manual;
  tempo agregado para mãe/avó é **derivado**, não persistido em duplicidade).
- **Estado de cronômetro ativo** (no máximo 1 por usuário — vale para folhas e compromissos).
- **Configuração** (horas disponíveis por dia; padrões da criação rápida).

**Volumetria:** uso pessoal, **2 usuários independentes**, sem concorrência
relevante e sem picos. Carga baixa — dimensionamento não é preocupação para a v1.

## Restrições

- **Plataforma:** PWA em **Flutter Web**; uso **só no celular** (sem versão desktop);
  **sempre online** (sem modo offline).
- **Backend:** **Firebase** (autenticação + persistência na nuvem).
- **Prazo/orçamento:** não há — projeto pessoal, sem data de entrega nem custo definido.

## Glossário do domínio

- **Bullet Journal**: método de organização (Ryder Carroll) — base conceitual do app.
- **Lista**: categoria a que uma tarefa pertence (unifica o antigo termo "área");
  base dos relatórios por lista.
- **Tarefa mãe / filha / neta**: os 3 níveis da hierarquia (nome usado também na tela).
- **Folha**: tarefa sem filhas — única tarefa executável (cronômetro), única que
  aparece na listagem por prioridade e única com tempo/data/importância próprios.
  (Compromissos também têm cronômetro, mas ficam na agenda, não na listagem.)
- **Importância**: peso de 1 a 4, sendo **1 a máxima**.
- **Prioridade**: `tempoEstimado × (5 − importância) × urgênciaDoPrazo`.
- **Migração**: reavaliar uma tarefa não feita e decidir migrar ou descartar.
- **Duração estimada**: tempo que o usuário acha que a tarefa levará (comparado com o real).
- **Compromisso**: evento agendado (data + hora de início + duração; fim = início +
  duração); pertence a uma lista, aparece na agenda do dia (ícone próprio), ocupa o
  "cabe no dia", tem registro de tempo e entra no relatório por lista.

## Riscos e pontos de atenção

- **Tempo agregado da mãe/avó** deve ser sempre **calculado a partir das folhas**,
  nunca editável diretamente — senão os totais divergem. Risco de bug de consistência.
- **Estado "cronômetro ativo" é global por usuário**: a lógica de pausar o anterior
  ao dar start em outra folha precisa ser centralizada, ou duas tarefas podem
  contar tempo simultaneamente.
- **Recálculo de prioridade** depende da data atual (faixas de urgência mudam a cada
  dia): a ordenação deve ser reavaliada na abertura/atualização da lista, não fixada.
- **Excluir em cascata** é destrutivo; garantir confirmação e integração com o
  **"desfazer"** (H13) para não haver perda acidental irreversível.
- **Mover na hierarquia** deve reatribuir corretamente o tempo acumulado à nova
  mãe/avó e recalcular progresso de ambas (origem e destino).
- **Detalhe de cálculo:** a fórmula de prioridade usa `tempoEstimado` em unidade a
  padronizar (minutos ou horas) — fixar a unidade para evitar distorção de escala
  entre os fatores.
