import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../domain/entities/password_rule_enum.dart';
import '../password_rule_label.dart';

/// Password rules list: green when met, muted when not.
class PasswordChecklistWidget extends StatelessWidget {
  const PasswordChecklistWidget({super.key, required this.metRules});

  final List<PasswordRuleEnum> metRules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in PasswordRuleEnum.values)
          _row(context, rule, metRules.contains(rule)),
      ],
    );
  }

  Widget _row(BuildContext context, PasswordRuleEnum rule, bool met) {
    final color = met ? context.colors.success : context.colors.textMuted;
    return Padding(
      padding: EdgeInsets.only(top: context.space.xs),
      child: Row(
        children: [
          Icon(
            met
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
          ),
          SizedBox(width: context.space.sm),
          Expanded(
            child: Text(
              rule.label,
              style: context.text.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
