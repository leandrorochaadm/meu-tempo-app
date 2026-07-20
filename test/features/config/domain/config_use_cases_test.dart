import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/config/domain/entities/day_config_entity.dart';
import 'package:meu_tempo/features/config/domain/repositories/config_repository.dart';
import 'package:meu_tempo/features/config/domain/usecases/set_available_minutes_use_case.dart';
import 'package:meu_tempo/features/config/domain/usecases/watch_config_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockConfigRepo extends Mock implements ConfigRepository {}

void main() {
  late _MockConfigRepo repo;

  setUp(() => repo = _MockConfigRepo());

  test('WatchConfigUseCase repassa o stream', () {
    when(() => repo.watchConfig()).thenAnswer(
      (_) => Stream.value(const Right(DayConfigEntity(availableMinutesPerDay: 300))),
    );
    expect(
      WatchConfigUseCase(repo)(const NoParams()),
      emits(isA<Right<Failure, DayConfigEntity>>()),
    );
  });

  test('SetAvailableMinutes normaliza valores <= 0 para 1', () async {
    when(() => repo.setAvailableMinutes(any()))
        .thenAnswer((_) async => const Right(unit));

    await SetAvailableMinutesUseCase(repo)(
      const SetAvailableMinutesParams(0),
    );

    verify(() => repo.setAvailableMinutes(1)).called(1);
  });

  test('SetAvailableMinutes repassa valor válido', () async {
    when(() => repo.setAvailableMinutes(any()))
        .thenAnswer((_) async => const Right(unit));

    await SetAvailableMinutesUseCase(repo)(
      const SetAvailableMinutesParams(360),
    );

    verify(() => repo.setAvailableMinutes(360)).called(1);
  });
}
