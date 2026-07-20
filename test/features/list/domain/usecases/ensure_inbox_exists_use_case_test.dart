import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/constants/app_defaults.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/repositories/task_list_repository.dart';
import 'package:meu_tempo/features/list/domain/usecases/ensure_inbox_exists_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskListRepository extends Mock implements TaskListRepository {}

class _FakeTaskListEntity extends Fake implements TaskListEntity {}

void main() {
  late _MockTaskListRepository repository;
  late EnsureInboxExistsUseCase useCase;

  setUpAll(() => registerFallbackValue(_FakeTaskListEntity()));

  setUp(() {
    repository = _MockTaskListRepository();
    useCase = EnsureInboxExistsUseCase(repository);
  });

  test('devolve a Entrada existente sem criar outra', () async {
    const inbox = TaskListEntity(id: 'l1', name: 'Entrada', isDefault: true);
    when(() => repository.getLists())
        .thenAnswer((_) async => const Right([inbox]));

    final result = await useCase(const NoParams());

    expect(result.getRight().toNullable(), inbox);
    verifyNever(() => repository.create(any()));
  });

  test('cria a Entrada quando não há lista default', () async {
    when(() => repository.getLists())
        .thenAnswer((_) async => const Right(<TaskListEntity>[]));
    when(() => repository.create(any())).thenAnswer(
      (inv) async => Right(
        (inv.positionalArguments.first as TaskListEntity),
      ),
    );

    final result = await useCase(const NoParams());

    final captured =
        verify(() => repository.create(captureAny())).captured.single
            as TaskListEntity;
    expect(captured.name, AppDefaults.inboxListName);
    expect(captured.isDefault, isTrue);
    expect(result.isRight(), isTrue);
  });

  test('propaga Left quando a leitura falha', () async {
    when(() => repository.getLists())
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result = await useCase(const NoParams());

    expect(result, isA<Left<Failure, TaskListEntity>>());
    verifyNever(() => repository.create(any()));
  });
}
