import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/swipe_action_tile.dart';

void main() {
  late bool completeCalled;
  late bool editCalled;
  late bool deleteCalled;

  setUp(() {
    completeCalled = false;
    editCalled = false;
    deleteCalled = false;
  });

  // [canComplete] false simula mãe/avó (sem conclusão).
  Widget harness({bool canComplete = true}) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SwipeActionTile(
            itemKey: const ValueKey('task-1'),
            onSwipeComplete: canComplete ? () => completeCalled = true : null,
            onSwipeEdit: () => editCalled = true,
            onLongPressDelete: () => deleteCalled = true,
            child: const SizedBox(
              height: 80,
              width: double.infinity,
              child: Text('Tarefa'),
            ),
          ),
        ),
      );

  testWidgets('arrastar da esquerda para a direita conclui a tarefa',
      (tester) async {
    await tester.pumpWidget(harness());

    await tester.drag(find.text('Tarefa'), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(completeCalled, isTrue);
    expect(editCalled, isFalse);
    // Não descarta de fato: o item continua na tela.
    expect(find.text('Tarefa'), findsOneWidget);
  });

  testWidgets('arrastar da direita para a esquerda edita a tarefa',
      (tester) async {
    await tester.pumpWidget(harness());

    await tester.drag(find.text('Tarefa'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(editCalled, isTrue);
    expect(completeCalled, isFalse);
    expect(find.text('Tarefa'), findsOneWidget);
  });

  testWidgets('clique longo exclui a tarefa', (tester) async {
    await tester.pumpWidget(harness());

    await tester.longPress(find.text('Tarefa'));
    await tester.pumpAndSettle();

    expect(deleteCalled, isTrue);
    expect(completeCalled, isFalse);
    expect(editCalled, isFalse);
  });

  testWidgets(
      'sem conclusão (mãe/avó): arrastar para a direita não faz nada',
      (tester) async {
    await tester.pumpWidget(harness(canComplete: false));

    await tester.drag(find.text('Tarefa'), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(completeCalled, isFalse);
    expect(editCalled, isFalse);
    expect(find.text('Tarefa'), findsOneWidget);
  });

  testWidgets('sem conclusão (mãe/avó): arrastar para a esquerda ainda edita',
      (tester) async {
    await tester.pumpWidget(harness(canComplete: false));

    await tester.drag(find.text('Tarefa'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(editCalled, isTrue);
  });

  testWidgets('sem conclusão (mãe/avó): clique longo continua excluindo',
      (tester) async {
    await tester.pumpWidget(harness(canComplete: false));

    await tester.longPress(find.text('Tarefa'));
    await tester.pumpAndSettle();

    expect(deleteCalled, isTrue);
  });

  group('threshold do arrasto (0.25)', () {
    testWidgets('arrasto pequeno não dispara a conclusão', (tester) async {
      await tester.pumpWidget(harness());

      // Bem abaixo do limiar de 25% da largura — não deve acionar.
      await tester.drag(find.text('Tarefa'), const Offset(20, 0));
      await tester.pumpAndSettle();

      expect(completeCalled, isFalse);
      expect(editCalled, isFalse);
    });
  });

  group('feedback tátil (HapticFeedback)', () {
    late List<MethodCall> hapticCalls;

    setUp(() {
      hapticCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') hapticCalls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('swipe dispara háptico leve', (tester) async {
      await tester.pumpWidget(harness());

      await tester.drag(find.text('Tarefa'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first.arguments, 'HapticFeedbackType.lightImpact');
    });

    testWidgets('clique longo dispara háptico médio', (tester) async {
      await tester.pumpWidget(harness());

      await tester.longPress(find.text('Tarefa'));
      await tester.pumpAndSettle();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first.arguments, 'HapticFeedbackType.mediumImpact');
    });
  });
}
