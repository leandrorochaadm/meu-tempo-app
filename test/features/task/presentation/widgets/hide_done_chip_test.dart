import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/task/presentation/widgets/hide_done_chip.dart';

void main() {
  Widget harness({required bool hideDone, required void Function(bool) onChanged}) =>
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: HideDoneChip(hideDone: hideDone, onChanged: onChanged),
        ),
      );

  testWidgets('quando ocultas, rótulo/ícone descrevem a ação de mostrar',
      (tester) async {
    await tester.pumpWidget(harness(hideDone: true, onChanged: (_) {}));

    expect(find.text('Mostrar concluídas'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
  });

  testWidgets('quando visíveis, rótulo/ícone descrevem a ação de ocultar',
      (tester) async {
    await tester.pumpWidget(harness(hideDone: false, onChanged: (_) {}));

    expect(find.text('Ocultar concluídas'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
  });

  testWidgets('tocar quando ocultas pede exibir (false)', (tester) async {
    bool? received;
    await tester
        .pumpWidget(harness(hideDone: true, onChanged: (v) => received = v));

    await tester.tap(find.byType(ActionChip));
    await tester.pump();

    expect(received, isFalse);
  });

  testWidgets('tocar quando visíveis pede ocultar (true)', (tester) async {
    bool? received;
    await tester
        .pumpWidget(harness(hideDone: false, onChanged: (v) => received = v));

    await tester.tap(find.byType(ActionChip));
    await tester.pump();

    expect(received, isTrue);
  });
}
