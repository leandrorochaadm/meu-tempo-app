import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/usecases/delete_time_entry_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/register_manual_time_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/update_time_entry_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/watch_time_entries_by_target_use_case.dart';
import 'package:meu_tempo/features/task/presentation/bloc/time_entry_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatch extends Mock implements WatchTimeEntriesByTargetUseCase {}

class _MockRegister extends Mock implements RegisterManualTimeUseCase {}

class _MockUpdate extends Mock implements UpdateTimeEntryUseCase {}

class _MockDelete extends Mock implements DeleteTimeEntryUseCase {}

class _FakeWatchParams extends Fake
    implements WatchTimeEntriesByTargetParams {}

class _FakeRegisterParams extends Fake implements RegisterManualTimeParams {}

class _FakeUpdateParams extends Fake implements UpdateTimeEntryParams {}

class _FakeDeleteParams extends Fake implements DeleteTimeEntryParams {}

void main() {
  late _MockWatch watch;
  late _MockRegister register;
  late _MockUpdate update;
  late _MockDelete delete;
  final occurredAt = DateTime(2026, 7, 20, 9);

  final entry = TimeEntryEntity(
    id: 'e1',
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    listId: 'l1',
    minutes: 30,
    origin: TimeEntryOriginEnum.manual,
    occurredAt: occurredAt,
  );

  setUpAll(() {
    registerFallbackValue(_FakeWatchParams());
    registerFallbackValue(_FakeRegisterParams());
    registerFallbackValue(_FakeUpdateParams());
    registerFallbackValue(_FakeDeleteParams());
  });

  setUp(() {
    watch = _MockWatch();
    register = _MockRegister();
    update = _MockUpdate();
    delete = _MockDelete();
    when(() => register(any())).thenAnswer((_) async => const Right(unit));
    when(() => update(any())).thenAnswer((_) async => const Right(unit));
    when(() => delete(any())).thenAnswer((_) async => const Right(unit));
  });

  TimeEntryBloc build() => TimeEntryBloc(watch, register, update, delete);

  const started = TimeEntryStarted(targetId: 't1', listId: 'l1');

  blocTest<TimeEntryBloc, TimeEntryState>(
    'Started com registros emite [Loading, Loaded]',
    build: () {
      when(() => watch(any())).thenAnswer((_) => Stream.value(Right([entry])));
      return build();
    },
    act: (bloc) => bloc.add(started),
    expect: () => [
      isA<TimeEntryLoaded>()
          .having((s) => s.entries.single, 'registro', entry),
    ],
  );

  blocTest<TimeEntryBloc, TimeEntryState>(
    'Started sem registros emite Empty',
    build: () {
      when(() => watch(any()))
          .thenAnswer((_) => Stream.value(const Right(<TimeEntryEntity>[])));
      return build();
    },
    act: (bloc) => bloc.add(started),
    expect: () => [isA<TimeEntryEmpty>()],
  );

  blocTest<TimeEntryBloc, TimeEntryState>(
    'stream com erro emite Error',
    build: () {
      when(() => watch(any()))
          .thenAnswer((_) => Stream.value(const Left(ServerFailure())));
      return build();
    },
    act: (bloc) => bloc.add(started),
    expect: () => [isA<TimeEntryError>()],
  );

  blocTest<TimeEntryBloc, TimeEntryState>(
    'TimeEntryAdded delega ao RegisterManualTimeUseCase',
    build: () {
      when(() => watch(any()))
          .thenAnswer((_) => Stream.value(const Right(<TimeEntryEntity>[])));
      return build();
    },
    act: (bloc) async {
      bloc.add(started);
      await Future<void>.delayed(Duration.zero);
      bloc.add(TimeEntryAdded(minutes: 45, occurredAt: occurredAt));
    },
    verify: (_) {
      final p = verify(() => register(captureAny())).captured.single
          as RegisterManualTimeParams;
      expect(p.targetId, 't1');
      expect(p.minutes, 45);
      expect(p.targetIsLeaf, isTrue);
    },
  );

  blocTest<TimeEntryBloc, TimeEntryState>(
    'TimeEntryEdited delega ao UpdateTimeEntryUseCase',
    build: () {
      when(() => watch(any()))
          .thenAnswer((_) => Stream.value(Right([entry])));
      return build();
    },
    act: (bloc) async {
      bloc.add(started);
      await Future<void>.delayed(Duration.zero);
      bloc.add(TimeEntryEdited(
        original: entry,
        minutes: 60,
        occurredAt: occurredAt,
      ));
    },
    verify: (_) {
      final p = verify(() => update(captureAny())).captured.single
          as UpdateTimeEntryParams;
      expect(p.original.id, 'e1');
      expect(p.newMinutes, 60);
    },
  );

  blocTest<TimeEntryBloc, TimeEntryState>(
    'TimeEntryDeleted seguido de Undo recria o registro excluído',
    build: () {
      when(() => watch(any()))
          .thenAnswer((_) => Stream.value(Right([entry])));
      return build();
    },
    act: (bloc) async {
      bloc.add(started);
      await Future<void>.delayed(Duration.zero);
      bloc.add(TimeEntryDeleted(entry));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TimeEntryUndoRequested());
    },
    verify: (_) {
      verify(() => delete(any())).called(1);
      // O desfazer re-cria via RegisterManualTime com os mesmos minutos.
      final p = verify(() => register(captureAny())).captured.single
          as RegisterManualTimeParams;
      expect(p.minutes, 30);
      expect(p.targetId, 't1');
    },
  );
}
