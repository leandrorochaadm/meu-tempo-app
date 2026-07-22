import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/appointment/domain/entities/appointment_entity.dart';
import 'package:meu_tempo/features/appointment/domain/usecases/check_fits_in_day_use_case.dart';
import 'package:meu_tempo/features/appointment/domain/usecases/create_appointment_use_case.dart';
import 'package:meu_tempo/features/appointment/domain/usecases/delete_appointment_use_case.dart';
import 'package:meu_tempo/features/appointment/domain/usecases/watch_appointments_for_day_use_case.dart';
import 'package:meu_tempo/features/appointment/presentation/bloc/agenda_bloc.dart';
import 'package:meu_tempo/features/config/domain/entities/day_config_entity.dart';
import 'package:meu_tempo/features/config/domain/usecases/watch_config_use_case.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/usecases/ensure_inbox_exists_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/usecases/start_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/stop_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_active_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchAppts extends Mock implements WatchAppointmentsForDayUseCase {}

class _MockCreate extends Mock implements CreateAppointmentUseCase {}

class _MockDelete extends Mock implements DeleteAppointmentUseCase {}

class _MockWatchConfig extends Mock implements WatchConfigUseCase {}

class _MockWatchTasks extends Mock implements WatchTasksUseCase {}

class _MockEnsureInbox extends Mock implements EnsureInboxExistsUseCase {}

class _MockStartTimer extends Mock implements StartTimerUseCase {}

class _MockStopTimer extends Mock implements StopTimerUseCase {}

class _MockWatchActiveTimer extends Mock implements WatchActiveTimerUseCase {}

class _FakeDayParams extends Fake implements DayParams {}

class _FakeStartParams extends Fake implements StartTimerParams {}

class _FakeStopParams extends Fake implements StopTimerParams {}

class _FakeNoParams extends Fake implements NoParams {}

class _FakeCreateParams extends Fake implements CreateAppointmentParams {}

class _FakeDeleteParams extends Fake implements DeleteAppointmentParams {}

