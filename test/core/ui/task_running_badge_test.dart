import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/task_running_badge.dart';

void main() {
  Widget harness() => MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: TaskRunningBadge()),
      );

  testWidgets('shows the "rodando" label', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.text('rodando'), findsOneWidget);
  });

  testWidgets('shows the timelapse icon', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.byIcon(Icons.timelapse_rounded), findsOneWidget);
  });
}
