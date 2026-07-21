import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/report/domain/entities/period_range.dart';
import 'package:meu_tempo/features/report/domain/entities/report_period_enum.dart';
import 'package:meu_tempo/features/report/domain/entities/report_tree_node.dart';
import 'package:meu_tempo/features/report/domain/entities/task_report_sort_enum.dart';
import 'package:meu_tempo/features/report/presentation/bloc/report_detail_bloc.dart';
import 'package:meu_tempo/features/report/presentation/pages/report_detail_page.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportDetailBloc
    extends MockBloc<ReportDetailEvent, ReportDetailState>
    implements ReportDetailBloc {}

void main() {
  late _MockReportDetailBloc bloc;
  final now = DateTime(2026, 7, 20);

  setUpAll(() async => initializeDateFormatting('pt_BR', null));

  setUp(() {
    bloc = _MockReportDetailBloc();
  });

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  ReportDetailLoaded loaded(List<ReportTreeNode> nodes) => ReportDetailLoaded(
        report: TaskReport(
          nodes: nodes,
          totalSpentMinutes: 0,
          totalEstimatedMinutes: 0,
        ),
        listName: 'Profissional',
        range: PeriodRange.at(ReportPeriodEnum.week, now, 0),
        period: ReportPeriodEnum.week,
        sort: TaskReportSortEnum.spent,
      );

  void stub(ReportDetailState state) {
    whenListen(bloc, const Stream<ReportDetailState>.empty(),
        initialState: state);
  }

  Widget harness() => MaterialApp(
        theme: AppTheme.dark,
        home: BlocProvider<ReportDetailBloc>.value(
          value: bloc,
          child: const ReportDetailPage(
            listId: 'prof',
            period: ReportPeriodEnum.week,
            offset: 0,
            listName: 'Profissional',
          ),
        ),
      );

  ReportTreeNode leafNode(String id, String title,
          {int spent = 60, int est = 60}) =>
      ReportTreeNode(
        id: id,
        title: title,
        targetType: TimerTargetTypeEnum.task,
        level: 0,
        spentMinutes: spent,
        estimatedMinutes: est,
      );

  final motherNode = ReportTreeNode(
    id: 'mae',
    title: 'Projeto Alfa',
    targetType: TimerTargetTypeEnum.task,
    level: 0,
    spentMinutes: 120,
    estimatedMinutes: 60,
    children: [
      ReportTreeNode(
        id: 'f1',
        title: 'Montar proposta',
        targetType: TimerTargetTypeEnum.task,
        level: 1,
        spentMinutes: 120,
        estimatedMinutes: 60,
      ),
    ],
  );

  final apptNode = ReportTreeNode(
    id: 'ap1',
    title: 'Reunião semanal',
    targetType: TimerTargetTypeEnum.appointment,
    level: 0,
    spentMinutes: 60,
  );

  testWidgets('renderiza os nós de topo e os chips (sem Mãe/Avó)',
      (tester) async {
    setView(tester);
    stub(loaded([motherNode]));

    await tester.pumpWidget(harness());

    expect(find.text('Projeto Alfa'), findsOneWidget);
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('Estouro'), findsOneWidget);
    expect(find.text('Mãe/Avó'), findsNothing);
    // Filha só aparece após expandir.
    expect(find.text('Montar proposta'), findsNothing);
  });

  testWidgets('tocar na raiz expande as filhas inline', (tester) async {
    setView(tester);
    stub(loaded([motherNode]));

    await tester.pumpWidget(harness());
    await tester.tap(find.text('Projeto Alfa'));
    await tester.pump();

    expect(find.text('Montar proposta'), findsOneWidget);
  });

  final avoComNeta = ReportTreeNode(
    id: 'avo',
    title: 'Avó Alfa',
    targetType: TimerTargetTypeEnum.task,
    level: 0,
    spentMinutes: 40,
    estimatedMinutes: 30,
    children: [
      ReportTreeNode(
        id: 'mae',
        title: 'Mãe Beta',
        targetType: TimerTargetTypeEnum.task,
        level: 1,
        spentMinutes: 40,
        estimatedMinutes: 30,
        children: [
          ReportTreeNode(
            id: 'neta',
            title: 'Neta Gama',
            targetType: TimerTargetTypeEnum.task,
            level: 2,
            spentMinutes: 40,
            estimatedMinutes: 30,
          ),
        ],
      ),
    ],
  );

  testWidgets('expandir a avó revela mãe e neta; recolher esconde',
      (tester) async {
    setView(tester);
    stub(loaded([avoComNeta]));

    await tester.pumpWidget(harness());
    expect(find.text('Mãe Beta'), findsNothing);
    expect(find.text('Neta Gama'), findsNothing);

    await tester.tap(find.text('Avó Alfa'));
    await tester.pump();
    expect(find.text('Mãe Beta'), findsOneWidget);
    expect(find.text('Neta Gama'), findsOneWidget);

    await tester.tap(find.text('Avó Alfa'));
    await tester.pump();
    expect(find.text('Mãe Beta'), findsNothing);
    expect(find.text('Neta Gama'), findsNothing);
  });

  testWidgets('folha de topo não é expansível (sem seta, tocar não faz nada)',
      (tester) async {
    setView(tester);
    stub(loaded([leafNode('a', 'Tarefa Solo')]));

    await tester.pumpWidget(harness());
    await tester.tap(find.text('Tarefa Solo'));
    await tester.pump();

    // Continua sendo o único texto de tarefa; nada expandiu.
    expect(find.text('Tarefa Solo'), findsOneWidget);
  });

  testWidgets('compromisso aparece com "(compr.)" no título', (tester) async {
    setView(tester);
    stub(loaded([apptNode]));

    await tester.pumpWidget(harness());

    expect(find.text('Reunião semanal (compr.)'), findsOneWidget);
  });

  testWidgets('tocar num chip dispara ReportDetailSortChanged', (tester) async {
    setView(tester);
    stub(loaded([leafNode('a', 'Tarefa A')]));

    await tester.pumpWidget(harness());
    await tester.tap(find.text('Estouro'));
    await tester.pump();

    verify(() => bloc.add(
          const ReportDetailSortChanged(TaskReportSortEnum.overrun),
        )).called(1);
  });

  testWidgets('sem nós mostra o empty state', (tester) async {
    setView(tester);
    stub(loaded(const []));

    await tester.pumpWidget(harness());

    expect(find.text('Sem tempo no período'), findsOneWidget);
  });
}
