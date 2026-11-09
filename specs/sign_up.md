# Criar conta

Fora do escopo: "Esqueci a senha". Quem esquecer fala com quem cuida do app, que redefine a
senha no servidor (requisitos-time-control.md, req. 16).

Cenários marcados com "(servidor)", "(integração)" ou "(teste de widget)" não se testam no
domínio: vão para o `tool/pb_permissions_test.py`, para um teste de integração ou para um
teste de widget. Os demais são do UseCase.

## REQ-001 Criar conta pelo app [pronto]

Fonte: requisitos-time-control.md, Requisitos, Essencial, req. 16 ("Criar conta pelo app").

Quando uma pessoa sem sessão pedir para criar conta com Nome válido (REQ-002), E-mail bem
escrito (REQ-010) e ainda sem conta (REQ-005), Senha válida (REQ-003) e Aceite da política
de privacidade (REQ-004), o sistema deve criar o Usuário e iniciar a sessão dele, sem
confirmação de e-mail.

O sistema deve gravar o Nome sem os espaços das pontas e o E-mail normalizado (REQ-005).

Quando a conta nova entrar pela primeira vez, o sistema deve seguir o primeiro acesso
guiado: lista "Entrada" (req. 5) e 1 tarefa de exemplo (req. 13).

Cenários:
- Nome "Ana", E-mail "ana@exemplo.com", Senha "abcd1234", aceite marcado: repositório chamado 1 vez com Nome "Ana", E-mail "ana@exemplo.com", Senha "abcd1234"
- Nome "  Ana  ", E-mail " Ana@Exemplo.com ", Senha "abcd1234", aceite marcado: repositório chamado 1 vez com Nome "Ana" e E-mail "ana@exemplo.com"
- (integração) conta "ana@exemplo.com" recém-criada abre o app: sessão iniciada, 1 lista ("Entrada") e 1 tarefa de exemplo
- (servidor) contas "ana@exemplo.com" e "bia@exemplo.com"; Bia lista as tarefas: 0 tarefas da Ana

## REQ-002 Nome válido [pronto]

Fonte: requisitos-time-control.md, Requisitos, Essencial, req. 16 ("Nome: de 2 a 50 caracteres") e req. 17 ("mesmos limites do cadastro").

O sistema deve contar os caracteres do Nome depois de tirar os espaços das pontas e do
jeito que a pessoa vê: um emoji ou uma letra acentuada contam 1. Espaço no meio conta.
Vale para Criar conta e para Editar nome.

Se o Nome tiver menos de 2 caracteres, então o sistema deve recusar com o Erro de campo
`displayNameLength` (REQ-011) e não gravar nada.

Se o Nome tiver mais de 50 caracteres, então o sistema deve recusar com o Erro de campo
`displayNameLength` (REQ-011) e não gravar nada.

Cenários:
- Criar conta, Nome "A" (1 caractere): recusado com `displayNameLength`, 0 contas criadas
- Criar conta, Nome "Al" (2 caracteres): aceito, Nome com 2 caracteres
- Criar conta, Nome "Ana" (3 caracteres): aceito, Nome com 3 caracteres
- Criar conta, Nome "A B" (3 caracteres, espaço no meio): aceito, Nome "A B" com 3 caracteres
- Criar conta, Nome "   " (só espaços): recusado com `displayNameLength`, 0 contas criadas
- Criar conta, Nome " A " (espaço, letra, espaço): recusado com `displayNameLength`, 0 contas criadas
- Criar conta, Nome "😀😀" (2 caracteres, 2 emojis): aceito, Nome com 2 caracteres
- Criar conta, Nome "😀" (1 emoji): recusado com `displayNameLength`, 0 contas criadas
- Criar conta, Nome "José" com o "é" escrito como "e" + acento combinado (4 caracteres): aceito, Nome com 4 caracteres
- Editar nome, Nome com 49 caracteres: aceito, Nome com 49 caracteres
- Editar nome, Nome com 50 caracteres: aceito, Nome com 50 caracteres
- Editar nome, Nome com 51 caracteres: recusado com `displayNameLength`, Nome anterior mantido, 0 gravações
- Editar nome, Nome com 50 caracteres e 2 espaços em cada ponta: aceito, Nome com 50 caracteres

## REQ-003 Senha de 8 a 71 caracteres [pronto]

Fonte: requisitos-time-control.md, Requisitos, Essencial, req. 16 ("Senha: de 8 a 71 caracteres, valendo exatamente como digitada").

O sistema deve usar a Senha exatamente como digitada, sem tirar espaços. Vale para Criar
conta e para a senha nova em Trocar senha.

Se a Senha tiver menos de 8 caracteres, então o sistema deve recusar com o Erro de campo
`passwordTooShort` (REQ-011) e não gravar nada.

Se a Senha tiver mais de 71 caracteres, então o sistema deve recusar com o Erro de campo
`passwordTooLong` (REQ-011) e não gravar nada.

Cenários:
- Senha "abcd123" (7 caracteres): recusada com `passwordTooShort`, 0 contas criadas
- Senha "abcd1234" (8 caracteres): aceita, 1 conta criada
- Senha "abcd12345" (9 caracteres): aceita, 1 conta criada
- Senha " abcd123" (8 caracteres, 1 espaço no início): aceita, gravada com 8 caracteres
- Senha vazia: recusada com `passwordTooShort`, 0 contas criadas
- Senha com 70 caracteres: aceita, 1 conta criada
- Senha com 71 caracteres: aceita, 1 conta criada
- Senha com 72 caracteres: recusada com `passwordTooLong`, 0 contas criadas

