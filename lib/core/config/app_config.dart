/// Build-time configuration, read from `config/<env>.json` through
/// `--dart-define-from-file`.
abstract final class AppConfig {
  static const pocketBaseUrlKey = 'POCKETBASE_URL';

  // `String.fromEnvironment` must be `const`; otherwise it returns empty in
  // release and web builds.
  static const String pocketBaseUrl = String.fromEnvironment(pocketBaseUrlKey);

  /// Required keys that are empty or blank.
  static List<String> get missingKeys => [
    if (pocketBaseUrl.trim().isEmpty) pocketBaseUrlKey,
  ];
}
