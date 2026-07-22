import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/ui/app_error_screen.dart';

void main() {
  // A tela é standalone (não depende de tema) porque é o fallback exibido
  // quando o próprio build/tema falha. O reload chama window.location.reload()
  // e só roda no navegador real — aqui cobrimos apenas a renderização.
  testWidgets('renderiza mensagem de erro e botão recarregar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AppErrorScreen());

    expect(find.text('Algo deu errado'), findsOneWidget);
    expect(find.text('Recarregar'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
