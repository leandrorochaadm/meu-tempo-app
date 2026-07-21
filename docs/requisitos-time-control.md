# Requisitos — Meu Tempo

_Controle de tempo pessoal — Bullet Journal digital com cronômetro por tarefa._
_Levantado em 2026-07-19 · Última atualização em 2026-07-20_
_Entrevistado: Leandro (usuário e dono da ideia)_

## Problema e objetivos

O dia passa e o Leandro não sabe onde foi o tempo. Sente que:
- Gasta tempo sem ser produtivo.
- Os projetos não saem do papel.
- Vive cansado.
- Procrastina muito.

A ideia é ter um aplicativo pessoal que ajude a enxergar como o tempo é gasto e
acompanhar hábitos, água, humor e energia ao longo do dia, para conseguir mudar
esse quadro.

**Vamos saber que deu certo quando** (depois de ~1 mês de uso):
- No fim de cada dia o Leandro **sabe em que gastou o tempo** — sem "horas que sumiram".
- Ele **planeja só o que cabe no dia** e conclui o que planejou.
- Ele **mantém as correntes** de hábitos (ex.: ler/meditar) por vários dias seguidos.
- Ele se sente **menos cansado**, e o sono/energia mostram melhora ao longo das semanas.

**Já na versão 1, dá certo quando:** ao fim de cada dia o Leandro vê **onde foi
o tempo** (tempo por área) e a comparação **estimado × real**, e passa a planejar
só o que **cabe no dia**. _(As demais medições da régua acima dependem de recursos
que ficaram para próximas versões.)_

## Como funciona hoje

Hoje o Leandro usa um **Bullet Journal em papel** (metodologia do Ryder Carroll):
- Uma folha para as tarefas do dia.
- Uma folha para a semana.
- Uma folha para o mês.

**O que dói no papel:**
- Não consegue ver o **tempo gasto em cada tarefa**.
- Não tem um **relatório preciso** de tudo que fez no dia.
- Não sabe **quanto tempo realmente trabalhou** no dia.

**Objetivo do app:** ser o Bullet Journal digital, mantendo a metodologia
(dia / semana / mês, registro rápido, migração de tarefas), mas resolvendo o
que o papel não faz — medir e relatar o tempo gasto em cada tarefa.

## Pessoas envolvidas

| Quem | O que faz | Decide/aprova algo? |
|------|-----------|---------------------|
| Usuário (2 pessoas) | Cada um usa o app para acompanhar o próprio dia; cada um tem seu **login** e seu **diário separado** | Sim — cada um é dono dos próprios dados |

**Observação:** o app terá **2 usuários independentes** (ex.: Leandro e outra
pessoa). Cada um vê **apenas os seus dados** — não há compartilhamento entre eles.

## Requisitos

Este documento descreve o **produto completo**. A **versão 1** foi propositalmente
focada no **gerenciador de tarefas com medição de tempo + agenda**: tarefas em 3
níveis, cronômetro, priorização, listas, relatórios, conclusão/progresso,
compromissos com horário e conta na nuvem. Água, hábitos, humor/energia, sono,
rituais e demais medições ficam em **Próximas versões**.

### Essencial (versão 1)

1. **Tarefas em 3 níveis** (mãe → filha → neta). Os campos **tempo estimado**,
   **data de entrega** e **importância (1 a 4, sendo 1 a máxima)** ficam **só na
   folha** (tarefa sem filhas). A tarefa mãe e a avó **herdam a soma** dos tempos
   das folhas.
   - _Pronto quando:_ crio "Lançar app" (mãe) → "Fazer telas" (filha) → "Tela de login" (neta) e só na neta informo tempo estimado, data e importância.
2. **Cronômetro e registro manual do tempo.**
   - Entre as tarefas, só a **folha** (sem filhas) pode ter cronômetro; **compromissos** (req. 14) também têm.
   - **Só 1 cronômetro ativo por vez:** dar start em outra tarefa/compromisso **pausa
     automaticamente** o que estava ativo.
   - O tempo registrado nas folhas **acumula para cima** (soma na mãe e na avó).
   - _Pronto quando:_ dou start na "Tela de login", depois start em outra folha (a primeira pausa sozinha), e o tempo aparece somado na mãe e na avó.
3. **Migração:** no dia seguinte, o app mostra as tarefas não feitas para eu decidir **migrar ou descartar** uma a uma.
   - _Pronto quando:_ deixo uma tarefa sem concluir hoje e amanhã o app me pergunta o que fazer com ela.
