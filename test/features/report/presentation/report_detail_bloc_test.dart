import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/appointment/domain/entities/appointment_entity.dart';
import 'package:meu_tempo/features/appointment/domain/usecases/watch_all_appointments_use_case.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/usecases/watch_lists_use_case.dart';
import 'package:meu_tempo/features/report/domain/entities/report_period_enum.dart';
import 'package:meu_tempo/features/report/domain/entities/task_report_sort_enum.dart';
import 'package:meu_tempo/features/report/domain/usecases/get_task_report_use_case.dart';
import 'package:meu_tempo/features/report/presentation/bloc/report_detail_bloc.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_time_entries_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchTasks extends Mock implements WatchTasksUseCase {}

class _MockWatchAppointments extends Mock
    implements WatchAllAppointmentsUseCase {}

class _MockWatchEntries extends Mock implements WatchTimeEntriesUseCase {}

class _MockWatchLists extends Mock implements WatchListsUseCase {}

class _FakeNoParams extends Fake implements NoParams {}

class _FakeEntriesParams extends Fake implements WatchTimeEntriesParams {}

class _FakeTasksParams extends Fake implements WatchTasksParams {}

void main() {
  late _MockWatchTasks watchTasks;
  late _MockWatchAppointments watchAppts;
  late _MockWatchEntries watchEntries;
  late _MockWatchLists watchLists;
  const getTaskReport = GetTaskReportUseCase();
  final today = DateTime(2026, 7, 20);

  setUpAll(() {
    registerFallbackValue(_FakeNoParams());
    registerFallbackValue(const WatchTasksParams());
    registerFallbackValue(_FakeEntriesParams());
    registerFallbackValue(_FakeTasksParams());
  });

  setUp(() {
    watchTasks = _MockWatchTasks();
    watchAppts = _MockWatchAppointments();
    watchEntries = _MockWatchEntries();
    watchLists = _MockWatchLists();
    when(() => watchTasks(any())).thenAnswer(
      (_) => Stream.value(Right(<TaskEntity>[
        TaskEntity(
          id: 't1',
          title: 'Montar proposta',
          listId: 'prof',
          createdAt: today,
          estimatedMinutes: 60,
        ),
      ])),
    );
    when(() => watchAppts(any())).thenAnswer(
      (_) => Stream.value(Right(<AppointmentEntity>[])),
    );
    when(() => watchLists(any())).thenAnswer(
      (_) => Stream.value(const Right(<TaskListEntity>[
        TaskListEntity(id: 'prof', name: 'Profissional'),
      ])),
    );
    when(() => watchEntries(any())).thenAnswer(
      (_) => Stream.value(Right(<TimeEntryEntity>[
        TimeEntryEntity(
          id: 'e1',
          targetId: 't1',
          targetType: TimerTargetTypeEnum.task,
          listId: 'prof',
          minutes: 90,
          origin: TimeEntryOriginEnum.timer,
          occurredAt: today,
        ),
      ])),
    );
  });

  ReportDetailBloc build() => ReportDetailBloc(
        watchTasks,
        watchAppts,
        watchEntries,
        watchLists,
        getTaskReport,
      );

  ReportDetailStarted started() => const ReportDetailStarted(
        listId: 'prof',
        period: ReportPeriodEnum.week,
        offset: 0,
        listName: 'Profissional',
      );

  // Os 4 streams emitem e cada update re-emite Loaded; por isso asseguramos o
  // ESTADO FINAL (via verify), não a sequência intermediária.
  blocTest<ReportDetailBloc, ReportDetailState>(
    'started agrega a tarefa da lista no período',
    build: build,
    act: (bloc) => bloc.add(started()),
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      final s = bloc.state;
      expect(s, isA<ReportDetailLoaded>());
      s as ReportDetailLoaded;
      expect(s.report.nodes.length, 1);
      expect(s.report.nodes.first.spentMinutes, 90);
      expect(s.report.nodes.first.overrunMinutes, 30);
      expect(s.listName, 'Profissional');
    },
  );

  blocTest<ReportDetailBloc, ReportDetailState>(
    'resolve o nome da lista pelo id quando listName vem nulo',
    build: build,
    act: (bloc) => bloc.add(const ReportDetailStarted(
      listId: 'prof',
      period: ReportPeriodEnum.week,
      offset: 0,
    )),
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      expect((bloc.state as ReportDetailLoaded).listName, 'Profissional');
    },
  );

  blocTest<ReportDetailBloc, ReportDetailState>(
    'ReportDetailSortChanged re-emite Loaded com a nova ordenação',
    build: build,
    act: (bloc) async {
      bloc.add(started());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ReportDetailSortChanged(TaskReportSortEnum.overrun));
    },
    wait: const Duration(milliseconds: 30),
    verify: (bloc) {
      expect(
        (bloc.state as ReportDetailLoaded).sort,
        TaskReportSortEnum.overrun,
      );
    },
  );

  blocTest<ReportDetailBloc, ReportDetailState>(
    'entries com erro emite ReportDetailError',
    build: () {
      // Isola: só entries emite (Left); os demais não emitem, para o Error
      // ser o estado final e não ser sobrescrito por um Loaded de sucesso.
      when(() => watchTasks(any())).thenAnswer(
        (_) => const Stream<Either<Failure, List<TaskEntity>>>.empty(),
      );
      when(() => watchAppts(any())).thenAnswer(
        (_) => const Stream<Either<Failure, List<AppointmentEntity>>>.empty(),
      );
      when(() => watchLists(any())).thenAnswer(
        (_) => const Stream<Either<Failure, List<TaskListEntity>>>.empty(),
      );
      when(() => watchEntries(any())).thenAnswer(
        (_) => Stream.value(const Left(ServerFailure())),
      );
      return build();
    },
    act: (bloc) => bloc.add(started()),
    wait: const Duration(milliseconds: 20),
    verify: (bloc) => expect(bloc.state, isA<ReportDetailError>()),
  );
}
