import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/appointment/data/datasources/appointment_remote_data_source.dart';
import 'package:meu_tempo/features/appointment/data/models/appointment_model.dart';
import 'package:meu_tempo/features/appointment/data/repositories/appointment_repository_impl.dart';
import 'package:meu_tempo/features/appointment/domain/entities/appointment_entity.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements AppointmentRemoteDataSource {}

void main() {
  late _MockDataSource dataSource;
  late AppointmentRepositoryImpl repository;

  setUp(() {
    dataSource = _MockDataSource();
    repository = AppointmentRepositoryImpl(dataSource);
  });

  final model = AppointmentModel(
    id: 'a1',
    title: 'Reunião',
    listId: 'prof',
    date: DateTime(2026, 7, 10),
    startMinute: 900,
    durationMinutes: 60,
  );

  test('watchAll converte Model → Entity no sucesso', () async {
    when(() => dataSource.watchAll())
        .thenAnswer((_) => Stream.value([model]));

    final result = await repository.watchAll().first;

    expect(result.isRight(), isTrue);
    final list = result.getRight().toNullable()!;
    expect(list, isA<List<AppointmentEntity>>());
    expect(list.single.id, 'a1');
    expect(list.single.title, 'Reunião');
  });

  test('watchAll mapeia AppException → Failure', () async {
    // O datasource lança a exceção sincronamente ao montar o stream (espelha o
    // try/catch em torno do snapshots()); o repositório traduz para Failure.
    when(() => dataSource.watchAll()).thenThrow(const ServerException());

    final result = await repository.watchAll().first;

    expect(result, const Left<Failure, List<AppointmentEntity>>(ServerFailure()));
  });
}