4. **Cabe no dia:** ao planejar, o app avisa se a soma das durações estimadas (tarefas **+ compromissos**) passa do tempo disponível. O tempo disponível é um valor de **horas fixas que o Leandro define** uma vez.
   - _Pronto quando:_ defino "8h disponíveis por dia"; ao planejar 9h entre tarefas e compromissos, o app me avisa que passou.
5. **Listas:** criar, editar e apagar listas (ex.: pessoal, profissional, estudo) e ligar cada tarefa a uma lista. Já existe por padrão uma lista fixa **"Entrada"** (destino das tarefas criadas rápido).
   - **Excluir lista com tarefas:** o app **pergunta** o que fazer com as tarefas — **mover para outra lista** (que o usuário escolhe) ou **excluir todas**.
   - _Pronto quando:_ crio a lista "Estudo", ligo uma tarefa a ela e depois consigo renomeá-la; ao tentar excluí-la com tarefas dentro, o app me pergunta se movo as tarefas para outra lista ou excluo todas.
6. **Listagem por prioridade:** lista **plana só das folhas** (tarefas executáveis), ordenada pela prioridade calculada.
   - **Fórmula:** `prioridade = tempoEstimado × (5 − importância) × urgênciaDoPrazo`. Tarefas mais próximas, mais importantes (1) e mais longas vêm primeiro.
   - **urgênciaDoPrazo (faixas graduais até 14 dias):**
     - Atrasada ou vence hoje → **6**
     - 1–2 dias → **5**
     - 3–5 dias → **4**
     - 6–9 dias → **3**
     - 10–14 dias → **2**
     - Mais de 14 dias → **1**
   - Cada item exibe um **subtítulo indicando a mãe e a avó** daquela tarefa (ex.: "Lançar app › Fazer telas"), para dar o contexto da hierarquia na lista plana.
   - _Pronto quando:_ uma tarefa importante (1) de 2h que vence hoje pontua `2 × 4 × 6 = 48` e fica acima da mesma tarefa vencendo em 4 dias (`2 × 4 × 4 = 32`); e vejo o subtítulo "Lançar app › Fazer telas" na folha.
7. **Relatórios das tarefas e da agenda** por dia, semana e mês: tempo por **lista** e **estimado × real**.
   - _Pronto quando:_ no fim do dia vejo "Profissional 3h, Estudo 1h" e a comparação do que estimei com o que gastei.
   - **7.1 — Navegar entre períodos (melhoria 2026-07-21):** além de ver o período atual,
     posso **voltar e avançar** entre dias/semanas/meses (setas ‹ ›), sem limite para trás
     (para enquanto houver dados registrados).
     - _Pronto quando:_ estou na visão "semana", volto uma seta e vejo o relatório da
       semana passada; volto de novo e vejo a retrasada.
   - **7.2 — Detalhe hierárquico por tarefa dentro da lista (melhoria 2026-07-21):** ao
     **tocar numa lista** no relatório, abre uma tela com a **hierarquia** (avó → filha →
     neta) das tarefas daquela lista no período, mais os compromissos, cada nó com
     **gasto × estimado** e o **estouro em número** (ex.: +2h00 / −1h00). O objetivo é
     **conferência pessoal**: comparar o estimado com o real e ver onde estourou.
     - _Hierarquia (como a tela principal):_ mostra só os nós de topo (avó/mãe); **tocar
       expande as filhas/netas inline**, indentadas. O **gasto da mãe/avó é derivado**
       (tempo próprio, se houver, + soma das folhas); o estimado da mãe/avó é a soma das
       folhas.
     - _Regras:_
       - Só aparecem tarefas (e nós ancestrais) **com tempo registrado no período** —
         nós sem tempo são ocultados; os totais batem com a visão por lista.
       - O **gasto é só o tempo daquele período** (filtro "hoje" mostra só hoje; "semana"
         soma todos os dias da semana).
       - **Compromisso** aparece como nó de topo pelo tempo gasto, **sem estimativa nem
         estouro**.
     - _Ordenação do topo (posso trocar):_ por **tempo gasto** (padrão) ou por **estouro**
       (quem mais passou da estimativa no topo). A ordenação "mãe/avó" foi **removida** — a
       própria árvore já organiza por estrutura.
     - _Pronto quando:_ na lista "Profissional" da semana, toco na mãe "Projeto Alfa"
       (gasto 2h · est. 1h · +1h), ela expande mostrando "Montar proposta gasto 2h · est.
       1h · +1h"; troco a ordenação para "estouro" e a mãe com maior estouro sobe ao topo.
