import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/timer_toggle_button.dart';

void main() {
  Widget harness({required bool isActive, VoidCallback? onPressed}) =>
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TimerToggleButton(
            isActive: isActive,
            onPressed: onPressed ?? () {},
          ),
        ),
      );

  testWidgets('mostra play e tooltip "Iniciar cronômetro" quando parado', (
    tester,
  ) async {
    await tester.pumpWidget(harness(isActive: false));

    expect(find.byIcon(Icons.play_circle_rounded), findsOneWidget);
    expect(find.byTooltip('Iniciar cronômetro'), findsOneWidget);
  });

  testWidgets('mostra stop e tooltip "Parar cronômetro" quando ativo', (
    tester,
  ) async {
    await tester.pumpWidget(harness(isActive: true));

    expect(find.byIcon(Icons.stop_circle_rounded), findsOneWidget);
    expect(find.byTooltip('Parar cronômetro'), findsOneWidget);
  });

  testWidgets('chama onPressed ao tocar', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      harness(isActive: false, onPressed: () => pressed = true),
    );

    await tester.tap(find.byType(IconButton));

    expect(pressed, isTrue);
  });
}
