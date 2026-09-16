import '../../domain/entities/effort_band_enum.dart';

/// Apresentação da faixa de esforço: rótulo em PT. Só tradução de exibição — o
/// peso da faixa na prioridade vive no domínio.
extension EffortBandPresentationX on EffortBandEnum {
  String get label => switch (this) {
        EffortBandEnum.quick => 'Rápida',
        EffortBandEnum.short => 'Curta',
        EffortBandEnum.medium => 'Média',
        EffortBandEnum.long => 'Longa',
        EffortBandEnum.veryLong => 'Muito longa',
      };
}
