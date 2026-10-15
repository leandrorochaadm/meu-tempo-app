import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/repositories/recurring_task_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/delete_recurring_task_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecurringTaskRepository extends Mock
    implements RecurringTaskRepository {}

void main() {
  late _MockRecurringTaskRepository repository;
  late DeleteRecurringTaskUseCase useCase;

  setUp(() {
    repository = _MockRecurringTaskRepository();
    useCase = DeleteRecurringTaskUseCase(repository);
  });

  test('should delete by id', () async {
    when(() => repository.delete('r1')).thenAnswer((_) async => Right(unit));

    final result = await useCase(const DeleteRecurringTaskParams(id: 'r1'));

    expect(result, Right<Failure, Unit>(unit));
    verify(() => repository.delete('r1')).called(1);
  });

  test('should return repository failure', () async {
    when(
      () => repository.delete('r1'),
    ).thenAnswer((_) async => const Left(ServerFailure()));

    final result = await useCase(const DeleteRecurringTaskParams(id: 'r1'));

    expect(result, const Left<Failure, Unit>(ServerFailure()));
  });
}
