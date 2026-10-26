/// Estado do cronômetro ativo: contando ou pausado (continua à vista até
/// continuar, parar ou dar start em outro alvo).
enum TimerStatusEnum {
  running('running'),
  paused('paused');

  const TimerStatusEnum(this.apiValue);

  /// Grafia gravada no backend (campo `status` do registro do cronômetro ativo).
  final String apiValue;

  /// Converte o valor cru do backend. Ausente (registro gravado antes do estado
  /// pausado existir) ou desconhecido → [running], que era o único estado.
  static TimerStatusEnum fromApi(String? raw) {
    for (final status in values) {
      if (status.apiValue == raw) return status;
    }
    return running;
  }
}
