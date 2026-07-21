import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/usecases/watch_lists_use_case.dart';
import 'package:meu_tempo/features/report/domain/entities/report_period_enum.dart';
import 'package:meu_tempo/features/report/domain/usecases/get_list_report_use_case.dart';
import 'package:meu_tempo/features/report/presentation/bloc/report_bloc.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_time_entries_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchTasks extends Mock implements WatchTasksUseCase {}

class _MockWatchLists extends Mock implements WatchListsUseCase {}

class _MockWatchEntries extends Mock implements WatchTimeEntriesUseCase {}

class _FakeNoParams extends Fake implements NoParams {}

class _FakeEntriesParams extends Fake implements WatchTimeEntriesParams {}

void main() {
  late _MockWatchTasks watchTasks;
  late _MockWatchLists watchLists;
  late _MockWatchEntries watchEntries;
  const getReport = GetListReportUseCase();
  final today = DateTime(2026, 7, 20);

  setUpAll(() {
    registerFallbackValue(_FakeNoParams());
    registerFallbackValue(_FakeEntriesParams());
  });

  setUp(() {
    watchTasks = _MockWatchTasks();
    watchLists = _MockWatchLists();
    watchEntries = _MockWatchEntries();
    when(() => watchLists(any())).thenAnswer(
      (_) => const Stream<Either<Failure, List<TaskListEntity>>>.empty(),
    );
    when(() => watchTasks(any())).thenAnswer(
      (_) => const Stream<Either<Failure, List<TaskEntity>>>.empty(),
    );
    when(() => watchEntries(any())).thenAnswer(
      (_) => const Stream<Either<Failure, List<TimeEntryEntity>>>.empty(),
    );
  });

  ReportBloc build() =>
      ReportBloc(watchTasks, watchLists, watchEntries, getReport);

  blocTest<ReportBloc, ReportState>(
    'started emite Loaded com linhas agregadas a partir das entries',
    build: () {
      when(() => watchEntries(any())).thenAnswer((_) => Stream.value(Right([
            TimeEntryEntity(
              id: 'e1',
              targetId: 't1',
              targetType: TimerTargetTypeEnum.task,
              listId: 'inbox',
              minutes: 30,
              origin: TimeEntryOriginEnum.timer,
              occurredAt: today,
            ),
          ])));
      return build();
    },
    act: (bloc) => bloc.add(const ReportStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const ReportLoading(),
      isA<ReportLoaded>().having((s) => s.rows.first.spentMinutes, 'real', 30),
    ],
  );

  blocTest<ReportBloc, ReportState>(
    'entries com erro emite ReportError',
    build: () {
      when(() => watchEntries(any())).thenAnswer(
        (_) => Stream.value(const Left(ServerFailure())),
      );
      return build();
    },
    act: (bloc) => bloc.add(const ReportStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [const ReportLoading(), const ReportError()],
  );

  blocTest<ReportBloc, ReportState>(
    'ReportPeriodChanged re-emite Loaded com o novo período',
    build: build,
    act: (bloc) async {
      bloc.add(const ReportStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const ReportPeriodChanged(ReportPeriodEnum.week));
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      // Assina entries ao iniciar e novamente ao trocar de período.
      verify(() => watchEntries(any())).called(2);
    },
  );
}