8. **Login** próprio por usuário, com **dados separados** entre os 2 usuários.
   - _Pronto quando:_ entro com minha conta e vejo só os meus dados.
9. **Backup na nuvem** (recuperar o histórico ao trocar de celular).
   - _Pronto quando:_ entro com minha conta em outro celular e vejo o mesmo histórico de antes.
10. **Conclusão de tarefas e progresso.**
    - **Concluir folha:** marcar uma folha como **feita**; ela sai da listagem de prioridade e deixa de ser pendência para a migração.
    - **Mãe conclui sozinha:** quando **todas as filhas** de uma mãe/avó estão feitas, ela é concluída **automaticamente**.
    - **Barra de progresso** na mãe/avó, mostrando o quanto do projeto já foi concluído (proporção de folhas feitas).
    - _Pronto quando:_ marco as 5 folhas de uma mãe como feitas e a mãe fica concluída sozinha, com a barra em 100%; ao concluir 3 de 5, a barra mostra 60%.
11. **Editar, excluir e mover tarefas.**
    - Editar qualquer campo (prazo, importância, **lista**, tempo estimado, título) — inclusive **mover a tarefa de uma lista para outra**.
    - Excluir uma tarefa (e definir o que acontece com as filhas — ver "Quando dá errado").
    - **Mover na hierarquia:** promover/rebaixar uma tarefa (ex.: neta vira filha) ou trocá-la de mãe.
    - _Pronto quando:_ mudo a data de uma tarefa e a prioridade dela se recalcula; movo uma neta para virar filha de outra mãe e o tempo passa a acumular na nova mãe.
12. **Uso sem fricção (registro rápido).**
    - **Criação rápida:** criar uma tarefa digitando só o **título**; ela nasce com **valores padrão** e já entra na listagem por prioridade. Padrões: importância **4 (mínima)**, entrega **hoje**, tempo estimado **30 min**, lista fixa **"Entrada"**. O Leandro reclassifica depois se quiser.
    - **Cronômetro em 1 toque:** dar start/stop **direto na listagem**, sem abrir a tarefa.
    - **Botões de tempo rápido:** no registro manual, atalhos como **+15 / +30 min**.
    - **Padrões inteligentes:** o app sugere a **última lista usada** e uma **importância padrão**.
    - _Pronto quando:_ crio uma tarefa só com o título em um toque, inicio o cronômetro dela pela própria lista, e ao registrar tempo à mão uso o botão "+30 min".
13. **Facilidade para usuário leigo.**
    - **Começar simples (revelação progressiva):** por padrão a pessoa cria tarefas comuns numa lista; recursos avançados (subtarefas/hierarquia, importância, prazo) só aparecem quando ela quiser usá-los — os valores padrão cuidam do resto.
    - **Desfazer (undo):** após **concluir, excluir ou migrar**, oferecer um "desfazer" rápido para reverter a ação.
    - **Primeiro acesso guiado:** o app já vem com uma **tarefa e uma lista de exemplo**, mostrando na prática como usar.
    - **Telas vazias que ensinam:** quando não há nada, a tela explica o **próximo passo** (ex.: "Toque em + para sua primeira tarefa") em vez de ficar em branco.
    - _Pronto quando:_ uso o app sem precisar mexer em hierarquia nem prioridade e ele funciona; ao excluir uma tarefa por engano, um "desfazer" a traz de volta; e no primeiro acesso vejo um exemplo pronto em vez de tela vazia.
14. **Agenda e compromissos com horário.**
    - Cadastrar **compromissos** com **data**, **hora de início** e **duração** (o fim = início + duração).
    - **Visão de agenda do dia**, mostrando os compromissos posicionados por horário.
    - O compromisso **ocupa o "cabe no dia"** (sua duração desconta das horas disponíveis, junto com as tarefas).
    - O compromisso **tem cronômetro / registro de tempo** e entra na comparação **estimado × real**, como as folhas.
    - O compromisso **pertence a uma lista** (ou cai na "Entrada") e entra no **relatório por lista**; na tela é mostrado com um **ícone diferente** do de tarefa.
    - _Pronto quando:_ crio "Reunião hoje 15h, 1h" na lista "Profissional", ela aparece na agenda às 15h com ícone de compromisso, desconta 1h do dia, e o tempo dela soma no relatório da lista "Profissional".

