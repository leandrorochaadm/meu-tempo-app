/// Formata "minutos a partir da meia-noite" como relógio "HH:mm".
class TimeFormatter {
  const TimeFormatter._();

  static String clock(int minuteOfDay) {
    final h = (minuteOfDay ~/ 60) % 24;
    final m = minuteOfDay % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
