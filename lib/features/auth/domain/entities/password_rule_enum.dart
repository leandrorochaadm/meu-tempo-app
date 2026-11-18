const int passwordMinLength = 8; // REQ-003
const int passwordMaxLength = 71; // REQ-003

final RegExp _asciiDigit = RegExp(r'[0-9]');

/// Length in code points, the way the server counts it.
int passwordLength(String password) => password.runes.length;

/// Password rules shown to the person (REQ-003).
enum PasswordRuleEnum {
  minLength,
  digit,
  uppercase,
  lowercase;

  /// Whether [password], used exactly as typed, meets this rule.
  bool isMetBy(String password) => switch (this) {
    PasswordRuleEnum.minLength => passwordLength(password) >= passwordMinLength,
    PasswordRuleEnum.digit => _asciiDigit.hasMatch(password),
    PasswordRuleEnum.uppercase => password != password.toLowerCase(),
    PasswordRuleEnum.lowercase => password != password.toUpperCase(),
  };
}
