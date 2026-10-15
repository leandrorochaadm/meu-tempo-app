import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/data/datasources/task_remote_data_source.dart';
import 'package:meu_tempo/features/task/data/models/task_model.dart';
import 'package:meu_tempo/features/task/data/repositories/task_repository_impl.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements TaskRemoteDataSource {}

class _FakeModel extends Fake implements TaskModel {}

void main() {
  late _MockDataSource dataSource;
  late TaskRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(_FakeModel()));

  setUp(() {
    dataSource = _MockDataSource();
    repository = TaskRepositoryImpl(dataSource);
  });

  final task = TaskEntity(
    id: '',
    title: 'Academia',
    listId: 'inbox',
    createdAt: DateTime(2026, 10, 15),
  );

  test('create should return ServerFailure on an unexpected error', () async {
    when(() => dataSource.create(any())).thenThrow(StateError('bad doc'));

    final result = await repository.create(task);

    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });

  test('getTasks should return ServerFailure on an unexpected error', () async {
    when(() => dataSource.getTasks()).thenThrow(StateError('bad doc'));

    final result = await repository.getTasks();

    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });
}
