import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/appointment_entity.dart';
import '../repositories/appointment_repository.dart';

/// Fluxo de todos os compromissos do usuário (usado pelo detalhe do relatório
/// para resolver o nome do compromisso pelo id do registro de tempo).
@lazySingleton
class WatchAllAppointmentsUseCase
    implements StreamUseCase<Either<Failure, List<AppointmentEntity>>, NoParams> {
  const WatchAllAppointmentsUseCase(this._repository);

  final AppointmentRepository _repository;

  @override
  Stream<Either<Failure, List<AppointmentEntity>>> call(NoParams params) =>
      _repository.watchAll();
}
