import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/auth/domain/entities/password_rule_enum.dart';
import 'package:meu_tempo/features/auth/presentation/widgets/password_checklist_widget.dart';

void main() {
  // REQ-012: checklist with minLength and lowercase met: 4 rules in order, 2 green, 2 not green
  testWidgets('should show 4 rules in order with met ones green', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: PasswordChecklistWidget(
            metRules: [PasswordRuleEnum.minLength, PasswordRuleEnum.lowercase],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(2));

    final texts = [
      'Pelo menos 8 caracteres',
      'Pelo menos 1 número',
      'Pelo menos 1 letra maiúscula',
      'Pelo menos 1 letra minúscula',
    ];
    for (final text in texts) {
      expect(find.text(text), findsOneWidget);
    }
    final tops = texts.map((t) => tester.getTopLeft(find.text(t)).dy).toList();
    expect(tops, [...tops]..sort());

    final metColor = tester.widget<Text>(find.text(texts[0])).style?.color;
    final unmetColor = tester.widget<Text>(find.text(texts[1])).style?.color;
    expect(tester.widget<Text>(find.text(texts[3])).style?.color, metColor);
    expect(tester.widget<Text>(find.text(texts[2])).style?.color, unmetColor);
    expect(metColor, isNot(unmetColor));
  });
}
