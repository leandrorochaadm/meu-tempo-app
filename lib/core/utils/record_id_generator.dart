import 'dart:math';

/// Gera ids no formato padrão do PocketBase (15 caracteres `a-z0-9`), para
/// encadear registros criados no mesmo lote.
abstract final class RecordIdGenerator {
  static const String _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  static const int _length = 15;
  static final Random _random = Random.secure();

  static String next() => String.fromCharCodes(
    List.generate(
      _length,
      (_) => _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
    ),
  );
}
