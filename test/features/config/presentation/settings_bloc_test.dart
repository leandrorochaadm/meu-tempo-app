import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/config/domain/entities/day_config_entity.dart';
import 'package:meu_tempo/features/config/domain/usecases/set_available_minutes_use_case.dart';
import 'package:meu_tempo/features/config/domain/usecases/watch_config_use_case.dart';
import 'package:meu_tempo/features/config/presentation/bloc/settings_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchConfig extends Mock implements WatchConfigUseCase {}

class _MockSetAvailable extends Mock implements SetAvailableMinutesUseCase {}

class _FakeNoParams extends Fake implements NoParams {}

class _FakeSetParams extends Fake implements SetAvailableMinutesParams {}

void main() {
  late _MockWatchConfig watchConfig;
  late _MockSetAvailable setAvailable;

  setUpAll(() {
    registerFallbackValue(_FakeNoParams());
    registerFallbackValue(_FakeSetParams());
  });

  setUp(() {
    watchConfig = _MockWatchConfig();
    setAvailable = _MockSetAvailable();
  });

  SettingsBloc build() => SettingsBloc(watchConfig, setAvailable);

  blocTest<SettingsBloc, SettingsState>(
    'started emite Loaded com as horas disponíveis atuais',
    build: () {
      when(() => watchConfig(any())).thenAnswer(
        (_) => Stream.value(
          const Right(DayConfigEntity(availableMinutesPerDay: 300)),
        ),
      );
      return build();
    },
    act: (bloc) => bloc.add(const SettingsStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const SettingsLoading(),
      const SettingsLoaded(300),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'AvailableMinutesChanged delega ao SetAvailableMinutesUseCase',
    build: () {
      when(() => watchConfig(any())).thenAnswer(
        (_) => const Stream<Either<Failure, DayConfigEntity>>.empty(),
      );
      when(() => setAvailable(any()))
          .thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) async {
      bloc.add(const SettingsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const AvailableMinutesChanged(600));
    },
    verify: (_) {
      final p = verify(() => setAvailable(captureAny())).captured.single
          as SetAvailableMinutesParams;
      expect(p.minutes, 600);
    },
  );

  blocTest<SettingsBloc, SettingsState>(
    'stream de config com erro emite SettingsError',
    build: () {
      when(() => watchConfig(any())).thenAnswer(
        (_) => Stream.value(const Left(ServerFailure())),
      );
      return build();
    },
    act: (bloc) => bloc.add(const SettingsStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [const SettingsLoading(), const SettingsError()],
  );
}
