import 'dart:developer' as developer;

/// Logger central do app. Nunca usar `print`/`debugPrint` — sempre `AppLogger`.
///
/// Usa `dart:developer` (`log`), que respeita níveis e não polui o console do PWA.
class AppLogger {
  const AppLogger._();

  static void logDebug(String message, {String? name}) =>
      developer.log(message, name: name ?? 'DEBUG', level: 500);

  static void logInfo(String message, {String? name}) =>
      developer.log(message, name: name ?? 'INFO', level: 800);

  static void logWarning(String message, {String? name}) =>
      developer.log(message, name: name ?? 'WARN', level: 900);

  static void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? name,
  }) =>
      developer.log(
        message,
        name: name ?? 'ERROR',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
}
