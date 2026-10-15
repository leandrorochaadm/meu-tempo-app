import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:meu_tempo/features/task/presentation/widgets/weekday_selector_widget.dart';

void main() {
  late Set<WeekdayEnum> current;

  Future<void> pump(
    WidgetTester tester, {
    Set<WeekdayEnum> initial = const {},
  }) async {
    current = initial;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => WeekdaySelectorWidget(
              selected: current,
              onChanged: (d) => setState(() => current = d),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('should render 7 day toggles in Monday-first order', (
    tester,
  ) async {
    await pump(tester);

    final letters = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(InkWell),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .take(WeekdayEnum.values.length)
        .toList();
    expect(letters, ['S', 'T', 'Q', 'Q', 'S', 'S', 'D']);
    expect(
      tester.getTopLeft(find.bySemanticsLabel('Seg')).dx,
      lessThan(tester.getTopLeft(find.bySemanticsLabel('Dom')).dx),
    );
  });

  testWidgets(
    'tapping a day should add it and tapping again should remove it',
    (tester) async {
      await pump(tester);

      await tester.tap(find.bySemanticsLabel('Qua'));
      await tester.pumpAndSettle();
      expect(current, {WeekdayEnum.wednesday});
      expect(
        tester.getSemantics(find.bySemanticsLabel('Qua')),
        isSemantics(isSelected: true),
      );

      await tester.tap(find.bySemanticsLabel('Qua'));
      await tester.pumpAndSettle();
      expect(current, <WeekdayEnum>{});
    },
  );

  testWidgets('Todo dia should select all days when not all selected', (
    tester,
  ) async {
    await pump(tester, initial: {WeekdayEnum.monday});

    await tester.tap(find.text('Todo dia'));
    await tester.pumpAndSettle();

    expect(current, WeekdayEnum.values.toSet());
  });

  testWidgets('Todo dia should clear all days when all selected', (
    tester,
  ) async {
    await pump(tester, initial: WeekdayEnum.values.toSet());

    await tester.tap(find.text('Todo dia'));
    await tester.pumpAndSettle();

    expect(current, <WeekdayEnum>{});
  });

  testWidgets('should show "Sem dia fixo" hint when nothing selected', (
    tester,
  ) async {
    await pump(tester);
    expect(find.textContaining('Sem dia fixo'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Seg'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sem dia fixo'), findsNothing);
    expect(find.textContaining('nos dias marcados'), findsOneWidget);
  });

  testWidgets('should not mutate the selected set', (tester) async {
    await pump(tester, initial: Set.unmodifiable({WeekdayEnum.monday}));

    await tester.tap(find.bySemanticsLabel('Ter'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(current, {WeekdayEnum.monday, WeekdayEnum.tuesday});
  });
}
