import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/timer_repository.dart';
import 'record_timer_session_use_case.dart';

class StopTimerParams extends Equatable {
  const StopTimerParams({required this.now});
  final DateTime now;

  @override
  List<Object?> get props => [now];
}

/// Para o cronômetro ativo (rodando ou pausado), somando a sessão do que estava
/// rodando ao alvo correto (tarefa ou compromisso) e gravando o registro de
/// tempo datado.
@lazySingleton
class StopTimerUseCase implements UseCase<Unit, StopTimerParams> {
  const StopTimerUseCase(this._timerRepository, this._recordSession);

  final TimerRepository _timerRepository;
  final RecordTimerSessionUseCase _recordSession;

  @override
  Future<Either<Failure, Unit>> call(StopTimerParams params) async {
    // `claimActive` lê e limpa o cronômetro atomicamente: entre vários toques
    // no "Parar" concorrentes, só um recebe o timer — os demais recebem `null`
    // e viram no-op. Isso torna o parar **idempotente**: o tempo é registrado
    // uma única vez, sem durações repetidas.
    final claimed = await _timerRepository.claimActive();
    final failure = claimed.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final active = claimed.getRight().toNullable();
    if (active == null) return const Right(unit); // já parado — nada a registrar

    // Pausado não soma (elapsedMinutes = 0). Falha ao somar não muda o
    // resultado: o claim já limpou o cronômetro (comportamento atual).
    await _recordSession(
      RecordTimerSessionParams(session: active, now: params.now),
    );
    return const Right(unit); // o claim já limpou o cronômetro
  }
}
