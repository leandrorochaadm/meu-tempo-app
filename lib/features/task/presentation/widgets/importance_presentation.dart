import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../domain/entities/importance_enum.dart';

/// Apresentação da importância: rótulo em PT e cor semântica (via tokens do
/// tema). Só tradução de exibição — a regra de negócio da importância (o peso
/// `5 − value` na prioridade) vive no domínio.
extension ImportancePresentationX on ImportanceEnum {
  String get label => switch (this) {
        ImportanceEnum.max => 'Máxima',
        ImportanceEnum.high => 'Alta',
        ImportanceEnum.low => 'Baixa',
        ImportanceEnum.min => 'Mínima',
      };

  Color colorOf(BuildContext context) {
    final colors = context.colors;
    return switch (this) {
      ImportanceEnum.max => colors.danger,
      ImportanceEnum.high => colors.warning,
      ImportanceEnum.low => colors.info,
      ImportanceEnum.min => colors.textMuted,
    };
  }
}
