/// Faixas graduais de urgência do prazo (até 14 dias), com o peso usado na
/// fórmula de prioridade. Ver requisito 6.
///
/// O atraso não é uma faixa fechada: a partir de `overdueOrToday` (peso 6) o peso
/// cresce **1 por dia de atraso, sem teto** — quanto mais atrasada, mais urgente.
/// Por isso o peso efetivo vem de [weightForDaysUntilDue], não de [weight].
enum UrgencyBandEnum {
  overdueOrToday(6),
  oneToTwoDays(5),
  threeToFiveDays(4),
  sixToNineDays(3),
  tenToFourteenDays(2),
  beyondFourteen(1);

  const UrgencyBandEnum(this.weight);

  final int weight;

  /// Peso efetivo da urgência para `days` dias até o prazo (negativo = atrasado).
  ///
  /// Dentro do prazo (e no dia do prazo) usa o peso da faixa. Em atraso, soma
  /// 1 por dia atrasado ao peso base 6 — sem teto: 1 dia = 7, 30 dias = 36.
  static int weightForDaysUntilDue(int days) =>
      days < 0 ? overdueOrToday.weight - days : fromDaysUntilDue(days).weight;

  /// Mapeia dias até o prazo (negativo = atrasado) para a faixa.
  static UrgencyBandEnum fromDaysUntilDue(int days) {
    if (days <= 0) return overdueOrToday;
    if (days <= 2) return oneToTwoDays;
    if (days <= 5) return threeToFiveDays;
    if (days <= 9) return sixToNineDays;
    if (days <= 14) return tenToFourteenDays;
    return beyondFourteen;
  }
}
