import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/app_notice_banner.dart';

void main() {
  var actions = 0;
  var dismissals = 0;

  setUp(() {
    actions = 0;
    dismissals = 0;
  });

  Widget harness({String message = 'Mensagem A'}) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => AppNoticeBanner.show(
                    context,
                    icon: Icons.info_rounded,
                    message: message,
                    actionLabel: 'Agir',
                    onAction: () => actions++,
                    onDismiss: () => dismissals++,
                  ),
                  child: const Text('abrir'),
                ),
                TextButton(
                  onPressed: () => AppNoticeBanner.hide(context),
                  child: const Text('fechar'),
                ),
              ],
            ),
          ),
        ),
      );

  testWidgets('shows message, action and "Agora não"', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Mensagem A'), findsOneWidget);
    expect(find.text('Agir'), findsOneWidget);
    expect(find.text('Agora não'), findsOneWidget);
  });

  testWidgets('action and dismiss call the callbacks', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agir'));
    await tester.tap(find.text('Agora não'));

    expect(actions, 1);
    expect(dismissals, 1);
  });

  testWidgets('showing again replaces the banner', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(harness(message: 'Mensagem B'));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Mensagem A'), findsNothing);
    expect(find.text('Mensagem B'), findsOneWidget);
  });

  testWidgets('hide removes the banner', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('fechar'));
    await tester.pumpAndSettle();

    expect(find.text('Mensagem A'), findsNothing);
  });
}
