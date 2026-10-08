# Entrevista — Meu Tempo: cronômetro na tela de bloqueio

_Levantado em 07/10/2026 · Última atualização em 07/10/2026_
_Entrevistado: Leandro (dono do app)_

## Problema e objetivos

- Leandro esquece de pausar ou parar o cronômetro. Ele continua contando e o
  tempo registrado fica maior que o real.
- Hoje a v1 não avisa quando o cronômetro fica esquecido ligado, e a correção
  é feita à mão quando ele percebe (requisitos da v1, "Cronômetro esquecido
  ligado"). Esta conversa muda essa decisão: o aviso de tempo estourado entra
  como desejável (ver "Quando dá errado").

**Vamos saber que deu certo quando:** o relatório da semana não tiver nenhuma
tarefa com tempo absurdo (tipo 24 horas para uma tarefa de 30 min).

## Como funciona hoje

- Leandro termina a atividade, mas não para o cronômetro.
- Ele só percebe quando vai **dar start na próxima tarefa**. Nessa hora o app
  pausa a anterior sozinho, mas o tempo entre o fim real e o novo start já
  foi contado na tarefa anterior.
- Depois de terminar a atividade, ele **usa o celular para outra coisa** (outros
  apps). Como o Meu Tempo fica em segundo plano, nada lembra que o cronômetro
  ainda está contando.

## Pessoas envolvidas

| Quem | O que faz | Decide/aprova algo? |
|------|-----------|---------------------|
| Leandro | Dono do app; usa no dia a dia | Sim — tudo |
| Demais usuários | Cada um usa o próprio cronômetro, com dados separados | Não |

## Requisitos

### Essencial (1ª versão)

1. **Cronômetro sempre à vista**: enquanto um cronômetro estiver rodando, ele
   aparece na **tela bloqueada** e **fixo na cortina de avisos**, mesmo com o
   app fechado.
   - _Pronto quando:_ dou start numa tarefa, abro o WhatsApp e bloqueio o
     celular: o cronômetro aparece na tela bloqueada. Ao desbloquear e puxar a
     cortina, ele está lá, fixo e contando. **Continua aparecendo mesmo se eu
     fechar o app de vez** (arrastar para fora).
   > 🟡 Parcial — planos 07, 09, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
2. **O que aparece**: nome, lista e tempo correndo — igual para tarefa e
   compromisso.
   - _Pronto quando:_ dou start na tarefa "Tela de login" da lista "Trabalho" e
     aparecem "Tela de login", "Trabalho" e o tempo andando. Dou start no
     compromisso "Dentista" da lista "Pessoal" e aparecem "Dentista", "Pessoal"
     e o tempo andando.
   > 🟡 Parcial — planos 06, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
3. **Pausar e parar dali mesmo**: botão **pausar** (continua depois) e botão
   **parar** (confirma com um segundo toque e conclui a tarefa). Pausado, continua à vista
   com o botão **continuar**; parado, some.
   - _Pronto quando:_ com o celular bloqueado, toco em "pausar": o tempo para e,
     ao abrir o app, a tarefa está pausada com o tempo certo. Dou start de
     novo, toco em "parar": o botão vira "confirmar"; toco nele e a tarefa
     aparece concluída no app. Se eu não tocar em "confirmar" em 5 segundos, o
     botão volta a "parar" e nada muda.
   > 🟡 Parcial — planos 04, 05, 06, 09, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
4. **Tarefas e compromissos**: tudo acima vale para os dois, do mesmo jeito.
   - _Pronto quando:_ repito os testes dos itens 1 e 3 com o compromisso
     "Dentista" e tudo funciona igual. E, com uma tarefa rodando, dou start no
     compromisso: a tela bloqueada passa a mostrar o compromisso (a tarefa
     pausa sozinha, como já acontece no app). Ao parar o compromisso, ele
     aparece na agenda com o sinal de "feito".
   > 🟡 Parcial — planos 02, 03, 05, 07, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
5. **Reabrir no app**: tarefa ou compromisso concluído pode ser reaberto
   dentro do app; ao reabrir uma filha, a mãe e a avó reabrem junto.
   - _Pronto quando:_ concluo a última filha de uma mãe e a mãe conclui
     sozinha. Reabro essa filha no app: ela volta para a listagem por
     prioridade, a mãe volta a ficar aberta e a barra de progresso cai. Reabro
     um compromisso concluído: o sinal de "feito" some da agenda.
   > ✅ Implementado — planos 02, 03

### Desejável

1. **Aviso de tempo estourado**: quando passar do tempo estimado, o app avisa
   e repete o aviso **a cada 1 hora** até pausar ou parar.
2. **Sem estimado, sem aviso**: tarefa sem tempo estimado e compromisso não
   recebem aviso; só ficam visíveis.

### Futuro

_Ainda não conversado._

## Não faz parte (por enquanto)

- Dar start em outra tarefa pela tela bloqueada: o start continua só dentro do
  app.
- Corrigir o tempo registrado pela tela bloqueada.
- Atalho (quadradinho) do cronômetro na tela inicial do celular.
- Mostrar o cronômetro no relógio de pulso (smartwatch).

## Regras de negócio

- **Pausar** (na tela bloqueada ou na cortina de avisos): o cronômetro para de
  contar e o tempo continua somando quando der start de novo, como já funciona
  no app.
  > 🟡 Parcial — planos 04, 06, 09, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
- **Parar**: interrompe o cronômetro **e** dá a tarefa ou o compromisso por
  **concluído**, **com confirmação em dois toques**: ao tocar em "parar", o
  botão vira "confirmar" por **5 segundos**; sem o segundo toque, volta a
  "parar" e nada muda. Igual no iPhone e no Android.
  > 🟡 Parcial — planos 05, 06, 09, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
- Vale para **tarefas e compromissos**, do mesmo jeito.
- **Pausado**: continua aparecendo, parado, com um botão **continuar** (que
  volta a contar) e o botão **parar**. Não dá para arrastar para o lado: só
  sai da tela ao continuar, parar ou dar start em outra tarefa/compromisso.
  > 🟡 Parcial — planos 04, 05, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
- **Parado** (concluído): some da tela bloqueada e da cortina.
  > 🟡 Parcial — planos 05, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
- Concluir pela tela bloqueada **não tem "desfazer"**: o segundo toque de
  confirmação já protege contra toque errado.
  > 🟡 Parcial — planos 09, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
- **Compromisso também pode ser concluído** (novidade: hoje só tarefa conclui).
  Ao parar um compromisso, ele fica marcado como concluído, também dentro do
  app. Já incluído na v1 (requisitos, req. 14) em 07/10/2026.
  > ✅ Implementado — planos 02, 03, 05
- **Reabrir**: tarefa ou compromisso concluído pode ser reaberto dentro do app
  (novidade; hoje só existe "desfazer" logo após concluir). Ao reabrir uma
  filha, a **mãe e a avó** que tinham concluído sozinhas **reabrem junto**.
  > ✅ Implementado — planos 02, 03
- Na agenda, o compromisso concluído **continua igual, com um sinal de
  "feito"** ao lado.
  > ✅ Implementado — plano 03
- **Tocar no cronômetro** (fora dos botões) abre o app direto na tarefa ou
  compromisso que está rodando.
  > 🟡 Parcial — planos 08, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
- **Dois celulares** (iPhone e Android com a mesma conta): a tela bloqueada de
  um não acompanha o outro na hora. Ao abrir o app, o celular acerta a própria
  tela bloqueada com o cronômetro que está de fato rodando.
  > 🟡 Parcial — planos 07, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
- Só um cronômetro aparece por vez: ao dar start em outro, a tela bloqueada
  passa a mostrar o novo (o anterior pausa sozinho, regra da v1).
  > 🟡 Parcial — planos 05, 07, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
- O que aparece: **nome**, **tempo correndo** e **lista**, igual para tarefa e
  compromisso. O tempo estimado **não** aparece.
  > 🟡 Parcial — planos 06, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)

