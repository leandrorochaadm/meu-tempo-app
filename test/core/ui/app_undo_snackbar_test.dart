import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/app_defaults.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/app_undo_snackbar.dart';

void main() {
  // Harness com um botão que, ao ser tocado, chama AppUndoSnackBar.show com um
  // BuildContext válido sob o ScaffoldMessenger (como no app real).
  Widget harness({
    required String message,
    required VoidCallback onUndo,
    String actionLabel = 'Desfazer',
  }) =>
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => AppUndoSnackBar.show(
                  context,
                  message: message,
                  onUndo: onUndo,
                  actionLabel: actionLabel,
                ),
                child: const Text('mostrar'),
              ),
            ),
          ),
        ),
      );

  Future<void> trigger(WidgetTester tester) async {
    await tester.tap(find.text('mostrar'));
    await tester.pump();
  }

  testWidgets('exibe a mensagem e o botão de ação', (tester) async {
    await tester.pumpWidget(
      harness(message: 'Tarefa concluída', onUndo: () {}),
    );
    await trigger(tester);

    expect(find.text('Tarefa concluída'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);
  });

  testWidgets('usa a duração padrão de undo e persist: false', (tester) async {
    await tester.pumpWidget(harness(message: 'X', onUndo: () {}));
    await trigger(tester);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.duration, AppDefaults.undoSnackbarDuration);
    // persist: false é o cerne da correção — no Flutter 3.41+ o default vira
    // true quando há action, ignorando o duration e fixando o snackbar.
    expect(snackBar.persist, isFalse);
  });

  testWidgets('tocar na ação dispara onUndo', (tester) async {
    var undone = false;
    await tester.pumpWidget(
      harness(message: 'X', onUndo: () => undone = true),
    );
    await trigger(tester);
    // Deixa a animação de entrada do snackbar concluir antes de tocar na ação.
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Desfazer'));
    await tester.pump();

    expect(undone, isTrue);
  });

  testWidgets('respeita um actionLabel customizado', (tester) async {
    await tester.pumpWidget(
      harness(message: 'X', onUndo: () {}, actionLabel: 'Reverter'),
    );
    await trigger(tester);

    expect(find.text('Reverter'), findsOneWidget);
  });

  testWidgets('substitui o snackbar anterior (hideCurrent + show)',
      (tester) async {
    await tester.pumpWidget(harness(message: 'Primeira', onUndo: () {}));

    await trigger(tester);
    expect(find.text('Primeira'), findsOneWidget);

    // Segundo disparo: hideCurrentSnackBar remove o anterior antes de exibir.
    await trigger(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
