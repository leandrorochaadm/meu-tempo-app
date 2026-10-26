import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/ui/app_not_configured_screen.dart';

void main() {
  testWidgets('shows the not configured notice', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AppNotConfiguredApp());

    expect(find.text('O app não foi configurado.'), findsOneWidget);
    expect(find.text('Fale com o suporte.'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });
}