## Quando dá errado

- **Cronômetro passou do tempo estimado** → o app **avisa** o usuário.
  Isso mudou a regra antiga da v1 ("o app não avisa"); a v1 já foi atualizada
  em 07/10/2026.
- O aviso **se repete a cada 1 hora** até o usuário pausar ou parar.
- **No navegador**, o aviso só aparece **com o app aberto**, dentro da própria tela.
- **Avisos do celular desligados** (o usuário negou a permissão ou desligou
  nos Ajustes) → o cronômetro não aparece na tela bloqueada. Ao dar start, o
  app mostra uma faixa: "Ative os avisos para ver o cronômetro com o celular
  bloqueado", com um botão que leva aos Ajustes do celular.
  > 🟡 Parcial — planos 08, 10, 11; falta: alvo no Xcode e validação no iPhone (passos manuais do plano 11)
- **Tarefa sem tempo estimado** e **compromisso** → o app **não avisa**; só
  fica visível na tela bloqueada e na cortina de avisos.

## Informações e volume

- O esquecimento acontece **todo dia**.
- Não entra informação nova: a tela bloqueada usa o que o app já guarda (nome
  da tarefa, lista, tempo).
- Exemplo típico: uma tarefa de **30 min** acaba com o cronômetro ligado por
  **cerca de 24 horas**, até o próximo start.