## REQ-004 Aceite obrigatório da política de privacidade [pronto]

Fonte: requisitos-time-control.md, Requisitos, Essencial, req. 16 ("Política de privacidade").

O sistema deve mostrar no cadastro a caixa "Li e aceito a política de privacidade", com
link para a política de privacidade, desmarcada ao abrir a tela.

Se a pessoa pedir para criar conta sem marcar a caixa, então o sistema deve recusar com o
Erro de campo `privacyPolicyNotAccepted` (REQ-011) e não criar a conta.

Cenários:
- Nome "Ana", E-mail "ana@exemplo.com", Senha "abcd1234", aceite desmarcado: recusado com `privacyPolicyNotAccepted`, 0 contas criadas
- Mesmos dados, aceite marcado: 1 conta criada
- (teste de widget) tela de cadastro aberta: 1 caixa desmarcada e 1 link para a política

## REQ-005 E-mail normalizado e já cadastrado [pronto]

Fonte: requisitos-time-control.md, Requisitos, Essencial, req. 16 ("É guardado em minúsculas e sem espaços nas pontas" e "E-mail que já tem conta não cria outra").

O sistema deve Normalizar o e-mail (tirar os espaços das pontas e passar para minúsculas)
antes de criar conta, entrar no app e trocar o e-mail.

Se a pessoa pedir para criar conta com um E-mail que, normalizado, já tem conta, então o
sistema deve recusar com `EmailAlreadyInUseFailure` e não criar outra conta.

Cenários:
- E-mail " Ana@Exemplo.com " ao criar conta: repositório recebe "ana@exemplo.com", 1 chamada
- E-mail "ANA@EXEMPLO.COM" e Senha "abcd1234" ao entrar: repositório recebe "ana@exemplo.com", 1 chamada
- Repositório responde que "ana@exemplo.com" já tem conta: recusado com `EmailAlreadyInUseFailure`, 0 contas novas
- (servidor) conta "ana@exemplo.com" existe; cadastro com "ana@exemplo.com": recusado, continua 1 conta
- (servidor) conta "ana@exemplo.com" existe; cadastro com "ana1@exemplo.com": 2 contas

## REQ-010 E-mail bem escrito [pronto]

Fonte: requisitos-time-control.md, Requisitos, Essencial, req. 16 ("E-mail: precisa estar bem escrito").

O sistema deve aceitar o E-mail normalizado só quando ele tiver exatamente 1 "@", pelo
menos 1 caractere antes do "@", e depois do "@" um domínio com pelo menos 1 ponto que não
fica no começo nem no fim. Vale para Criar conta e para Trocar e-mail.

Se o E-mail não seguir esse formato, então o sistema deve recusar com o Erro de campo
`invalidEmail` (REQ-011) e não gravar nada.

Cenários:
- E-mail "ana@exemplo.com": aceito, 1 conta criada
- E-mail "a@b.co": aceito, 1 conta criada
- E-mail "ana@": recusado com `invalidEmail`, 0 contas criadas
- E-mail "ana.exemplo.com" (nenhum "@"): recusado com `invalidEmail`, 0 contas criadas
- E-mail vazio: recusado com `invalidEmail`, 0 contas criadas
- E-mail "@exemplo.com" (nada antes do "@"): recusado com `invalidEmail`, 0 contas criadas
- E-mail "ana@@exemplo.com" (dois "@"): recusado com `invalidEmail`, 0 contas criadas
- E-mail "ana@exemplo" (domínio sem ponto): recusado com `invalidEmail`, 0 contas criadas
- E-mail "ana@exemplo." (ponto no fim): recusado com `invalidEmail`, 0 contas criadas
- E-mail "ana@.exemplo.com" (ponto no começo do domínio): recusado com `invalidEmail`, 0 contas criadas

## REQ-011 Avisos de todos os campos de uma vez [pronto]

Fonte: requisitos-time-control.md, Requisitos, Essencial, req. 16 ("Avisos todos de uma vez") e req. 17 ("avisos todos de uma vez").

Quando a pessoa pedir para criar conta, editar o nome, trocar o e-mail ou trocar a senha,
o sistema deve conferir todos os campos no app antes de chamar o servidor e, havendo
erro, recusar com `InvalidAccountFieldsFailure` levando todos os Erros de campo
encontrados, sem chamar o servidor.

Se os campos passarem na conferência do app, então o sistema deve chamar o servidor e
devolver só o erro dele (`EmailAlreadyInUseFailure` ou `WrongCurrentPasswordFailure`).

Cenários:
- Criar conta com Nome "A", E-mail "ana@", Senha "abc" e aceite desmarcado: recusado com 4 erros (`displayNameLength`, `invalidEmail`, `passwordTooShort`, `privacyPolicyNotAccepted`), 0 chamadas ao servidor
- Criar conta com Nome "Ana", E-mail "ana@", Senha "abcd1234" e aceite marcado: recusado com 1 erro (`invalidEmail`), 0 chamadas ao servidor
- Criar conta com dados válidos e servidor dizendo que o e-mail já tem conta: recusado com `EmailAlreadyInUseFailure`, 1 chamada ao servidor