### Próximas versões

_Já conversados e detalhados; ficam para depois da versão 1 (sem ordem definida ainda)._

**Medições e monitoráveis:**
- **Cadastro genérico de "coisas a monitorar"** (4 tipos de medição; toda meta com direção **aumentar** ou **limite**).
- **Água** (botões de tamanho — tamanhos são CRUD do usuário — com meta diária).
- **Hábitos** medidos por tempo, com sequência de dias ("corrente").
- **Humor (1–4)** e **energia (1–4)**, vários registros por dia com horário.
- **Sono** (hora de dormir/acordar + qualidade 1–4, com meta e relatórios).

**Rituais e planejamento:**
- **Revisão de fim de dia** (resumo + migração + humor/energia).
- **Planejamento do dia seguinte** logo após a revisão (na noite anterior).
- **Calibragem de estimativa** (o quanto o Leandro erra as estimativas).
- **Metas por semana e mês** (além das diárias).

**Agenda avançada e visão de período:**
- **Tarefas e compromissos recorrentes** (ex.: academia seg/qua/sex).
- **Picos de energia** (melhores horários para tarefas difíceis).
- **Visão de semana e de mês para planejar** (distribuir tarefas ao longo dos dias).

**Lembretes:**
- **Lembretes** de água, humor/energia e tarefas/compromissos (intervalos e horários).

### Desejável

1. Relatório cruzando **humor/energia × como o tempo foi gasto** (ex.: "nos dias com mais rede social, energia mais baixa").
2. Anotações livres (notas do Bullet Journal), captura rápida de ideias e eventos sem tarefa.

### Futuro

1. Uso no computador com sincronização entre aparelhos.
2. Compartilhamento entre usuários (diário conjunto).

## Não faz parte (por enquanto)

- **Não mede o uso de tela sozinho** — o app não rastreia automaticamente o tempo
  de rede social/celular; o Leandro registra manualmente.
- **Sem compartilhamento entre os 2 usuários** — cada um vê só os próprios dados.
- **Sem versão de computador** — só celular nesta versão.
- **Sem controle de finanças/dinheiro.**

## Regras de negócio

- **Hierarquia de tarefas (3 níveis):** mãe → filha → neta. Tempo estimado, data
  de entrega e importância existem **só na folha** (tarefa sem filhas); mãe e avó
  **herdam a soma** dos tempos das folhas.
- **Cronômetro só na folha (e em compromissos):** apenas tarefas sem filhas e
  compromissos podem ter cronômetro.
- **Um cronômetro por vez:** dar start em outra tarefa/compromisso **pausa
  automaticamente** o que estava ativo.
- **Tempo acumulativo:** o tempo de uma folha soma no total da mãe e da avó.
- **Prioridade:** `tempoEstimado × (5 − importância) × urgênciaDoPrazo`
  (importância 1 = máxima). A `urgênciaDoPrazo` usa **faixas graduais até 14 dias**:
  atrasada/hoje = **6**, 1–2 dias = **5**, 3–5 dias = **4**, 6–9 dias = **3**,
  10–14 dias = **2**, mais de 14 dias = **1**.
- **Conclusão de folha:** uma folha marcada como **feita** sai da listagem de
  prioridade e não é mais pendência para a migração.
- **Conclusão automática da mãe/avó:** quando todas as filhas estão feitas, a
  mãe (e a avó) é concluída sozinha.
- **Progresso da mãe/avó:** proporção de folhas concluídas (usada na barra de progresso).
- **Mover na hierarquia:** ao mover uma tarefa de mãe, o tempo acumulado passa a
  contar na nova mãe/avó.
- **Excluir em cascata:** excluir uma tarefa com filhas apaga também todas as
  filhas/netas, sempre com **confirmação** antes.
- **Excluir lista com tarefas:** o app pergunta ao usuário — **mover as tarefas**
  para outra lista ou **excluir todas**.
- **Valores padrão da criação rápida:** importância **4**, entrega **hoje**,
  tempo estimado **30 min**, lista **"Entrada"** (lista fixa que já existe por padrão).
