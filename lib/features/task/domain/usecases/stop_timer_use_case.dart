import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/task_repository.dart';
import '../repositories/timer_repository.dart';

class StopTimerParams extends Equatable {
  const StopTimerParams({required this.now});
  final DateTime now;

  @override
  List<Object?> get props => [now];
}

/// Para o cronômetro ativo, somando o tempo decorrido à folha.
@lazySingleton
class StopTimerUseCase implements UseCase<Unit, StopTimerParams> {
  const StopTimerUseCase(this._timerRepository, this._taskRepository);

  final TimerRepository _timerRepository;
  final TaskRepository _taskRepository;

  @override
  Future<Either<Failure, Unit>> call(StopTimerParams params) async {
    final activeResult = await _timerRepository.getActive();
    final failure = activeResult.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final active = activeResult.getRight().toNullable();
    if (active == null) return const Right(unit); // nada rodando

    final elapsed = active.elapsedMinutes(params.now);
    if (elapsed > 0) {
      await _taskRepository.addSpentMinutes(active.targetId, elapsed);
    }
    return _timerRepository.clear();
  }
}
