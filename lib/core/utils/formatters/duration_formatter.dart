/// Formata durações em minutos para exibição na UI (pt-BR).
///
/// Formatação **não** é regra de negócio, mas também não pode ser literal
/// espalhada na tela — vive aqui, no `core`.
class DurationFormatter {
  const DurationFormatter._();

  /// `90` → "1h30" · `45` → "45min" · `120` → "2h".
  static String hm(int minutes) {
    if (minutes <= 0) return '0min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  /// `5` → "00:00:05" · `65` → "00:01:05" · `3661` → "01:01:01".
  /// Sempre 2 dígitos por campo — formato de cronômetro ao vivo (negativo → zero).
  static String hms(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(sec)}';
  }
}
