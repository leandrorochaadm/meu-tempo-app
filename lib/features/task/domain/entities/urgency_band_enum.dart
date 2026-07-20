/// Faixas graduais de urgência do prazo (até 14 dias), com o peso usado na
/// fórmula de prioridade. Ver requisito 6.
enum UrgencyBandEnum {
  overdueOrToday(6),
  oneToTwoDays(5),
  threeToFiveDays(4),
  sixToNineDays(3),
  tenToFourteenDays(2),
  beyondFourteen(1);

  const UrgencyBandEnum(this.weight);

  final int weight;

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
