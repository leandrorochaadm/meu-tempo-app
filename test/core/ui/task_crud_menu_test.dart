import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/task_crud_menu.dart';

void main() {
  late bool editTapped;
  late bool moveTapped;
  late bool deleteTapped;

  setUp(() {
    editTapped = false;
    moveTapped = false;
    deleteTapped = false;
  });

  Widget harness() => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TaskCrudMenu(
            onEdit: () => editTapped = true,
            onMove: () => moveTapped = true,
            onDelete: () => deleteTapped = true,
          ),
        ),
      );

  Future<void> openAndSelect(WidgetTester tester, String item) async {
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the three CRUD options when opened', (tester) async {
    await tester.pumpWidget(harness());

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Mover'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
  });

  testWidgets('selecting Editar triggers onEdit', (tester) async {
    await tester.pumpWidget(harness());
    await openAndSelect(tester, 'Editar');

    expect(editTapped, isTrue);
  });

  testWidgets('selecting Mover triggers onMove', (tester) async {
    await tester.pumpWidget(harness());
    await openAndSelect(tester, 'Mover');

    expect(moveTapped, isTrue);
  });

  testWidgets('selecting Excluir triggers onDelete', (tester) async {
    await tester.pumpWidget(harness());
    await openAndSelect(tester, 'Excluir');

    expect(deleteTapped, isTrue);
  });
}
