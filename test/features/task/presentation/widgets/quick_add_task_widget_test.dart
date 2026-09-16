import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/quick_add_target_entity.dart';
import 'package:meu_tempo/features/task/presentation/widgets/quick_add_task_widget.dart';

void main() {
  const mae = QuickAddTargetEntity(
    taskId: 'p1',
    title: 'Lançar app',
    listId: 'trabalho',
    level: 0,
  );
  const filha = QuickAddTargetEntity(
    taskId: 'f1',
    title: 'Fazer telas',
    listId: 'trabalho',
    level: 1,
  );

  Widget harness({
    void Function(String)? onSubmit,
    void Function(String)? onSubmitAndStart,
    QuickAddTargetEntity? target,
    QuickAddTargetEntity? offeredParent,
    void Function(QuickAddTargetEntity?)? onTargetChanged,
    List<TaskListEntity> lists = const [],
    String? selectedListId,
    void Function(String)? onListSelected,
  }) =>
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: QuickAddTaskWidget(
            onSubmit: onSubmit ?? (_) {},
            onSubmitAndStart: onSubmitAndStart ?? (_) {},
            target: target,
            offeredParent: offeredParent,
            onTargetChanged: onTargetChanged,
            lists: lists,
            selectedListId: selectedListId,
            onListSelected: onListSelected,
          ),
        ),
      );

  testWidgets('sem alvo cria tarefa mãe: placeholder e sem faixa de contexto',
      (tester) async {
    await tester.pumpWidget(harness());

    expect(find.text('Nova tarefa…'), findsOneWidget);
    expect(find.textContaining('dentro de'), findsNothing);
  });

  testWidgets('com alvo mostra a faixa de contexto e o placeholder de filha',
      (tester) async {
    await tester.pumpWidget(harness(target: mae));

    expect(find.text('dentro de "Lançar app"'), findsOneWidget);
    expect(find.text('Nova filha…'), findsOneWidget);
  });

  testWidgets('alvo de nível 1 lança neta', (tester) async {
    await tester.pumpWidget(harness(target: filha));

    expect(find.text('Nova neta…'), findsOneWidget);
  });

  testWidgets('✕ da faixa volta a criar tarefa mãe (alvo null)',
      (tester) async {
    var cleared = false;
    QuickAddTargetEntity? received = mae;
    await tester.pumpWidget(harness(
      target: mae,
      onTargetChanged: (t) {
        cleared = true;
        received = t;
      },
    ));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(cleared, isTrue);
    expect(received, isNull);
  });

  testWidgets('↑ só cria; ▶ cria e pede o cronômetro', (tester) async {
    String? criada;
    String? criadaComTimer;
    await tester.pumpWidget(harness(
      onSubmit: (t) => criada = t,
      onSubmitAndStart: (t) => criadaComTimer = t,
    ));

    await tester.enterText(find.byType(TextField), 'Estudar');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(criada, 'Estudar');
    expect(criadaComTimer, isNull);

    await tester.enterText(find.byType(TextField), 'Correr');
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(criadaComTimer, 'Correr');
  });

  testWidgets('título vazio não cria nada', (tester) async {
    var chamou = false;
    await tester.pumpWidget(harness(onSubmit: (_) => chamou = true));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    expect(chamou, isFalse);
  });

  testWidgets('a oferta de mãe vira chip que aponta a barra para dentro dela',
      (tester) async {
    QuickAddTargetEntity? escolhido;
    await tester.pumpWidget(harness(
      offeredParent: mae,
      onTargetChanged: (t) => escolhido = t,
    ));

    expect(find.text('Tarefa mãe'), findsOneWidget);
    await tester.tap(find.text('filha de "Lançar app"'));
    await tester.pump();

    expect(escolhido, mae);
  });

  testWidgets('chips de lista aparecem só no modo raiz (filha herda a lista)',
      (tester) async {
    const lists = [
      TaskListEntity(id: 'inbox', name: 'Entrada', isDefault: true),
      TaskListEntity(id: 'trabalho', name: 'Trabalho'),
    ];

    await tester.pumpWidget(harness(
      lists: lists,
      selectedListId: 'trabalho',
      onListSelected: (_) {},
    ));
    expect(find.text('Trabalho'), findsOneWidget);

    await tester.pumpWidget(harness(
      target: mae,
      lists: lists,
      selectedListId: 'trabalho',
      onListSelected: (_) {},
    ));
    expect(find.text('Trabalho'), findsNothing);
  });
}
