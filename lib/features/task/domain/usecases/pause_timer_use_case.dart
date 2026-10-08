import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/active_timer_entity.dart';
import '../entities/timer_status_enum.dart';
import '../repositories/timer_repository.dart';
import 'record_timer_session_use_case.dart';

class PauseTimerParams extends Equatable {
  const PauseTimerParams({required this.targetId, required this.now});

  /// Alvo que quem pediu a pausa estava vendo. Se o cronômetro ativo for
  /// outro (ex.: start dado em outro celular), a pausa vira no-op.
  final String targetId;
  final DateTime now;

  @override
  List<Object?> get props => [targetId, now];
}

/// Pausa o cronômetro ativo de [PauseTimerParams.targetId] (tarefa ou
/// compromisso): soma a sessão ao alvo, grava o registro de tempo e mantém o
/// mesmo alvo como pausado — ele continua existindo até continuar, parar ou
/// dar start em outro. Idempotente: já pausado, outro alvo, sem cronômetro ou
/// corrida perdida para outro toque → `Right(unit)` sem gravar nada.
@lazySingleton
class PauseTimerUseCase implements UseCase<Unit, PauseTimerParams> {
  const PauseTimerUseCase(this._timerRepository, this._recordSession);

  final TimerRepository _timerRepository;
  final RecordTimerSessionUseCase _recordSession;

  @override
  Future<Either<Failure, Unit>> call(PauseTimerParams params) async {
    final current = await _timerRepository.getActive();
    final failure = current.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final active = current.getRight().toNullable();
    if (active == null ||
        active.targetId != params.targetId ||
        active.isPaused) {
      return const Right(unit);
    }

    final replaced = await _timerRepository.replaceActiveIfUnchanged(
      expected: active,
      replacement: ActiveTimerEntity(
        targetId: active.targetId,
        targetType: active.targetType,
        listId: active.listId,
        startedAt: params.now,
        status: TimerStatusEnum.paused,
      ),
    );
    final replaceFailure = replaced.getLeft().toNullable();
    if (replaceFailure != null) return Left(replaceFailure);
    // Outro toque/celular mudou o cronômetro antes: quem venceu já registrou.
    if (replaced.getRight().toNullable() != true) return const Right(unit);

    return _recordSession(
      RecordTimerSessionParams(session: active, now: params.now),
    );
  }
}
