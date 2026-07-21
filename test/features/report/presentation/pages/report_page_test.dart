import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/report/domain/entities/list_report_row.dart';
import 'package:meu_tempo/features/report/domain/entities/period_range.dart';
import 'package:meu_tempo/features/report/domain/entities/report_period_enum.dart';
import 'package:meu_tempo/features/report/presentation/bloc/report_bloc.dart';
import 'package:meu_tempo/features/report/presentation/pages/report_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportBloc extends MockBloc<ReportEvent, ReportState>
    implements ReportBloc {}

void main() {
  late _MockReportBloc bloc;
  final now = DateTime(2026, 7, 20);

  setUpAll(() async => initializeDateFormatting('pt_BR', null));

  setUp(() {
    bloc = _MockReportBloc();
  });

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  ReportLoaded loaded({int offset = 0, bool canGoForward = false}) =>
      ReportLoaded(
        const [
          ListReportRow(
            listId: 'prof',
            listName: 'Profissional',
            estimatedMinutes: 600,
            spentMinutes: 750,
          ),
        ],
        period: ReportPeriodEnum.week,
        range: PeriodRange.at(ReportPeriodEnum.week, now, offset),
        offset: offset,
        canGoForward: canGoForward,
      );

  Widget harness() => MaterialApp(
        theme: AppTheme.dark,
        home: BlocProvider<ReportBloc>.value(
          value: bloc,
          child: const ReportPage(),
        ),
      );

  testWidgets('renderiza o rótulo do período e a linha da lista',
      (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded());

    await tester.pumpWidget(harness());

    expect(find.text('Profissional'), findsOneWidget);
    // now=2026-07-20 (segunda) → semana atual 20/07–26/07.
    expect(find.text('20/07 – 26/07'), findsOneWidget);
  });

  testWidgets('seta ‹ dispara ReportPeriodStepped(-1)', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded());

    await tester.pumpWidget(harness());
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pump();

    verify(() => bloc.add(const ReportPeriodStepped(-1))).called(1);
  });

  testWidgets('seta › fica desabilitada no período atual', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded());

    await tester.pumpWidget(harness());

    final forward = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(forward.onPressed, isNull);
  });

  testWidgets('seta › habilitada quando há período à frente', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded(offset: -1, canGoForward: true));

    await tester.pumpWidget(harness());

    final forward = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(forward.onPressed, isNotNull);
  });

  testWidgets('tocar numa lista navega para o detalhe com os parâmetros',
      (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded());

    final router = GoRouter(
      initialLocation: '/report',
      routes: [
        GoRoute(
          path: '/report',
          builder: (_, _) => BlocProvider<ReportBloc>.value(
            value: bloc,
            child: const ReportPage(),
          ),
        ),
        GoRoute(
          path: '/report/detail',
          builder: (_, state) => Scaffold(
            body: Text('DETALHE ${state.uri.query}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
    await tester.tap(find.text('Profissional'));
    await tester.pumpAndSettle();

    expect(find.textContaining('DETALHE'), findsOneWidget);
    expect(find.textContaining('list=prof'), findsOneWidget);
    expect(find.textContaining('period=week'), findsOneWidget);
  });
}
