import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/appointment/domain/entities/appointment_entity.dart';
import 'package:meu_tempo/features/appointment/domain/entities/day_fit.dart';
import 'package:meu_tempo/features/appointment/presentation/bloc/agenda_bloc.dart';
import 'package:meu_tempo/features/appointment/presentation/pages/agenda_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAgendaBloc extends MockBloc<AgendaEvent, AgendaState>
    implements AgendaBloc {}

void main() {
  late _MockAgendaBloc bloc;

  setUpAll(() => registerFallbackValue(const AgendaStarted()));

  setUp(() => bloc = _MockAgendaBloc());

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  AgendaLoaded loaded({bool done = false}) => AgendaLoaded(
        appointments: [
          AppointmentEntity(
            id: 'a1',
            title: 'Dentista',
            listId: 'pessoal',
            date: DateTime(2026, 10, 7),
            startMinute: 900,
            durationMinutes: 60,
            isDone: done,
          ),
        ],
        fit: const DayFit(plannedMinutes: 60, availableMinutes: 480),
      );

  Widget harness() => MaterialApp(
        theme: AppTheme.dark,
        home: BlocProvider<AgendaBloc>.value(
          value: bloc,
          child: const AgendaPage(),
        ),
      );

  const doneEvent = AppointmentDoneToggled(appointmentId: 'a1', done: true);
  const reopenEvent = AppointmentDoneToggled(appointmentId: 'a1', done: false);

  testWidgets('compromisso aberto não mostra o sinal de feito e oferece Concluir',
      (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded());
    await tester.pumpWidget(harness());

    expect(find.byIcon(Icons.task_alt_rounded), findsNothing);
    expect(find.byTooltip('Concluir'), findsOneWidget);
    expect(find.text('Dentista'), findsOneWidget);
  });

  testWidgets('compromisso concluído mostra o sinal de feito e continua igual',
      (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded(done: true));
    await tester.pumpWidget(harness());

    expect(find.byIcon(Icons.task_alt_rounded), findsOneWidget);
    expect(find.text('Dentista'), findsOneWidget);
    expect(find.byTooltip('Iniciar cronômetro'), findsOneWidget);
    expect(find.byTooltip('Excluir'), findsOneWidget);
    expect(find.byTooltip('Reabrir'), findsOneWidget);
  });

  testWidgets('tocar em Concluir conclui e oferece Desfazer', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded());
    await tester.pumpWidget(harness());

    await tester.tap(find.byTooltip('Concluir'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // animação de entrada

    verify(() => bloc.add(doneEvent)).called(1);
    expect(find.text('"Dentista" concluído'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pump();

    verify(() => bloc.add(reopenEvent)).called(1);
  });

  testWidgets('tocar em Reabrir reabre sem snackbar', (tester) async {
    setView(tester);
    when(() => bloc.state).thenReturn(loaded(done: true));
    await tester.pumpWidget(harness());

    await tester.tap(find.byTooltip('Reabrir'));
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => bloc.add(reopenEvent)).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });
}