- **Desfazer:** concluir, excluir e migrar podem ser **desfeitos** logo após a ação.
- **Migração de tarefas:** quando uma tarefa (folha **não concluída**) não é feita
  no dia, no dia seguinte o app mostra as pendências e o Leandro decide uma a uma —
  **levar pra frente** (migrar) ou **descartar**.
- **Planejamento cabe no dia:** o tempo disponível é um valor fixo de horas
  definido pelo Leandro; se a soma das durações estimadas (tarefas **+
  compromissos**) passar desse valor, o app avisa.
- **Hábito feito por tempo:** ao registrar qualquer tempo numa atividade que é
  hábito, ele conta como feito no dia e a sequência de dias aumenta.
- **Dados por usuário:** cada usuário só enxerga os próprios dados.
- **Cronômetro sem limite:** o cronômetro não tem limite de horas e o app **não
  avisa** sobre tempos longos. Se o Leandro esquecer ligado, ele **edita o tempo
  manualmente** quando perceber.
- **Registro retroativo:** lançamentos (tempo, água, humor, energia, hábitos)
  podem ser feitos depois, informando o horário real do acontecimento.
- **Corrente mantida por registro retroativo:** registrar um dia que faltou
  mantém a sequência do hábito, desde que ele tenha sido realmente feito.
- **Direção da meta:** toda meta é de **aumentar** ("pelo menos" X — bater é
  vitória) ou de **diminuir/limite** ("no máximo" X — passar é alerta). Vale para
  qualquer "coisa a monitorar" com meta, inclusive tempo por lista.
- **Ritual noturno:** o planejamento do próximo dia acontece **na noite anterior,
  logo após a revisão de fim de dia** — não de manhã.

## Quando dá errado

- **Cronômetro esquecido ligado** (contou tempo demais) → o app **não avisa**;
  o Leandro **edita o tempo manualmente** quando perceber.
- **Passou um dia sem registrar um hábito** → o Leandro pode **voltar e registrar
  o dia que faltou**; se de fato fez, a corrente é mantida.
- **Esqueceu de anotar água/humor/energia na hora** → pode **registrar depois
  informando o horário** em que realmente aconteceu (lançamento retroativo).
- **Excluir uma tarefa que tem filhas** → o app **apaga a tarefa e todas as
  filhas/netas**, pedindo **confirmação** antes.
- **Excluir uma lista que tem tarefas** → o app **pergunta**: mover as tarefas para
  outra lista (à escolha do usuário) ou excluir todas.
- **Criação rápida** → a tarefa nasce só com o título, recebendo **valores
  padrão** (importância 4, entrega hoje, 30 min, lista "Entrada"), e já entra na
  listagem por prioridade.

## Informações e volume

**Listas (categorias das tarefas):**
- Cada tarefa pertence a uma **lista** (ex.: pessoal, profissional, estudo, leitura,
  exercício/saúde, casa/afazeres, família/relacionamentos, rede social).
- O Leandro poderá **criar, editar e apagar** suas próprias listas.
- Haverá **relatório por lista**.
- _(Nota: "lista" unifica o que antes era chamado de "área" — é o mesmo conceito.)_

**Tarefas e agenda:**
- O app também é a **agenda pessoal** do Leandro.
- **Tarefas em 3 níveis** (mãe → filha → neta). Só a **folha** tem **tempo
  estimado**, **data de entrega** e **importância (1 a 4)**; mãe e avó herdam a
  soma dos tempos.
- **Listagem** plana das folhas, ordenada por **prioridade** (ver Regras), com
  subtítulo mostrando a mãe e a avó de cada tarefa.
- Cada tarefa pertence a uma **lista** (ver acima).
- **Compromissos** têm **data + hora de início + duração** (fim = início + duração),
  aparecem na **visão de agenda do dia**, ocupam o "cabe no dia" e também têm
  cronômetro/registro de tempo (estimado × real).
- O app registra o **tempo real** por **cronômetro** (só nas folhas e nos
  compromissos, 1 por vez, com pausa automática) ou **manual**; o tempo acumula na
  mãe e na avó.
- Relatório-chave: comparar **duração estimada × tempo real**.
- **Planejamento de capacidade:** ao montar o dia, o app deve mostrar se as
  tarefas planejadas **cabem no tempo disponível** (soma das durações estimadas
  × horas do dia) e avisar quando o Leandro planeja mais do que cabe.

