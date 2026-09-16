import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/effort_band_enum.dart';

void main() {
  test('mapeia minutos para a faixa, com o limite superior incluso', () {
    expect(EffortBandEnum.fromEstimatedMinutes(1), EffortBandEnum.quick);
    expect(EffortBandEnum.fromEstimatedMinutes(15), EffortBandEnum.quick);
    expect(EffortBandEnum.fromEstimatedMinutes(16), EffortBandEnum.short);
    expect(EffortBandEnum.fromEstimatedMinutes(30), EffortBandEnum.short);
    expect(EffortBandEnum.fromEstimatedMinutes(31), EffortBandEnum.medium);
    expect(EffortBandEnum.fromEstimatedMinutes(60), EffortBandEnum.medium);
    expect(EffortBandEnum.fromEstimatedMinutes(61), EffortBandEnum.long);
    expect(EffortBandEnum.fromEstimatedMinutes(180), EffortBandEnum.long);
    expect(EffortBandEnum.fromEstimatedMinutes(181), EffortBandEnum.veryLong);
    expect(EffortBandEnum.fromEstimatedMinutes(480), EffortBandEnum.veryLong);
  });

  test('o padrão da criação rápida (30 min) tem faixa própria', () {
    expect(EffortBandEnum.fromEstimatedMinutes(30), EffortBandEnum.short);
    // Não divide faixa com 1 h, o corte vizinho mais comum.
    expect(
      EffortBandEnum.fromEstimatedMinutes(60),
      isNot(EffortBandEnum.fromEstimatedMinutes(30)),
    );
  });

  test('sem estimativa cai na faixa mais fraca', () {
    expect(EffortBandEnum.fromEstimatedMinutes(0), EffortBandEnum.quick);
  });

  test('pesos sobem de 1 em 1 a partir de 1', () {
    expect(EffortBandEnum.values.map((b) => b.weight), [1, 2, 3, 4, 5]);
  });
}
