import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/active_timer_entity.dart';
import '../repositories/timer_repository.dart';

/// Fluxo do cronômetro ativo do usuário.
@lazySingleton
class WatchActiveTimerUseCase
    implements StreamUseCase<Either<Failure, ActiveTimerEntity?>, NoParams> {
  const WatchActiveTimerUseCase(this._repository);

  final TimerRepository _repository;

  @override
  Stream<Either<Failure, ActiveTimerEntity?>> call(NoParams params) =>
      _repository.watchActive();
}