**Monitoráveis genéricos (conceito central):**
O Leandro cria e edita suas próprias **"coisas a monitorar"** (não vêm fixas no
app). Toda meta escolhe uma **direção**:
- **Aumentar** ("pelo menos" X) → bater/passar o número é **vitória** (ex.: estudar pelo menos 2h, água pelo menos 2L).
- **Diminuir / limite** ("no máximo" X) → passar do número é **alerta** (ex.: rede social no máximo 30 min, celular no máximo 1h).

Cada uma usa um dos **tipos de medição**:
- **Quantidade com meta** — soma valores no dia com meta (ex.: água, passos, páginas).
- **Nota / nível** — escala com horário, várias vezes ao dia (ex.: humor 1–4, energia 1–4).
- **Tempo gasto** — cronômetro/manual, com sequência de dias (ex.: meditar, ler, exercício).
- **Sim/não ou hora-a-hora** — feito/não feito no dia, ou início/fim (ex.: sono dormi/acordei, tomar remédio).

Água, humor, energia, sono e hábitos são **exemplos já prontos** desse cadastro.

**Água** (exemplo de "quantidade com meta"):
- Lançamentos várias vezes por dia, por **botões de tamanho**.
- Os **tamanhos de copo são cadastrados pelo próprio usuário** (CRUD: criar,
  editar, apagar) — ex.: copo 200ml, garrafa 500ml.
- Tem **meta diária**; o app mostra quanto falta para bater a meta.

**Sono** (exemplo de "sim/não ou hora-a-hora"):
- **Hora de dormir e acordar** (app calcula a duração) + **qualidade (1–4)**.
- Tem **meta de horas** e entra nos **relatórios** (ex.: média da semana).

**Hábitos:**
- Exemplos: meditar, ler, exercício.
- São medidos pelo **tempo gasto** (não só "fiz/não fiz").
- Contam como **feitos** assim que houver **qualquer tempo** registrado no dia.
- O app mostra a **sequência de dias seguidos** (a "corrente"/foguinho).
- **Hábito = atividade de tempo:** ao registrar o tempo de uma atividade
  (ex.: ler), o hábito correspondente já conta como feito — sem registro duplicado.

**Humor e energia:**
- Vários lançamentos por dia, cada um com **horário**.
- **Humor:** nota de **1 a 4**.
- **Energia:** nível de **1 a 4**.
- Gera **histórico** ao longo do tempo.

**Relatórios:** por **dia, semana e mês** (tempo por lista, estimado × real,
água, hábitos/sequência, humor e energia).

## Limites

- **Uso só no celular** — a 1ª versão não terá versão de computador nem uso
  simultâneo em vários aparelhos. (A recuperação do histórico num celular novo,
  via backup na nuvem, está incluída — ver adiante.)
- **Sempre online** — o app funciona conectado à internet (não terá modo offline).
- **Lembretes/avisos** de: beber água, registrar humor/energia, e
  tarefas/compromissos agendados.
- **Cópia de segurança na nuvem**: os dados ficam guardados fora do celular,
  com **cadastro/login**, para recuperar o histórico ao trocar/perder o aparelho.
  Como o app é sempre online, os dados são salvos na nuvem à medida que o Leandro usa.
- **Sem prazo e sem orçamento** — é um projeto pessoal, sem data de entrega nem
  custo definido.

## Pontos em aberto

_Nenhum ponto em aberto — todos os temas foram fechados._

Decisões que encerraram as pendências anteriores:
- Tamanhos de copo → **CRUD do usuário** (não são fixos).
- Cronômetro → **sem limite e sem aviso**; correção manual quando o usuário perceber.
- **Sem prazo e sem orçamento** (projeto pessoal).
- **Lista = área** (conceito unificado sob o nome "lista").
- **urgênciaDoPrazo** → faixas graduais até 14 dias (atrasada/hoje = 6 … +14 dias = 1).
- **Excluir lista com tarefas** → o app pergunta: **mover as tarefas** para outra
  lista ou **excluir todas**.

## Glossário

- **Bullet Journal**: método de organização no papel (do Ryder Carroll) com
  registro rápido do dia, semana e mês e migração de tarefas — a base do app.
- **Migração**: reavaliar uma tarefa não feita e decidir levá-la pra frente ou descartar.
- **Lista**: categoria a que uma tarefa pertence (pessoal, profissional, estudo,
  leitura, etc.), criada/editada pelo Leandro; base dos relatórios por lista.
  Unifica o antigo termo "área".
