import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/task/presentation/pages/edit_task_args.dart';
import 'package:meu_tempo/features/task/presentation/widgets/task_parent_picker.dart';

void main() {
  const candidates = [
    ParentCandidate(id: 'm1', title: 'Lançar app', path: 'tarefa mãe'),
    ParentCandidate(
        id: 'f1', title: 'Fazer telas', path: 'Lançar app · tarefa filha'),
  ];

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('lista candidatos, raiz e cancelar', (tester) async {
    setView(tester);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showTaskParentPicker(ctx, candidates),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Tornar tarefa mãe (raiz)'), findsOneWidget);
    expect(find.text('Lançar app'), findsOneWidget);
    expect(find.text('Fazer telas'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('escolher um candidato devolve seu id', (tester) async {
    setView(tester);
    String? chosen;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async =>
                chosen = await showTaskParentPicker(ctx, candidates),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fazer telas'));
    await tester.pumpAndSettle();

    expect(chosen, 'f1');
  });

  testWidgets('escolher raiz devolve a sentinela', (tester) async {
    setView(tester);
    String? chosen;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async =>
                chosen = await showTaskParentPicker(ctx, candidates),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tornar tarefa mãe (raiz)'));
    await tester.pumpAndSettle();

    expect(chosen, kMakeRootSentinel);
  });
}
