import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_list_filter_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_task_list_filter_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements TaskListFilterRepository {}

void main() {
  late _MockRepository repository;
  late GetTaskListFilterUseCase useCase;

  setUp(() {
    repository = _MockRepository();
    useCase = GetTaskListFilterUseCase(repository);
  });

  test('delega ao repository e devolve o filtro salvo', () async {
    when(() => repository.getSelectedListId())
        .thenAnswer((_) async => const Right<Failure, String?>('lista-9'));

    final result = await useCase(const NoParams());

    expect(result, const Right<Failure, String?>('lista-9'));
    verify(() => repository.getSelectedListId()).called(1);
  });

  test('propaga o Left do repository', () async {
    when(() => repository.getSelectedListId())
        .thenAnswer((_) async => const Left<Failure, String?>(ServerFailure()));

    final result = await useCase(const NoParams());

    expect(result, const Left<Failure, String?>(ServerFailure()));
  });
}