- **Tarefa mãe / filha / neta**: os 3 níveis da hierarquia de tarefas (nome usado
  também na tela). A **folha** (sem filhas) é a única tarefa que tem tempo estimado,
  data, importância e cronômetro (compromissos também têm cronômetro).
- **Folha**: tarefa sem filhas — a única tarefa executável (cronômetro) e a única
  que aparece na listagem por prioridade. (Compromissos também têm cronômetro, mas
  vivem na agenda, não na listagem por prioridade.)
- **Importância**: peso da tarefa de **1 a 4**, sendo **1 a máxima**.
- **Prioridade**: ordem de execução calculada por
  `tempoEstimado × (5 − importância) × urgênciaDoPrazo`, sendo a urgência
  em faixas graduais até 14 dias (atrasada/hoje = 6 … mais de 14 dias = 1).
- **Monitorável ("coisa a monitorar")**: qualquer item que o Leandro cria pra
  acompanhar, usando um dos 4 tipos de medição. Água, humor, sono e hábitos são exemplos.
- **Hábito**: atividade recorrente medida por tempo; conta como feita ao registrar
  qualquer tempo, e tem sequência de dias ("corrente").
- **Energia**: sensação de disposição física/mental, registrada de 1 a 4 com horário.
- **Duração estimada**: quanto tempo o Leandro acha que a tarefa vai levar
  (comparada depois com o tempo real).
- **Compromisso**: evento agendado com data, **hora de início** e **duração**
  (fim = início + duração); pertence a uma **lista**, aparece na agenda do dia
  (com ícone próprio), ocupa o "cabe no dia" e tem cronômetro/registro de tempo.
- **Meta**: alvo de uma "coisa a monitorar", com direção — **aumentar**
  ("pelo menos" X) ou **diminuir/limite** ("no máximo" X).

## Cobertura da entrevista

- [x] Objetivo — dor e régua de sucesso definidas
- [x] Hoje — processo atual (Bullet Journal em papel) e o que dói
- [x] Pessoas — 2 usuários independentes, com login e dados separados
- [x] O que o sistema faz — tarefas de negócio (grupos A–E + transversais)
- [x] Regras e exceções
- [x] Informações — dados e monitoráveis genéricos
- [ ] Volume e ritmo — quantidades, picos _(pouco relevante: uso pessoal, 2 usuários)_
- [x] Limites — só celular, sempre online, backup na nuvem; sem prazo/orçamento
- [x] Prioridade — **versão 1 = gerenciador de tarefas (3 níveis) + tempo/cronômetro + listas + relatórios + conclusão/progresso + CRUD + uso sem fricção + facilidade p/ leigo + agenda/compromissos + login/nuvem** (req. 1–14); o resto em "Próximas versões"
- [x] Não-objetivos confirmados
- [x] Validação de qualidade dos Essenciais _(régua de sucesso definida; "pronto quando" preenchidos)_

## Histórico de sessões

- 2026-07-19 — Abertura + exploração completa: dor e objetivo; Bullet Journal como
  base; medição de tempo (cronômetro + manual); áreas com CRUD e relatórios;
  migração de tarefas; "cabe no dia"; monitoráveis genéricos (4 tipos de medição);
  água, sono, hábitos, humor e energia; 2 usuários com dados separados; sempre
  online; backup na nuvem; lembretes; não-objetivos e prioridade definidos;
  régua de sucesso e exceções ("quando dá errado") fechadas. Revisão geral do
  documento feita (contradição offline corrigida, requisitos renumerados 1–14).
  Pendências finais fechadas: tamanhos de copo viram CRUD do usuário; cronômetro
  sem limite/sem aviso (correção manual); sem prazo e sem orçamento (projeto
  pessoal). Metas ganharam **direção** (aumentar × diminuir/limite) para qualquer
  "coisa a monitorar". Melhorias sugeridas e aprovadas como essenciais
  (grupo F, req. 15–18): planejamento matinal, revisão de fim de dia, calibragem
  de estimativa e metas semanais/mensais; transversais renumerados 19–21.
  Ajuste: planejamento do dia passou a ser **na noite anterior, logo após a
  revisão** (não matinal). Grupo G (req. 22–24) adicionado como essencial:
  tarefas recorrentes, picos de energia e visão de semana/mês para planejar.
  **Decisão de escopo:** a **versão 1** ficou só com agenda + tempo por tarefa +
  áreas + relatórios + login/nuvem (req. 1–8); todo o resto foi movido para
  "Próximas versões".
