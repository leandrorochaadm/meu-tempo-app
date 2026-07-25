import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/priority_breakdown.dart';
import 'package:meu_tempo/features/task/presentation/widgets/priority_info_button.dart';

void main() {
  Widget harness(PriorityBreakdown breakdown) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: PriorityInfoButton(breakdown: breakdown)),
      );

  Future<void> openDialog(WidgetTester tester, PriorityBreakdown b) async {
    await tester.pumpWidget(harness(b));
    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra os fatores e a conta final', (tester) async {
    await openDialog(
      tester,
      const PriorityBreakdown(
        estimatedMinutes: 60,
        importance: ImportanceEnum.max,
        urgencyWeight: 6,
        daysUntilDue: 0,
      ),
    );

    expect(find.text('Como calculamos'), findsOneWidget);
    expect(find.text('1h'), findsOneWidget); // tempo estimado formatado
    expect(find.text('Máxima (5 − 1 = 4)'), findsOneWidget);
    expect(find.text('6 (vence hoje)'), findsOneWidget);
    expect(find.text('60 × 4 × 6 = 1440'), findsOneWidget);
  });

  testWidgets('explica o atraso em dias na urgência', (tester) async {
    await openDialog(
      tester,
      const PriorityBreakdown(
        estimatedMinutes: 30,
        importance: ImportanceEnum.min,
        urgencyWeight: 11,
        daysUntilDue: -5,
      ),
    );

    expect(find.text('11 (atrasada 5 dias)'), findsOneWidget);
    expect(find.text('30 × 1 × 11 = 330'), findsOneWidget);
  });

  testWidgets('atraso de 1 dia usa singular', (tester) async {
    await openDialog(
      tester,
      const PriorityBreakdown(
        estimatedMinutes: 30,
        importance: ImportanceEnum.min,
        urgencyWeight: 7,
        daysUntilDue: -1,
      ),
    );

    expect(find.text('7 (atrasada 1 dia)'), findsOneWidget);
  });

  testWidgets('sem prazo informa "sem prazo"', (tester) async {
    await openDialog(
      tester,
      const PriorityBreakdown(
        estimatedMinutes: 30,
        importance: ImportanceEnum.min,
        urgencyWeight: 1,
        daysUntilDue: null,
      ),
    );

    expect(find.text('1 (sem prazo)'), findsOneWidget);
  });

  testWidgets('fecha ao tocar em Entendi', (tester) async {
    await openDialog(
      tester,
      const PriorityBreakdown(
        estimatedMinutes: 30,
        importance: ImportanceEnum.min,
        urgencyWeight: 1,
        daysUntilDue: null,
      ),
    );

    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(find.text('Como calculamos'), findsNothing);
  });
}
