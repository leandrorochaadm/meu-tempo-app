import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/appointment/domain/repositories/appointment_repository.dart';
import 'package:meu_tempo/features/appointment/domain/usecases/set_appointment_done_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AppointmentRepository {}

void main() {
  late _MockRepo repository;
  late SetAppointmentDoneUseCase useCase;

  setUp(() {
    repository = _MockRepo();
    useCase = SetAppointmentDoneUseCase(repository);
  });

  test('concluir chama setDone(id, true) e devolve Right', () async {
    when(() => repository.setDone('a1', true))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(
      const SetAppointmentDoneParams(appointmentId: 'a1', done: true),
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.setDone('a1', true)).called(1);
  });

  test('reabrir chama setDone(id, false) e devolve Right', () async {
    when(() => repository.setDone('a1', false))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(
      const SetAppointmentDoneParams(appointmentId: 'a1', done: false),
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.setDone('a1', false)).called(1);
  });

  test('repassa o Failure do repositório', () async {
    when(() => repository.setDone('a1', true))
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result = await useCase(
      const SetAppointmentDoneParams(appointmentId: 'a1', done: true),
    );

    expect(result, const Left<Failure, Unit>(ServerFailure()));
  });

  test('compromisso inexistente devolve NotFoundFailure', () async {
    when(() => repository.setDone('x', true))
        .thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase(
      const SetAppointmentDoneParams(appointmentId: 'x', done: true),
    );

    expect(result, const Left<Failure, Unit>(NotFoundFailure()));
  });

  test('Params com mesmos valores são iguais', () {
    expect(
      const SetAppointmentDoneParams(appointmentId: 'a1', done: true),
      equals(const SetAppointmentDoneParams(appointmentId: 'a1', done: true)),
    );
    expect(
      const SetAppointmentDoneParams(appointmentId: 'a1', done: true),
      isNot(equals(
        const SetAppointmentDoneParams(appointmentId: 'a1', done: false),
      )),
    );
  });
}
