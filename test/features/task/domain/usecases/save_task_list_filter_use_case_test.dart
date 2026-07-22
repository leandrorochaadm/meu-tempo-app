import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_list_filter_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/save_task_list_filter_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements TaskListFilterRepository {}

void main() {
  late _MockRepository repository;
  late SaveTaskListFilterUseCase useCase;

  setUp(() {
    repository = _MockRepository();
    useCase = SaveTaskListFilterUseCase(repository);
  });

  test('delega o listId escolhido ao repository', () async {
    when(() => repository.setSelectedListId(any()))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(const SaveTaskListFilterParams('lista-3'));

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.setSelectedListId('lista-3')).called(1);
  });

  test('repassa null (limpar filtro) ao repository', () async {
    when(() => repository.setSelectedListId(any()))
        .thenAnswer((_) async => const Right(unit));

    await useCase(const SaveTaskListFilterParams(null));

    verify(() => repository.setSelectedListId(null)).called(1);
  });
}
