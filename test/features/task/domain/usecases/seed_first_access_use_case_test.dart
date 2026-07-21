import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/features/config/domain/entities/day_config_entity.dart';
import 'package:meu_tempo/features/config/domain/repositories/config_repository.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/seed_first_access_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockConfigRepo extends Mock implements ConfigRepository {}

class _MockTaskRepo extends Mock implements TaskRepository {}

class _FakeTask extends Fake implements TaskEntity {}

void main() {
  late _MockConfigRepo configRepo;
  late _MockTaskRepo taskRepo;
  final today = DateTime(2026, 7, 20);

  setUpAll(() => registerFallbackValue(_FakeTask()));

  setUp(() {
    configRepo = _MockConfigRepo();
    taskRepo = _MockTaskRepo();
    when(() => taskRepo.create(any())).thenAnswer(
      (_) async => Right(TaskEntity(
        id: 'x',
        title: 'x',
        listId: 'inbox',
        createdAt: today,
      )),
    );
    when(() => configRepo.markOnboarded())
        .thenAnswer((_) async => const Right(unit));
  });

  SeedFirstAccessUseCase useCase() =>
      SeedFirstAccessUseCase(configRepo, CreateTaskUseCase(taskRepo));

  final params = SeedFirstAccessParams(today: today, inboxListId: 'inbox');

  test('primeiro acesso: cria tarefa-exemplo e marca onboarded', () async {
    when(() => configRepo.getConfig())
        .thenAnswer((_) async => const Right(DayConfigEntity()));

    await useCase()(params);

    verify(() => taskRepo.create(any())).called(1);
    verify(() => configRepo.markOnboarded()).called(1);
  });

  test('já onboarded: não cria nada (idempotente)', () async {
    when(() => configRepo.getConfig()).thenAnswer(
      (_) async => const Right(DayConfigEntity(onboarded: true)),
    );

    await useCase()(params);

    verifyNever(() => taskRepo.create(any()));
    verifyNever(() => configRepo.markOnboarded());
  });
}