void main() {
  late _MockWatchAppts watchAppts;
  late _MockCreate create;
  late _MockDelete deleteAppt;
  late _MockWatchConfig watchConfig;
  late _MockWatchTasks watchTasks;
  late _MockEnsureInbox ensureInbox;
  late _MockStartTimer startTimer;
  late _MockStopTimer stopTimer;
  late _MockWatchActiveTimer watchActiveTimer;
  const checkFits = CheckFitsInDayUseCase();

  const inbox = TaskListEntity(id: 'inbox', name: 'Entrada', isDefault: true);

  setUpAll(() {
    registerFallbackValue(_FakeDayParams());
    registerFallbackValue(_FakeNoParams());
    registerFallbackValue(_FakeCreateParams());
    registerFallbackValue(_FakeDeleteParams());
    registerFallbackValue(_FakeStartParams());
    registerFallbackValue(_FakeStopParams());
  });

  setUp(() {
    watchAppts = _MockWatchAppts();
    create = _MockCreate();
    deleteAppt = _MockDelete();
    watchConfig = _MockWatchConfig();
    watchTasks = _MockWatchTasks();
    ensureInbox = _MockEnsureInbox();
    startTimer = _MockStartTimer();
    stopTimer = _MockStopTimer();
    watchActiveTimer = _MockWatchActiveTimer();
    when(() => ensureInbox(any())).thenAnswer((_) async => const Right(inbox));
    when(() => watchConfig(any())).thenAnswer(
      (_) => const Stream<Either<Failure, DayConfigEntity>>.empty(),
    );
    when(() => watchTasks(any())).thenAnswer(
      (_) => const Stream<Either<Failure, List<TaskEntity>>>.empty(),
    );
    when(() => watchActiveTimer(any())).thenAnswer(
      (_) => const Stream<Either<Failure, ActiveTimerEntity?>>.empty(),
    );
    when(() => startTimer(any())).thenAnswer((_) async => const Right(unit));
    when(() => stopTimer(any())).thenAnswer((_) async => const Right(unit));
  });

  AgendaBloc build() => AgendaBloc(
        watchAppts,
        create,
        deleteAppt,
        checkFits,
        watchConfig,
        watchTasks,
        ensureInbox,
        startTimer,
        stopTimer,
        watchActiveTimer,
      );

  AppointmentEntity appt(int start) => AppointmentEntity(
        id: 'a$start',
        title: 'a',
        listId: 'inbox',
        date: DateTime(2026, 7, 20),
        startMinute: start,
        durationMinutes: 60,
      );

  blocTest<AgendaBloc, AgendaState>(
    'started emite Loaded com compromissos ordenados por horário',
    build: () {
      when(() => watchAppts(any()))
          .thenAnswer((_) => Stream.value(Right([appt(900), appt(540)])));
      return build();
    },
    act: (bloc) => bloc.add(const AgendaStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const AgendaLoading(),
      isA<AgendaLoaded>().having(
        (s) => s.appointments.first.startMinute,
        'primeiro horário',
        540,
      ),
    ],
  );

  blocTest<AgendaBloc, AgendaState>(
    'propaga activeAppointmentId e activeTimerStartedAt do cronômetro ativo',
    build: () {
      final startedAt = DateTime(2026, 7, 22, 9, 15);
      when(() => watchAppts(any()))
          .thenAnswer((_) => Stream.value(Right([appt(540)])));
      when(() => watchActiveTimer(any())).thenAnswer(
        (_) => Stream.value(Right<Failure, ActiveTimerEntity?>(
          ActiveTimerEntity(
            targetId: 'a540',
            targetType: TimerTargetTypeEnum.appointment,
            listId: 'inbox',
            startedAt: startedAt,
          ),
        )),
      );
      return build();
    },
    act: (bloc) => bloc.add(const AgendaStarted()),
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      final state = bloc.state as AgendaLoaded;
      expect(state.activeAppointmentId, 'a540');
      expect(state.activeTimerStartedAt, DateTime(2026, 7, 22, 9, 15));
    },
  );

  blocTest<AgendaBloc, AgendaState>(
    'ignora startedAt quando o cronômetro ativo é de uma tarefa (não agenda)',
    build: () {
      when(() => watchAppts(any()))
          .thenAnswer((_) => Stream.value(Right([appt(540)])));
      when(() => watchActiveTimer(any())).thenAnswer(
        (_) => Stream.value(Right<Failure, ActiveTimerEntity?>(
          ActiveTimerEntity(
            targetId: 't1',
            targetType: TimerTargetTypeEnum.task,
            listId: 'inbox',
            startedAt: DateTime(2026, 7, 22, 9, 15),
          ),
        )),
      );
      return build();
    },
    act: (bloc) => bloc.add(const AgendaStarted()),
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      final state = bloc.state as AgendaLoaded;
      expect(state.activeAppointmentId, isNull);
      expect(state.activeTimerStartedAt, isNull);
    },
  );

  blocTest<AgendaBloc, AgendaState>(
    'AppointmentCreated delega ao CreateAppointmentUseCase',
    build: () {
      when(() => watchAppts(any())).thenAnswer(
        (_) => Stream.value(const Right(<AppointmentEntity>[])),
      );
      when(() => create(any())).thenAnswer((_) async => Right(appt(540)));
      return build();
    },
    act: (bloc) async {
      bloc.add(const AgendaStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const AppointmentCreated(
        title: 'Reunião',
        startMinute: 900,
        durationMinutes: 60,
      ));
    },
    verify: (_) {
      final p =
          verify(() => create(captureAny())).captured.single
              as CreateAppointmentParams;
      expect(p.title, 'Reunião');
      expect(p.startMinute, 900);
    },
  );

  blocTest<AgendaBloc, AgendaState>(
    'tarefas com prazo de hoje entram no cálculo do "cabe no dia"',
    build: () {
      when(() => watchAppts(any())).thenAnswer(
        (_) => const Stream<Either<Failure, List<AppointmentEntity>>>.empty(),
      );
      final now = DateTime.now();
      when(() => watchTasks(any())).thenAnswer(
        (_) => Stream.value(Right([
          TaskEntity(
            id: 't1',
            title: 't1',
            listId: 'inbox',
            createdAt: now,
            estimatedMinutes: 90,
            dueDate: now,
          ),
        ])),
      );
      return build();
    },
    act: (bloc) => bloc.add(const AgendaStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const AgendaLoading(),
      isA<AgendaLoaded>()
          .having((s) => s.fit.plannedMinutes, 'planejado', 90),
    ],
  );

  blocTest<AgendaBloc, AgendaState>(
    'config define as horas disponíveis do "cabe no dia"',
    build: () {
      when(() => watchAppts(any())).thenAnswer(
        (_) => const Stream<Either<Failure, List<AppointmentEntity>>>.empty(),
      );
      when(() => watchConfig(any())).thenAnswer(
        (_) => Stream.value(
          const Right(DayConfigEntity(availableMinutesPerDay: 300)),
        ),
      );
      return build();
    },
    act: (bloc) => bloc.add(const AgendaStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const AgendaLoading(),
      isA<AgendaLoaded>()
          .having((s) => s.fit.availableMinutes, 'disponível', 300),
    ],
  );

  blocTest<AgendaBloc, AgendaState>(
    'AppointmentDeleted delega ao DeleteAppointmentUseCase',
    build: () {
      when(() => watchAppts(any()))
          .thenAnswer((_) => Stream.value(Right([appt(540)])));
      when(() => deleteAppt(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      bloc.add(const AgendaStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const AppointmentDeleted('a540'));
    },
    verify: (_) {
      final p = verify(() => deleteAppt(captureAny())).captured.single
          as DeleteAppointmentParams;
      expect(p.appointmentId, 'a540');
    },
  );

  blocTest<AgendaBloc, AgendaState>(
    'AppointmentTimerStarted inicia o cronômetro com targetType appointment',
    build: () {
      when(() => watchAppts(any()))
          .thenAnswer((_) => Stream.value(Right([appt(540)])));
      return build();
    },
    act: (bloc) async {
      bloc.add(const AgendaStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const AppointmentTimerStarted('a540'));
    },
    verify: (_) {
      final p = verify(() => startTimer(captureAny())).captured.single
          as StartTimerParams;
      expect(p.targetId, 'a540');
      expect(p.targetType, TimerTargetTypeEnum.appointment);
      expect(p.listId, 'inbox');
    },
  );
}
