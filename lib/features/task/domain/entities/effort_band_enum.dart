/// Faixas de esforço da folha, com o peso usado na fórmula de prioridade.
///
/// O tempo estimado entra na fórmula **pela faixa**, não em minutos crus: em
/// minutos ele varia ~100× (5 min a 8 h) contra 4× da importância e 6× da
/// urgência, e acabava engolindo os dois. Com peso 1–5 os três fatores ficam na
/// mesma escala e "mais longa vem primeiro" continua valendo — só deixa de
/// atropelar prazo e importância.
enum EffortBandEnum {
  quick(1),
  short(2),
  medium(3),
  long(4),
  veryLong(5);

  const EffortBandEnum(this.weight);

  /// Peso na fórmula de prioridade.
  final int weight;

  static const int quickMaxMinutes = 15;

  /// 30 min é o tempo estimado padrão da criação rápida (`AppDefaults`) e o
  /// corte mais comum na prática — por isso tem faixa própria, em vez de cair
  /// na mesma faixa de 1 h.
  static const int shortMaxMinutes = 30;
  static const int mediumMaxMinutes = 60;
  static const int longMaxMinutes = 180;

  /// Faixa de `minutes` de tempo estimado (limite superior incluso).
  static EffortBandEnum fromEstimatedMinutes(int minutes) {
    if (minutes <= quickMaxMinutes) return quick;
    if (minutes <= shortMaxMinutes) return short;
    if (minutes <= mediumMaxMinutes) return medium;
    if (minutes <= longMaxMinutes) return long;
    return veryLong;
  }
}
