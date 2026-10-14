import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/priority_breakdown.dart';
import 'package:meu_tempo/core/theme/app_colors.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/core/ui/task_crud_menu.dart';
import 'package:meu_tempo/core/ui/task_running_badge.dart';
import 'package:meu_tempo/features/task/domain/entities/prioritized_leaf.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/presentation/widgets/prioritized_leaf_tile.dart';

void main() {
  final today = DateTime(2026, 7, 21);

  TaskEntity leafTask({
    bool isDone = false,
    int spentMinutes = 90,
    String title = 'Estudar Flutter',
  }) => TaskEntity(
    id: 't1',
    title: title,
    listId: 'l1',
    createdAt: today,
    estimatedMinutes: 120,
    dueDate: today,
    spentMinutes: spentMinutes,
    isDone: isDone,
  );

  PrioritizedLeaf leaf({
    bool isDone = false,
    int spentMinutes = 90,
    bool isOverdue = false,
    String title = 'Estudar Flutter',
    String ancestryLabel = '',
  }) => PrioritizedLeaf(
    task: leafTask(isDone: isDone, spentMinutes: spentMinutes, title: title),
    breakdown: const PriorityBreakdown(
      estimatedMinutes: 42,
      importance: ImportanceEnum.min,
      urgencyWeight: 1,
      daysUntilDue: null,
    ),
    ancestryLabel: ancestryLabel,
    rank: 1,
    isOverdue: isOverdue,
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

  Widget harness({
    required PrioritizedLeaf leaf,
    required bool isActive,
    DateTime? activeStartedAt,
  }) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: PrioritizedLeafTile(
        leaf: leaf,
        isActive: isActive,
        activeStartedAt: activeStartedAt,
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

  testWidgets('mostra a posição (#rank) em vez da pontuação bruta', (
    tester,
  ) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    expect(find.textContaining('#1'), findsOneWidget);
    expect(find.textContaining('prio'), findsNothing);
  });

  testWidgets('shows running badge when active', (tester) async {
    setView(tester);
    await tester.pumpWidget(
      harness(leaf: leaf(), isActive: true, activeStartedAt: DateTime.now()),
    );

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

  testWidgets('tapping the timer button triggers onToggleTimer', (
    tester,
  ) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    await tester.tap(find.byTooltip('Iniciar cronômetro'));
    await tester.pump();

    expect(timerTapped, isTrue);
  });

  testWidgets('"Somar 30 min" no menu ⋮ chama onAddTime', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Somar 30 min'));
    await tester.pumpAndSettle();

    expect(addTimeTapped, isTrue);
  });

  testWidgets('tapping the complete circle triggers onToggleDone', (
    tester,
  ) async {
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

  BoxDecoration cardDecoration(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(PrioritizedLeafTile),
            matching: find.byType(Container),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('tints the whole card when the timer is running', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: true));

    expect(cardDecoration(tester).color, AppColors.dark.timerActiveSurface);
  });

  testWidgets('uses the plain surface color when inactive', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    expect(cardDecoration(tester).color, AppColors.dark.surface);
  });

  testWidgets('shows the check icon when the leaf is done', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(isDone: true), isActive: false));

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  Color leftBorderColor(WidgetTester tester) =>
      (cardDecoration(tester).border! as Border).left.color;

  testWidgets('overdue leaf paints the left border in warning', (tester) async {
    setView(tester);
    await tester.pumpWidget(
      harness(leaf: leaf(isOverdue: true), isActive: false),
    );

    expect(leftBorderColor(tester), AppColors.dark.warning);
  });

  testWidgets('non-overdue leaf paints the left border in primary', (
    tester,
  ) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    expect(leftBorderColor(tester), AppColors.dark.primary);
  });

  testWidgets('active leaf keeps the timer-active border even if overdue', (
    tester,
  ) async {
    setView(tester);
    await tester.pumpWidget(
      harness(leaf: leaf(isOverdue: true), isActive: true),
    );

    expect(leftBorderColor(tester), AppColors.dark.timerActive);
  });

  testWidgets('card com título de 1 linha tem no máximo 88 px de altura', (
    tester,
  ) async {
    setView(tester);
    await tester.pumpWidget(
      harness(
        leaf: leaf(title: 'Relatório', ancestryLabel: 'Projeto › Cliente'),
        isActive: true,
        activeStartedAt: DateTime.now(),
      ),
    );

    expect(
      tester.getSize(find.byType(PrioritizedLeafTile)).height,
      lessThanOrEqualTo(88),
    );
  });

  testWidgets('não mostra o tempo estimado', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    expect(find.textContaining('est.'), findsNothing);
  });

  testWidgets(
    'título longo aparece inteiro, em mais de 1 linha, sem overflow',
    (tester) async {
      setView(tester);
      const longTitle =
          'Preparar a apresentação trimestral completa com todos os números';
      await tester.pumpWidget(
        harness(leaf: leaf(title: longTitle), isActive: false),
      );

      final text = tester.widget<Text>(find.text(longTitle));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
      expect(
        tester.getSize(find.text(longTitle)).height,
        greaterThanOrEqualTo(
          2 * AppTheme.dark.textTheme.titleMedium!.fontSize!,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mostra Concluir/Reabrir como dica do botão de concluir', (
    tester,
  ) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));
    expect(find.byTooltip('Concluir'), findsOneWidget);

    await tester.pumpWidget(harness(leaf: leaf(isDone: true), isActive: false));
    expect(find.byTooltip('Reabrir'), findsOneWidget);
  });

  testWidgets('tocar na linha de tempo abre a explicação da prioridade', (
    tester,
  ) async {
    setView(tester);
    await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

    await tester.tap(find.textContaining('gasto'));
    await tester.pumpAndSettle();

    expect(find.text('Como calculamos'), findsOneWidget);
  });

  testWidgets(
    'clique longo na linha de tempo exclui (gesto do card não é capturado)',
    (tester) async {
      setView(tester);
      await tester.pumpWidget(harness(leaf: leaf(), isActive: false));

      await tester.longPress(find.textContaining('gasto'));
      await tester.pump();

      expect(deleteTapped, isTrue);
    },
  );
}
