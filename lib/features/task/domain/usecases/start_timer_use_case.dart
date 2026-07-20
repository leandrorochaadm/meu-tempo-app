import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/active_timer_entity.dart';
import '../repositories/task_repository.dart';
import '../repositories/timer_repository.dart';
import '../task_failures.dart';

class StartTimerParams extends Equatable {
  const StartTimerParams({
    required this.targetId,
    required this.targetIsLeaf,
    required this.now,
  });

  final String targetId;
  final bool targetIsLeaf;
  final DateTime now;

  @override
  List<Object?> get props => [targetId, targetIsLeaf, now];
}

/// Inicia o cronômetro numa folha. **Só 1 ativo por vez:** se já houver outro
/// rodando, ele é pausado e seu tempo decorrido é somado antes de iniciar o novo.
@lazySingleton
class StartTimerUseCase implements UseCase<Unit, StartTimerParams> {
  const StartTimerUseCase(this._timerRepository, this._taskRepository);

  final TimerRepository _timerRepository;
  final TaskRepository _taskRepository;

  @override
  Future<Either<Failure, Unit>> call(StartTimerParams params) async {
    if (!params.targetIsLeaf) return const Left(TimerOnNonLeafFailure());

    final activeResult = await _timerRepository.getActive();
    final failure = activeResult.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final active = activeResult.getRight().toNullable();
    if (active != null) {
      // Pausa o anterior, somando o tempo decorrido.
      final elapsed = active.elapsedMinutes(params.now);
      if (elapsed > 0) {
        await _taskRepository.addSpentMinutes(active.targetId, elapsed);
      }
    }

    return _timerRepository.setActive(
      ActiveTimerEntity(targetId: params.targetId, startedAt: params.now),
    );
  }
}