## Limites

- **Prazo:** é a próxima coisa a fazer no app, antes de qualquer outra novidade.
- Precisa funcionar no iPhone e no Android.
- **Limite do iPhone:** depois de **8 horas** rodando, o iPhone tira o
  cronômetro da tela bloqueada sozinho (pode ficar até 4 horas a mais, parado).
  Leandro aceitou o limite. O aviso de tempo estourado (desejável) ajuda quando
  existir, mas não cobre tarefa sem tempo estimado nem compromisso; nesses
  casos, depois de 8 horas volta a ser como hoje (corrigir à mão). Também
  aceito. No Android não há esse limite.
- Para mostrar o cronômetro com a tela bloqueada, o Meu Tempo passa a ter um
  **aplicativo instalado** no iPhone e no Android. A versão aberta pelo
  **navegador continua**, mas nela o cronômetro **não** aparece na tela
  bloqueada.
  > 🟡 Parcial — plano 01; falta: `flutterfire configure` e SHA/URL scheme (passos manuais), notificação e Live Activity (planos 10, 11)

## Pontos em aberto

- [x] O que você quer ver com o celular bloqueado e por quê → o cronômetro rodando, para lembrar de parar
- [x] O compromisso mostra a lista? → sim, igual à tarefa (corrigido: o compromisso pertence a uma lista, req. 14 da v1)
- [x] Vale só para tarefas ou também para compromissos? → os dois, do mesmo jeito (ver, pausar e parar)
- [x] Depois de pausar ou parar, some ou fica? → pausado fica (com botão de continuar); parado some
- [x] Como o compromisso concluído aparece na agenda? → igual, com sinal de "feito"
- [x] Concluir pela tela bloqueada tem "desfazer"? → não; a confirmação basta
- [x] Se concluir por engano, como reabrir? → novidade: reabrir dentro do app
- [x] Reabrir é essencial ou pode esperar? → essencial
- [x] Ao reabrir uma filha, a mãe reabre? → sim, mãe (e avó) reabrem junto
- [x] Priorizar → essencial: à vista + pausar/parar; desejável: aviso de estouro
- [x] Como conferir que cada item ficou pronto → "Pronto quando" de cada essencial
- [x] Quer só ver ou também pausar/parar dali? → ver **e** pausar/parar ali mesmo, sem abrir o app

## Glossário

- **Folha**: tarefa sem filhas, a única tarefa com cronômetro.
- **Compromisso**: item da agenda, também com cronômetro.
- **Cronômetro ativo**: o único que está contando agora (só um por vez).
- **Pausar**: interromper o cronômetro, podendo continuar depois.
- **Parar**: interromper o cronômetro e concluir a tarefa ou o compromisso.
- **Cortina de avisos**: a área que desce do topo da tela do celular.

## Cobertura da entrevista

- [x] Objetivo — resultado esperado e como saber que deu certo
- [x] Hoje — processo atual e o que dói
- [x] Pessoas — quem usa, quem faz o quê, quem aprova
- [x] O que o sistema faz — tarefas de negócio
- [x] Regras e exceções
- [x] Informações — dados e de onde vêm
- [x] Volume e ritmo — quantidades, picos
- [x] Limites — prazo, orçamento, integrações, obrigações legais
- [x] Prioridade — essencial × depois
- [x] Não-objetivos confirmados
- [x] Validação de qualidade dos Essenciais

_Etapas de Fase A/B: não se aplica — app pessoal, sem venda._

## Histórico de sessões

- 07/10/2026 — sessão 1: problema, processo atual, requisitos, regras,
  exceções, prioridade, não-objetivos, critérios de pronto e validação dos
  essenciais. Surgiram duas novidades além da tela bloqueada: "compromisso
  concluído" e "reabrir no app".
