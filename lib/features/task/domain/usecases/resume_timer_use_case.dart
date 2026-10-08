import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/active_timer_entity.dart';
import '../entities/timer_status_enum.dart';
import '../repositories/timer_repository.dart';

class ResumeTimerParams extends Equatable {
  const ResumeTimerParams({required this.targetId, required this.now});

  /// Alvo pausado que quem pediu estava vendo; outro alvo ativo → no-op.
  final String targetId;
  final DateTime now;

  @override
  List<Object?> get props => [targetId, now];
}

/// Continua o cronômetro pausado de [ResumeTimerParams.targetId]: o mesmo alvo
/// volta a contar a partir de agora (a sessão anterior já foi somada ao
/// pausar). Idempotente: já rodando, outro alvo, sem cronômetro ou corrida
/// perdida → `Right(unit)` sem gravar nada.
@lazySingleton
class ResumeTimerUseCase implements UseCase<Unit, ResumeTimerParams> {
  const ResumeTimerUseCase(this._timerRepository);

  final TimerRepository _timerRepository;

  @override
  Future<Either<Failure, Unit>> call(ResumeTimerParams params) async {
    final current = await _timerRepository.getActive();
    final failure = current.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final active = current.getRight().toNullable();
    if (active == null ||
        active.targetId != params.targetId ||
        active.isRunning) {
      return const Right(unit);
    }

    final replaced = await _timerRepository.replaceActiveIfUnchanged(
      expected: active,
      replacement: ActiveTimerEntity(
        targetId: active.targetId,
        targetType: active.targetType,
        listId: active.listId,
        startedAt: params.now,
        status: TimerStatusEnum.running,
      ),
    );
    return replaced.map((_) => unit);
  }
}
