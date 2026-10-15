import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/recurring_task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/weekday_enum.dart';
import 'package:meu_tempo/features/task/presentation/pages/edit_recurring_task_page.dart';

void main() {
  const lists = [
    TaskListEntity(id: 'inbox', name: 'Entrada', isDefault: true),
    TaskListEntity(id: 'work', name: 'Trabalho'),
  ];

  final academia = RecurringTaskEntity(
    id: 'r1',
    title: 'Academia',
    listId: 'work',
    estimatedMinutes: 60,
    importance: ImportanceEnum.high,
    weekdays: {WeekdayEnum.monday, WeekdayEnum.wednesday, WeekdayEnum.friday},
    createdAt: DateTime(2026, 10, 1),
  );

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Abre a página e devolve um getter do resultado (lido após tocar "Salvar").
  Future<RecurringTaskFormResult? Function()> pushPage(
    WidgetTester tester, {
    RecurringTaskEntity? template,
    List<TaskListEntity> pageLists = lists,
  }) async {
    setView(tester);
    RecurringTaskFormResult? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async => result = await Navigator.of(ctx)
                  .push<RecurringTaskFormResult>(
                    MaterialPageRoute(
                      builder: (_) => EditRecurringTaskPage(
                        template: template,
                        lists: pageLists,
                      ),
                    ),
                  ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return () => result;
  }

  bool isChipSelected(WidgetTester tester, String label) => tester
      .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
      .selected;

  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
  }

  testWidgets('create should open empty with default list', (tester) async {
    await pushPage(tester);

    expect(find.text('Nova tarefa recorrente'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(isChipSelected(tester, 'Entrada'), isTrue);
    expect(isChipSelected(tester, 'Trabalho'), isFalse);
    expect(isChipSelected(tester, '30min'), isTrue);
    expect(isChipSelected(tester, 'Mínima'), isTrue);
    expect(find.textContaining('Sem dia fixo'), findsOneWidget);
  });

  testWidgets('edit should open prefilled', (tester) async {
    await pushPage(tester, template: academia);

    expect(find.text('Editar tarefa recorrente'), findsOneWidget);
    expect(find.text('Academia'), findsOneWidget);
    expect(isChipSelected(tester, 'Trabalho'), isTrue);
    expect(isChipSelected(tester, '1h'), isTrue);
    expect(isChipSelected(tester, 'Alta'), isTrue);
    for (final day in ['Seg', 'Qua', 'Sex']) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(day)),
        isSemantics(isSelected: true),
      );
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('Ter')),
      isNot(isSemantics(isSelected: true)),
    );
  });

  testWidgets('day toggles should be at least 48 dp wide', (tester) async {
    await pushPage(tester);

    final size = tester.getSize(find.bySemanticsLabel('Seg'));
    expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension));
    expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
  });

  testWidgets('save should return the typed result', (tester) async {
    final get = await pushPage(tester);

    await tester.enterText(find.byType(TextField), '  Ler e-mails ');
    await tester.tap(find.text('Trabalho'));
    await tester.tap(find.text('15min'));
    await tester.tap(find.text('Baixa'));
    await tester.tap(find.text('Todo dia'));
    await tester.pumpAndSettle();
    await tapSave(tester);

    final result = get()!;
    expect(result.title, 'Ler e-mails');
    expect(result.listId, 'work');
    expect(result.estimatedMinutes, 15);
    expect(result.importance, ImportanceEnum.low);
    expect(result.weekdays, WeekdayEnum.values.toSet());
  });

  testWidgets('save without weekdays should return empty set', (tester) async {
    final get = await pushPage(tester);

    await tester.enterText(find.byType(TextField), 'Revisar finanças');
    await tapSave(tester);

    expect(get()!.weekdays, <WeekdayEnum>{});
  });

  testWidgets('save should not pop when title is blank', (tester) async {
    final get = await pushPage(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tapSave(tester);

    expect(get(), isNull);
    expect(find.text('Nova tarefa recorrente'), findsOneWidget);
  });

  testWidgets('should keep a non-shortcut duration selected', (tester) async {
    final odd = RecurringTaskEntity(
      id: 'r2',
      title: 'Leitura',
      listId: 'inbox',
      estimatedMinutes: 45,
      importance: ImportanceEnum.min,
      weekdays: const {},
      createdAt: DateTime(2026, 10, 1),
    );
    await pushPage(tester, template: odd);

    expect(isChipSelected(tester, '45min'), isTrue);
  });

  testWidgets('save should be disabled without lists', (tester) async {
    await pushPage(tester, pageLists: const []);

    expect(find.text('Lista'), findsNothing);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
