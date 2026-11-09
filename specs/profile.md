# Perfil

O Perfil fica na tela de Configurações. Cenários marcados com "(servidor)" ou
"(integração)" não se testam no domínio (ver `sign_up.md`).

## REQ-006 Editar nome [pronto]

Fonte: requisitos-time-control.md, Requisitos, Essencial, req. 17 ("Nome: nome igual ao atual é recusado com aviso. Conta antiga sem nome...").

Quando o Usuário salvar um Nome válido (REQ-002) no Perfil, o sistema deve gravar o novo
Nome, já sem os espaços das pontas, e mostrá-lo no Perfil.

Se o novo Nome, sem os espaços das pontas, for igual ao atual, então o sistema deve
recusar com o Erro de campo `sameDisplayName` (REQ-011) e não gravar nada.

Enquanto o Usuário não tiver Nome (conta antiga), o sistema deve mostrar o campo vazio com
o texto "Informe seu nome", sem obrigar o preenchimento para usar o app.

Cenários:
- Nome "Ana", salva "Ana Lima": Nome "Ana Lima", 1 gravação
- Nome "Ana", salva " Ana Lima ": Nome "Ana Lima", 1 gravação
- Nome "Ana", salva "Ana": recusado com `sameDisplayName`, 0 gravações
- Nome "Ana", salva " Ana ": recusado com `sameDisplayName`, 0 gravações
- Nome "Ana", salva "A" (1 caractere): recusado com `displayNameLength`, 0 gravações
- Conta sem Nome, salva "Ana": Nome "Ana", 1 gravação
- (teste de widget) conta sem Nome abre o Perfil: 1 campo vazio com "Informe seu nome"

## REQ-007 Trocar e-mail [pronto]

Fonte: requisitos-time-control.md, Requisitos, Essencial, req. 17 ("Trocar o e-mail").

Quando o Usuário pedir para trocar o E-mail informando um novo E-mail bem escrito
(REQ-010) e a Senha atual correta, o sistema deve gravar o novo E-mail normalizado
(REQ-005) na hora, sem e-mail de confirmação, e Encerrar outros aparelhos (REQ-009).

Se o novo E-mail, normalizado, for igual ao atual, então o sistema deve recusar com o Erro
de campo `sameEmail` (REQ-011) e não chamar o servidor.

Se a Senha atual estiver errada, então o sistema deve recusar com
`WrongCurrentPasswordFailure`, sem dizer se o novo E-mail já tem conta, e manter o E-mail.

Se a Senha atual estiver correta e o novo E-mail já tiver conta de outro Usuário, então o
sistema deve recusar com `EmailAlreadyInUseFailure` e manter o E-mail.

Cenários:
- Ana (E-mail "ana@exemplo.com", Senha "abcd1234") troca para "ana.lima@exemplo.com" com "abcd1234": repositório chamado 1 vez com "ana.lima@exemplo.com", e 1 chamada para encerrar outros aparelhos
- Ana troca para " Ana.Lima@Exemplo.com " com "abcd1234": repositório recebe "ana.lima@exemplo.com", 1 chamada
- Ana troca para "ana@exemplo.com" com "abcd1234": recusado com `sameEmail`, 0 chamadas ao servidor
- Ana troca para "ANA@exemplo.com" com "abcd1234": recusado com `sameEmail`, 0 chamadas ao servidor
- Ana troca para "ana@" com "abcd1234": recusado com `invalidEmail`, 0 chamadas ao servidor
- Servidor responde senha atual errada: recusado com `WrongCurrentPasswordFailure`, 0 chamadas para encerrar outros aparelhos
- Servidor responde e-mail já usado: recusado com `EmailAlreadyInUseFailure`, 0 chamadas para encerrar outros aparelhos
- (servidor) Ana troca para "bia@exemplo.com", que é da Bia, com a senha "abcd1235" (errada): recusado como senha atual errada, 0 trocas
- (servidor) Ana troca para "ana.lima@exemplo.com" com "abcd1234": entrar com "ana.lima@exemplo.com" funciona, com "ana@exemplo.com" não, 1 troca

## REQ-008 Trocar senha [pronto]

Fonte: requisitos-time-control.md, Requisitos, Essencial, req. 17 ("Trocar a senha").

Quando o Usuário pedir para trocar a Senha informando a Senha atual correta e uma senha
nova válida (REQ-003), o sistema deve gravar a senha nova, manter este aparelho dentro e
Encerrar outros aparelhos (REQ-009).

Se a senha nova for igual à Senha atual digitada, então o sistema deve recusar com o Erro
de campo `samePassword` (REQ-011) e não chamar o servidor.

Se a Senha atual estiver errada, então o sistema deve recusar com
`WrongCurrentPasswordFailure` e manter a Senha.

Cenários:
- Atual "abcd1234", nova "wxyz5678" (8 caracteres): repositório chamado 1 vez, e 1 chamada para encerrar outros aparelhos
- Atual "abcd1234", nova "wxyz567" (7 caracteres): recusado com `passwordTooShort`, 0 chamadas ao servidor
- Atual "abcd1234", nova "abcd1234": recusado com `samePassword`, 0 chamadas ao servidor
- Atual "abcd123", nova "abcd123": recusado com 2 erros (`passwordTooShort`, `samePassword`), 0 chamadas ao servidor
- Servidor responde senha atual errada: recusado com `WrongCurrentPasswordFailure`, 0 chamadas para encerrar outros aparelhos
- (servidor) Senha "abcd1234"; troca com atual "abcd1234" e nova "wxyz5678": entrar com "wxyz5678" funciona, com "abcd1234" não, 1 troca
- (servidor) Senha "abcd1234"; troca com atual "abcd1235" e nova "wxyz5678": recusado, Senha continua "abcd1234", 0 trocas

## REQ-009 Outros aparelhos saem na hora após trocar e-mail ou senha [pronto]

Fonte: requisitos-time-control.md, Requisitos, Essencial, req. 17 ("os outros aparelhos saem da conta na hora").

Quando o Usuário trocar o E-mail (REQ-007) ou a Senha (REQ-008), o sistema deve Encerrar
outros aparelhos e manter a sessão do aparelho onde a troca foi feita.

Enquanto outro aparelho estiver com o app aberto, o sistema deve levá-lo para a tela de
entrada assim que o servidor avisar a troca, sem esperar uma ação da pessoa.

Se outro aparelho estiver com o app fechado, então o sistema deve levá-lo para a tela de
entrada ao abrir o app.

Se a troca for recusada, então o sistema deve manter a sessão de todos os aparelhos.

Cenários:
- Troca de Senha aceita: 1 chamada para encerrar outros aparelhos e este aparelho com 1 sessão aberta
- Troca recusada com `WrongCurrentPasswordFailure`: 0 chamadas para encerrar outros aparelhos
- (integração) Ana com o app aberto no celular e no navegador troca a Senha no celular, sem tocar no navegador: 1 sessão aberta (celular), navegador na tela de entrada
- (integração) Ana com sessão em 3 aparelhos, 1 deles fechado, troca o E-mail no navegador: o aparelho aberto vai para a entrada sem ação; o fechado vai ao abrir; 1 sessão aberta (navegador)
- (integração) Ana com sessão em 2 aparelhos; troca recusada por senha atual errada: 2 sessões abertas
