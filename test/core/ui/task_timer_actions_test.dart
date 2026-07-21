import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/task_timer_actions.dart';

void main() {
  late bool timerTapped;
  late bool addTimeTapped;

  setUp(() {
    timerTapped = false;
    addTimeTapped = false;
  });

  Widget harness({required bool isActive}) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TaskTimerActions(
            isActive: isActive,
            onToggleTimer: () => timerTapped = true,
            onAddTime: () => addTimeTapped = true,
          ),
        ),
      );

  testWidgets('shows "Iniciar" when inactive', (tester) async {
    await tester.pumpWidget(harness(isActive: false));

    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Parar'), findsNothing);
  });

  testWidgets('shows "Parar" when active', (tester) async {
    await tester.pumpWidget(harness(isActive: true));

    expect(find.text('Parar'), findsOneWidget);
    expect(find.text('Iniciar'), findsNothing);
  });

  testWidgets('renders the quick-minutes shortcut label', (tester) async {
    await tester.pumpWidget(harness(isActive: false));

    expect(find.text('+${TaskTimerActions.quickMinutes} min'), findsOneWidget);
  });

  testWidgets('tapping the timer button triggers onToggleTimer',
      (tester) async {
    await tester.pumpWidget(harness(isActive: false));

    await tester.tap(find.text('Iniciar'));

    expect(timerTapped, isTrue);
  });

  testWidgets('tapping the shortcut triggers onAddTime', (tester) async {
    await tester.pumpWidget(harness(isActive: false));

    await tester.tap(find.text('+${TaskTimerActions.quickMinutes} min'));

    expect(addTimeTapped, isTrue);
  });
}
