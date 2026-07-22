import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/presentation/bloc/time_entry_bloc.dart';
import 'package:meu_tempo/features/task/presentation/pages/time_entry_page.dart';
import 'package:meu_tempo/features/task/presentation/widgets/time_entry_tile.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockBloc extends MockBloc<TimeEntryEvent, TimeEntryState>
    implements TimeEntryBloc {}

void main() {
  late _MockBloc bloc;

  final leaf = TaskEntity(
    id: 't1',
    title: 'Estudar',
    listId: 'l1',
    createdAt: DateTime(2026, 7, 21),
    estimatedMinutes: 30,
    spentMinutes: 30,
  );

  final entry = TimeEntryEntity(
    id: 'e1',
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    listId: 'l1',
    minutes: 30,
    origin: TimeEntryOriginEnum.manual,
    occurredAt: DateTime(2026, 7, 21),
  );

  setUpAll(() async {
    registerFallbackValue(const TimeEntryUndoRequested());
    await initializeDateFormatting('pt_BR');
  });

  setUp(() => bloc = _MockBloc());

  Widget harness() => MaterialApp(
        theme: AppTheme.dark,
        home: BlocProvider<TimeEntryBloc>.value(
          value: bloc,
          child: TimeEntryPage(leaf: leaf),
        ),
      );

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('dispara TimeEntryStarted no initState', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(const TimeEntryLoading());

    await tester.pumpWidget(harness());

    verify(() => bloc.add(
          const TimeEntryStarted(targetId: 't1', listId: 'l1'),
        )).called(1);
  });

  testWidgets('mostra empty state sem registros', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(const TimeEntryEmpty());

    await tester.pumpWidget(harness());

    expect(find.text('Nenhum registro ainda'), findsOneWidget);
  });

  testWidgets('renderiza um tile por registro', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(TimeEntryLoaded([entry]));

    await tester.pumpWidget(harness());

    expect(find.byType(TimeEntryTile), findsOneWidget);
  });

  testWidgets('excluir dispara TimeEntryDeleted e mostra desfazer',
      (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(TimeEntryLoaded([entry]));

    await tester.pumpWidget(harness());
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();

    verify(() => bloc.add(TimeEntryDeleted(entry))).called(1);
    expect(find.text('Desfazer'), findsOneWidget);
    // persist deve ser false para o snackbar sumir sozinho (ver Flutter 3.41+).
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.persist, isFalse);
  });

  testWidgets('desfazer dispara TimeEntryUndoRequested', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(TimeEntryLoaded([entry]));

    await tester.pumpWidget(harness());
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    // Deixa o snackbar concluir a animação de entrada antes de tocar em Desfazer.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Desfazer'));
    await tester.pump();

    verify(() => bloc.add(const TimeEntryUndoRequested())).called(1);
  });

  testWidgets('FAB abre o editor de duração', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(const TimeEntryEmpty());

    await tester.pumpWidget(harness());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Duração'), findsOneWidget);
  });

  testWidgets('salvar no editor dispara TimeEntryAdded', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(const TimeEntryEmpty());

    await tester.pumpWidget(harness());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => bloc.add(captureAny())).captured.whereType<TimeEntryAdded>();
    expect(captured, isNotEmpty);
    expect(captured.first.minutes, 30);
  });
}
