import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/appointment_entity.dart';

abstract class AppointmentRepository {
  /// Fluxo dos compromissos de um dia (meia-noite).
  Stream<Either<Failure, List<AppointmentEntity>>> watchForDay(DateTime day);

  /// Fluxo de **todos** os compromissos do usuário. Usado pelo detalhe do
  /// relatório para resolver o nome do compromisso pelo id que veio no registro
  /// de tempo (a inclusão no relatório é decidida pelo registro, não pela data
  /// agendada do compromisso).
  Stream<Either<Failure, List<AppointmentEntity>>> watchAll();

  Future<Either<Failure, AppointmentEntity>> create(AppointmentEntity a);

  Future<Either<Failure, Unit>> delete(String appointmentId);

  /// Soma [minutes] ao tempo real do compromisso (cronômetro ou registro manual).
  Future<Either<Failure, Unit>> addSpentMinutes(
    String appointmentId,
    int minutes,
  );
}
