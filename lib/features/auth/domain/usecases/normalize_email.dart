/// Normalizes an e-mail: trims the ends and lowercases it.
String normalizeEmail(String raw) {
  // REQ-005
  return raw.trim().toLowerCase();
}
