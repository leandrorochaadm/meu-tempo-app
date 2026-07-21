import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/task_crud_menu.dart';
import 'package:meu_tempo/core/ui/task_running_badge.dart';
import 'package:meu_tempo/features/task/domain/entities/prioritized_leaf.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/presentation/widgets/prioritized_leaf_tile.dart';

void main() {
  final today = DateTime(2026, 7, 21);

  TaskEntity leafTask({bool isDone = false, int spentMinutes = 90}) => TaskEntity(
        id: 't1',
        title: 'Estudar Flutter',
        listId: 'l1',
        createdAt: today,
        estimatedMinutes: 120,
        dueDate: today,
        spentMinutes: spentMinutes,
        isDone: isDone,
      );

  PrioritizedLeaf leaf({bool isDone = false, int spentMinutes = 90}) =>
      PrioritizedLeaf(
        task: leafTask(isDone: isDone, spentMinutes: spentMinutes),
        priority: 42,
        ancestryLabel: '',
      );

  // Callbacks-espião: registram que foram chamados.
  late bool timerTapped;
  late bool addTimeTapped;
  late bool doneTapped;
  late bool editTapped;
  late bool moveTapped;
  late bool deleteTapped;

  setUp(() {
    timerTapped = false;
    addTimeTapped = false;
    doneTapped = false;
    editTapped = false;
    moveTapped = false;
    deleteTapped = false;
  });

  Widget harness({required PrioritizedLeaf leaf, required bool isActive}) =>
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: PrioritizedLeafTile(
            leaf: leaf,
            isActive: isActive,
            today: today,
            onToggleTimer: () => timerTapped = true,
            onAddTime: () => addTimeTapped = true,
            onToggleDone: () => doneTapped = true,
            onEdit: () => editTapped = true,
            onMove: () => moveTapped = true,
            onDelete: () => deleteTapped = true,
          ),
        ),
      );

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows spent time in the subtitle', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    expect(find.textContaining('gasto'), findsOneWidget);
  });

  testWidgets('shows running badge when active', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: true));

    expect(find.byType(TaskRunningBadge), findsOneWidget);
  });

  testWidgets('hides running badge when inactive', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    expect(find.byType(TaskRunningBadge), findsNothing);
  });

  testWidgets('exposes the CRUD menu', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    expect(find.byType(TaskCrudMenu), findsOneWidget);
  });

  testWidgets('tapping the timer button triggers onToggleTimer',
      (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    await tester.tap(find.text('Iniciar'));
    await tester.pump();

    expect(timerTapped, isTrue);
  });

  testWidgets('tapping +30 min triggers onAddTime', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    await tester.tap(find.text('+30 min'));
    await tester.pump();

    expect(addTimeTapped, isTrue);
  });

  testWidgets('tapping the complete circle triggers onToggleDone',
      (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    await tester.tap(find.byIcon(Icons.circle_outlined));
    await tester.pump();

    expect(doneTapped, isTrue);
  });

  testWidgets('selecting Editar triggers onEdit', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(editTapped, isTrue);
  });

  testWidgets('selecting Mover triggers onMove', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mover'));
    await tester.pumpAndSettle();

    expect(moveTapped, isTrue);
  });

  testWidgets('selecting Excluir triggers onDelete', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(deleteTapped, isTrue);
  });

  testWidgets('shows the check icon when the leaf is done', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(isDone: true), isActive: false));

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}
