/// Chaves do armazenamento seguro do aparelho (Keychain/Keystore), guardadas
/// via `flutter_secure_storage`. Nunca usar a string literal espalhada pelo
/// código (regra `enums.md`) — sempre referenciar por aqui.
class SecureStorageKeys {
  const SecureStorageKeys._();

  /// Sessão do PocketBase (token + usuário).
  static const String pocketBaseAuth = 'pb_auth';
}
