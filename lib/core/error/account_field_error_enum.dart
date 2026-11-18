/// Reasons an account field (name, e-mail, password, consent) is refused.
enum AccountFieldErrorEnum {
  displayNameLength,
  sameDisplayName,
  invalidEmail,
  sameEmail,
  passwordTooShort,
  passwordTooLong,
  passwordMissingDigit,
  passwordMissingUppercase,
  passwordMissingLowercase,
  samePassword,
  privacyPolicyNotAccepted,
}
