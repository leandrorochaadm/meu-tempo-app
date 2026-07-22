import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/task_running_badge.dart';

void main() {
  Widget harness(DateTime startedAt) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: TaskRunningBadge(startedAt: startedAt)),
      );

  testWidgets('mostra 00:00:00 ao iniciar a sessão', (tester) async {
    await tester.pumpWidget(harness(DateTime.now()));

    expect(find.text('00:00:00'), findsOneWidget);
  });

  testWidgets('mostra o ícone de cronômetro', (tester) async {
    await tester.pumpWidget(harness(DateTime.now()));

    expect(find.byIcon(Icons.timelapse_rounded), findsOneWidget);
  });

  testWidgets('exibe o tempo decorrido de uma sessão em andamento',
      (tester) async {
    // Sessão iniciada há 1h01m05s → o selo mostra o decorrido formatado.
    // (O avanço a cada segundo depende de DateTime.now() real, que o relógio
    // fake do flutter_test não adianta com pump — por isso testamos a fórmula
    // a partir de um startedAt no passado, que é determinístico.)
    final startedAt = DateTime.now().subtract(const Duration(seconds: 3665));
    await tester.pumpWidget(harness(startedAt));

    expect(find.text('01:01:05'), findsOneWidget);
  });

  testWidgets('cancela o Timer no dispose (sem timer pendente)',
      (tester) async {
    await tester.pumpWidget(harness(DateTime.now()));

    // Remove o widget da árvore; se o dispose não cancelasse o Timer, o
    // flutter_test falharia com "A Timer is still pending".
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('reinicia ao trocar o startedAt (didUpdateWidget)',
      (tester) async {
    // Sessão que já dura ~1h → mostra um valor alto.
    final old = DateTime.now().subtract(const Duration(hours: 1));
    await tester.pumpWidget(harness(old));
    expect(find.text('00:00:00'), findsNothing);

    // Nova sessão começa agora → volta perto de zero.
    await tester.pumpWidget(harness(DateTime.now()));
    await tester.pump();
    expect(find.text('00:00:00'), findsOneWidget);
  });
}
