import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/data/datasources/task_list_filter_local_data_source.dart';
import 'package:meu_tempo/features/task/data/repositories/task_list_filter_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements TaskListFilterLocalDataSource {}

void main() {
  late _MockDataSource dataSource;
  late TaskListFilterRepositoryImpl repository;

  setUp(() {
    dataSource = _MockDataSource();
    repository = TaskListFilterRepositoryImpl(dataSource);
  });

  group('getSelectedListId', () {
    test('devolve Right com o valor do datasource', () async {
      when(() => dataSource.getSelectedListId()).thenReturn('lista-1');
      final result = await repository.getSelectedListId();
      expect(result, const Right<Failure, String?>('lista-1'));
    });

    test('erro do datasource vira Left(ServerFailure)', () async {
      when(() => dataSource.getSelectedListId()).thenThrow(Exception('boom'));
      final result = await repository.getSelectedListId();
      expect(result, const Left<Failure, String?>(ServerFailure()));
    });
  });

  group('setSelectedListId', () {
    test('delega ao datasource e devolve Right(unit)', () async {
      when(() => dataSource.setSelectedListId(any())).thenAnswer((_) async {});
      final result = await repository.setSelectedListId('lista-2');
      expect(result, const Right<Failure, Unit>(unit));
      verify(() => dataSource.setSelectedListId('lista-2')).called(1);
    });

    test('erro do datasource vira Left(ServerFailure)', () async {
      when(() => dataSource.setSelectedListId(any()))
          .thenThrow(Exception('boom'));
      final result = await repository.setSelectedListId('lista-2');
      expect(result, const Left<Failure, Unit>(ServerFailure()));
    });
  });
}
