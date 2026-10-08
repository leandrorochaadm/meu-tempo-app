import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/active_timer_entity.dart';
import '../entities/timer_status_enum.dart';
import '../entities/timer_target_type_enum.dart';
import '../repositories/timer_repository.dart';
import '../task_failures.dart';
import 'record_timer_session_use_case.dart';

class StartTimerParams extends Equatable {
  const StartTimerParams({
    required this.targetId,
    required this.targetType,
    required this.targetIsLeaf,
    required this.listId,
    required this.now,
  });

  final String targetId;
  final TimerTargetTypeEnum targetType;

  /// Só relevante para tarefa (compromisso sempre pode ter cronômetro).
  final bool targetIsLeaf;

  /// Lista à qual o alvo pertence — persistida no cronômetro ativo para montar
  /// o registro de tempo ao pausar/parar.
  final String listId;
  final DateTime now;

  @override
  List<Object?> get props => [targetId, targetType, targetIsLeaf, listId, now];
}

/// Inicia o cronômetro numa folha ou compromisso. **Só 1 ativo por vez:** se já
/// houver outro (rodando ou pausado), ele é encerrado; a sessão do que estava
/// rodando é somada ao alvo certo (tarefa ou compromisso) com um registro de
/// tempo datado. Dar start no mesmo alvo pausado volta a contar (equivale a
/// continuar).
@lazySingleton
class StartTimerUseCase implements UseCase<Unit, StartTimerParams> {
  const StartTimerUseCase(this._timerRepository, this._recordSession);

  final TimerRepository _timerRepository;
  final RecordTimerSessionUseCase _recordSession;

  @override
  Future<Either<Failure, Unit>> call(StartTimerParams params) async {
    // A trava de folha só vale para tarefa; compromisso sempre pode.
    if (params.targetType == TimerTargetTypeEnum.task && !params.targetIsLeaf) {
      return const Left(TimerOnNonLeafFailure());
    }

    // Reivindica o anterior atomicamente (lê e limpa): entre toques concorrentes
    // no play, só um recebe o cronômetro anterior e soma seu tempo — evita somar
    // a mesma sessão anterior mais de uma vez (mesma idempotência do parar).
    final claimed = await _timerRepository.claimActive();
    final failure = claimed.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final active = claimed.getRight().toNullable();
    if (active != null) {
      // Encerra o anterior somando a sessão ao alvo certo. Pausado não soma
      // (elapsedMinutes = 0). Falha ao somar não impede o novo start: o
      // anterior já foi reivindicado e o usuário precisa do cronômetro novo.
      await _recordSession(
        RecordTimerSessionParams(session: active, now: params.now),
      );
    }

    return _timerRepository.setActive(ActiveTimerEntity(
      targetId: params.targetId,
      targetType: params.targetType,
      listId: params.listId,
      startedAt: params.now,
      status: TimerStatusEnum.running,
    ));
  }
}