- 2026-07-19 (cont.) — Detalhamento do **gerenciador de tarefas** (v1): hierarquia
  em 3 níveis (mãe→filha→neta), campos e cronômetro só nas folhas, 1 cronômetro
  por vez com pausa automática, tempo acumulativo, listagem plana das folhas por
  prioridade (`tempoEstimado × (5−importância) × urgênciaDoPrazo`) com subtítulo
  da mãe/avó, e **"lista" unificando "área"**. Fórmula de prioridade fechada:
  urgênciaDoPrazo em **faixas graduais até 14 dias** (atrasada/hoje = 6 … +14 dias = 1).
  **Nenhum ponto em aberto restante.**
- 2026-07-19 (cont.) — Lacunas do gerenciador fechadas como essenciais (req. 10):
  **concluir folha**, **mãe conclui sozinha** quando todas as filhas terminam, e
  **barra de progresso** na mãe/avó. Ajuste manual da ordem ficou de fora.
  Adicionados ainda: **CRUD** de tarefas (editar/excluir/mover, com exclusão em
  cascata mediante confirmação) e **uso sem fricção** (criação rápida, cronômetro
  em 1 toque, botões de tempo rápido, padrões inteligentes). Definido: tarefa
  criada só com título fica numa seção "a completar". **Ajuste posterior:** a
  criação rápida passou a usar **valores padrão** (importância 4, entrega hoje,
  30 min, lista "Entrada") e a tarefa já entra na listagem — substituindo a seção
  "a completar". Adicionado ainda (req. 13) para o **usuário leigo**: **começar
  simples** (revelação progressiva) e **desfazer** em concluir/excluir/migrar.
  Complementado com: **primeiro acesso guiado** (exemplo pronto) e **telas vazias
  que ensinam**. (Mantido "tarefa mãe/filha/neta" também na tela, a pedido do
  Leandro — descartada a troca por "tarefa/subtarefa".) Confirmado que
  **mover de lista** já está coberto pelo CRUD (req. 11). **Nenhum ponto em
  aberto restante.**
- 2026-07-20 — Geração e **revisão do handoff técnico** (`handoff-time-control.md`).
  A revisão achou uma promessa órfã: **agenda/compromissos com horário** estava nas
  Informações mas sem requisito. Decisão: **incluir na v1** (req. 14) — compromisso
  com hora de início + duração, na visão de agenda do dia, ocupando o "cabe no dia"
  e com cronômetro/registro de tempo. Removido "ajuste manual da ordem" do handoff
  (não constava nos requisitos).
- 2026-07-20 (cont.) — Nova revisão cruzada: compromisso passa a **pertencer a uma
  lista** (entra no relatório por lista) e é exibido com **ícone diferente** do de
  tarefa. Corrigido o glossário (folha não é mais "a única com cronômetro" —
  compromissos também têm). **Nenhum ponto em aberto restante.**
- 2026-07-20 (cont.) — Revisão de consistência pós-agenda: req. 2 deixou de dizer
  "cronômetro só nas folhas" (compromissos também têm); req. 4 ("cabe no dia") passou
  a citar tarefas + compromissos; introdução dos requisitos atualizada (v1 real, com
  "lista" no lugar de "área"). Documentos de requisitos e handoff consistentes.
- 2026-07-20 (cont.) — Gerados os **fluxogramas da v1** (`temp/diagrams/`). Ao
  desenhar, surgiu a lacuna "excluir lista com tarefas"; decisão: o app **pergunta**
  se move as tarefas para outra lista ou exclui todas. Registrado no req. 5, regras,
  "quando dá errado" e no fluxograma 12. **Nenhum ponto em aberto restante.**
- 2026-07-20 (cont.) — Definido o **nome oficial do produto: "Meu Tempo"**. Avaliados
  e descartados "TimePoint" e "myTime" (colisão semântica com ponto eletrônico /
  controle de jornada, e domínios principais ocupados) e "Cronos" (nome muito
  disputado). "Meu Tempo" venceu: o "Meu" posiciona autonomia pessoal (não
  vigilância) e há domínios livres (`meutempo.app`, variações `.com.br`). Títulos
  dos três documentos atualizados.
