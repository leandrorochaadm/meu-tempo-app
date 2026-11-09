# Glossário

| Termo | No código | Definição |
|---|---|---|
| Usuário | `UserEntity` | Pessoa com conta no app; dona dos próprios dados. |
| Nome | `UserEntity.displayName` | Nome da pessoa, mostrado no Perfil. Vazio só em conta antiga (REQ-006). Limites em REQ-002. |
| E-mail | `UserEntity.email` | Endereço usado para entrar no app. Formato em REQ-010; guardado normalizado (REQ-005). |
| Normalizar e-mail | `normalizeEmail` | Tira os espaços das pontas e passa para minúsculas (REQ-005). |
| Senha | `SignUpParams.password` | Segredo usado para entrar no app, valendo exatamente como digitado. Limites em REQ-003. |
| Criar conta | `SignUpUseCase` | Cadastro aberto feito pela própria pessoa no app (REQ-001). |
| Aceite da política de privacidade | `SignUpParams.acceptedPrivacyPolicy` | Caixa marcada pela pessoa no cadastro (REQ-004). |
| Perfil | `ProfileSection` | Parte da tela de Configurações (`SettingsPage`) onde o Usuário edita Nome, E-mail e Senha. |
| Editar nome | `UpdateDisplayNameUseCase` | Troca do Nome no Perfil (REQ-006). |
| Trocar e-mail | `ChangeEmailUseCase` | Troca do E-mail no Perfil, com a Senha atual (REQ-007). |
| Trocar senha | `ChangePasswordUseCase` | Troca da Senha no Perfil, com a Senha atual (REQ-008). |
| Senha atual (troca de e-mail) | `ChangeEmailParams.currentPassword` | Senha digitada para confirmar a troca do E-mail. |
| Senha atual (troca de senha) | `ChangePasswordParams.currentPassword` | Senha digitada para confirmar a troca da Senha. |
| Encerrar outros aparelhos | `AuthRepository.signOutOtherDevices` | Tira da conta todos os aparelhos, menos aquele onde a troca foi feita (REQ-009). |
| Erro de campo | `AccountFieldErrorEnum` | Motivo de recusa de um campo, conferido no app: `displayNameLength`, `sameDisplayName`, `invalidEmail`, `sameEmail`, `passwordTooShort`, `passwordTooLong`, `samePassword`, `privacyPolicyNotAccepted` (REQ-011). |
| Campos inválidos | `InvalidAccountFieldsFailure` | Recusa com todos os Erros de campo de uma vez (REQ-011), em `auth_failures.dart`. |
| E-mail já usado | `EmailAlreadyInUseFailure` | O servidor recusou porque outra conta tem esse E-mail (REQ-005, REQ-007), em `auth_failures.dart`. |
| Senha atual errada | `WrongCurrentPasswordFailure` | O servidor recusou a Senha atual (REQ-007, REQ-008), em `auth_failures.dart`. |
