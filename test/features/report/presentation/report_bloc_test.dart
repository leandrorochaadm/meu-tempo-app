import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/usecases/watch_lists_use_case.dart';
import 'package:meu_tempo/features/report/domain/usecases/get_list_report_use_case.dart';
import 'package:meu_tempo/features/report/presentation/bloc/report_bloc.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchTasks extends Mock implements WatchTasksUseCase {}

class _MockWatchLists extends Mock implements WatchListsUseCase {}

class _FakeNoParams extends Fake implements NoParams {}

void main() {
  late _MockWatchTasks watchTasks;
  late _MockWatchLists watchLists;
  const getReport = GetListReportUseCase();
  final today = DateTime(2026, 7, 20);

  setUpAll(() => registerFallbackValue(_FakeNoParams()));

  setUp(() {
    watchTasks = _MockWatchTasks();
    watchLists = _MockWatchLists();
    when(() => watchLists(any())).thenAnswer(
      (_) => const Stream<Either<Failure, List<TaskListEntity>>>.empty(),
    );
  });

  ReportBloc build() => ReportBloc(watchTasks, watchLists, getReport);

  blocTest<ReportBloc, ReportState>(
    'started emite Loaded com linhas agregadas',
    build: () {
      when(() => watchTasks(any())).thenAnswer((_) => Stream.value(Right([
            TaskEntity(
              id: 't1',
              title: 't1',
              listId: 'inbox',
              createdAt: today,
              estimatedMinutes: 60,
              spentMinutes: 30,
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
    'stream com erro emite ReportError',
    build: () {
      when(() => watchTasks(any())).thenAnswer(
        (_) => Stream.value(const Left(ServerFailure())),
      );
      return build();
    },
    act: (bloc) => bloc.add(const ReportStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [const ReportLoading(), const ReportError()],
  );
}
