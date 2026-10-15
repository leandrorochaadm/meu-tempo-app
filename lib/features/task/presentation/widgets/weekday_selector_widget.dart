import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../domain/entities/weekday_enum.dart';
import 'weekday_presentation.dart';

/// Seletor dos 7 dias da semana (seg→dom) + atalho "Todo dia". Controlado: o
/// estado fica no formulário; cada toque devolve um Set **novo** em [onChanged].
class WeekdaySelectorWidget extends StatelessWidget {
  const WeekdaySelectorWidget({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<WeekdayEnum> selected;
  final ValueChanged<Set<WeekdayEnum>> onChanged;

  @override
  Widget build(BuildContext context) {
    final allSelected = selected.containsAll(WeekdayEnum.values);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final day in WeekdayEnum.values)
              Expanded(
                child: _WeekdayToggle(
                  day: day,
                  isSelected: selected.contains(day),
                  onTap: () => onChanged(
                    selected.contains(day)
                        ? ({...selected}..remove(day))
                        : {...selected, day},
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: context.space.sm),
        ChoiceChip(
          label: const Text('Todo dia'),
          selected: allSelected,
          onSelected: (_) => onChanged(
            allSelected ? <WeekdayEnum>{} : WeekdayEnum.values.toSet(),
          ),
        ),
        SizedBox(height: context.space.sm),
        Text(
          selected.isEmpty
              ? 'Sem dia fixo: só entra na lista pelo botão “Adicionar hoje”.'
              : 'Entra sozinha na sua lista nos dias marcados.',
          style: context.text.bodySmall?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _WeekdayToggle extends StatelessWidget {
  const _WeekdayToggle({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final WeekdayEnum day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      label: day.label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          height: kMinInteractiveDimension,
          margin: EdgeInsets.symmetric(horizontal: context.space.xs),
          alignment: Alignment.center,
          duration: context.motion.fast,
          curve: context.motion.curve,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? colors.primary : colors.surfaceHigh,
            border: isSelected ? null : Border.all(color: colors.border),
          ),
          child: ExcludeSemantics(
            child: Text(
              day.shortLabel,
              style: context.text.labelLarge?.copyWith(
                color: isSelected ? colors.onPrimary : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
