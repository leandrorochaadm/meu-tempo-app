import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/appointment/domain/entities/appointment_entity.dart';
import 'package:meu_tempo/features/appointment/domain/failures.dart';
import 'package:meu_tempo/features/appointment/domain/repositories/appointment_repository.dart';
import 'package:meu_tempo/features/appointment/domain/usecases/check_fits_in_day_use_case.dart';
import 'package:meu_tempo/features/appointment/domain/usecases/create_appointment_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AppointmentRepository {}

class _FakeAppointment extends Fake implements AppointmentEntity {}

void main() {
  final today = DateTime(2026, 7, 20);

  setUpAll(() => registerFallbackValue(_FakeAppointment()));

  group('CheckFitsInDayUseCase', () {
    const useCase = CheckFitsInDayUseCase();

    test('soma tarefas + compromissos e compara com o disponível', () {
      final fit = useCase(
        taskDurations: [60, 30],
        appointmentDurations: [60],
        availableMinutes: 480,
      );
      expect(fit.plannedMinutes, 150);
      expect(fit.fits, isTrue);
      expect(fit.overflowMinutes, 0);
    });

    test('sinaliza estouro quando passa do disponível', () {
      final fit = useCase(
        taskDurations: [300],
        appointmentDurations: [300],
        availableMinutes: 480,
      );
      expect(fit.fits, isFalse);
      expect(fit.overflowMinutes, 120);
    });
  });

  group('CreateAppointmentUseCase', () {
    late _MockRepo repo;
    setUp(() => repo = _MockRepo());

    test('recusa título vazio', () async {
      final r = await CreateAppointmentUseCase(repo)(
        CreateAppointmentParams(
          title: '  ',
          listId: 'inbox',
          date: today,
          startMinute: 540,
          durationMinutes: 60,
        ),
      );
      r.getLeft().fold(() => fail('esperava Left'),
          (f) => expect(f, isA<EmptyAppointmentTitleFailure>()));
    });

    test('recusa duração <= 0', () async {
      final r = await CreateAppointmentUseCase(repo)(
        CreateAppointmentParams(
          title: 'Reunião',
          listId: 'inbox',
          date: today,
          startMinute: 540,
          durationMinutes: 0,
        ),
      );
      expect(r, isA<Left<Failure, AppointmentEntity>>());
    });

    test('cria com data normalizada para meia-noite', () async {
      when(() => repo.create(any())).thenAnswer(
        (inv) async => Right(inv.positionalArguments.first as AppointmentEntity),
      );
      await CreateAppointmentUseCase(repo)(
        CreateAppointmentParams(
          title: 'Reunião',
          listId: 'prof',
          date: DateTime(2026, 7, 20, 15, 30),
          startMinute: 900,
          durationMinutes: 60,
        ),
      );
      final captured =
          verify(() => repo.create(captureAny())).captured.single
              as AppointmentEntity;
      expect(captured.date, DateTime(2026, 7, 20));
      expect(captured.endMinute, 960);
    });
  });
}
