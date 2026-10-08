import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../appointment/domain/usecases/set_appointment_done_use_case.dart';
import '../entities/timer_target_type_enum.dart';
import '../repositories/timer_repository.dart';
import 'complete_task_use_case.dart';
import 'record_timer_session_use_case.dart';

class FinishTimerParams extends Equatable {
  const FinishTimerParams({required this.targetId, required this.now});

  /// Alvo que quem pediu o "parar" estava vendo. Se o cronômetro ativo for
  /// outro (ex.: start dado em outro celular), o pedido vira no-op.
  final String targetId;
  final DateTime now;

  @override
  List<Object?> get props => [targetId, now];
}

/// "Parar" que conclui (tela bloqueada): interrompe o cronômetro de
/// [FinishTimerParams.targetId] — rodando ou pausado —, soma a sessão do que
/// estava rodando e dá o alvo por **concluído**: a folha via
/// [CompleteTaskUseCase] (mãe/avó concluem junto quando todas as filhas
/// estiverem feitas) ou o compromisso via [SetAppointmentDoneUseCase].
///
/// Idempotente: outro alvo ativo, sem cronômetro ou corrida perdida para outro
/// toque/celular → `Right(unit)` sem gravar nada. Diferente do
/// `StopTimerUseCase` (botão "Parar" do app), que só para e não conclui.
@lazySingleton
class FinishTimerUseCase implements UseCase<Unit, FinishTimerParams> {
  const FinishTimerUseCase(
    this._timerRepository,
    this._recordSession,
    this._completeTask,
    this._setAppointmentDone,
  );

  final TimerRepository _timerRepository;
  final RecordTimerSessionUseCase _recordSession;
  final CompleteTaskUseCase _completeTask;
  final SetAppointmentDoneUseCase _setAppointmentDone;

  @override
  Future<Either<Failure, Unit>> call(FinishTimerParams params) async {
    final current = await _timerRepository.getActive();
    final failure = current.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final active = current.getRight().toNullable();
    if (active == null || active.targetId != params.targetId) {
      return const Right(unit);
    }

    final cleared = await _timerRepository.clearActiveIfUnchanged(
      expected: active,
    );
    final clearFailure = cleared.getLeft().toNullable();
    if (clearFailure != null) return Left(clearFailure);
    // Outro toque/celular mudou o cronômetro antes: quem venceu já agiu.
    if (cleared.getRight().toNullable() != true) return const Right(unit);

    // Pausado não soma (elapsedMinutes = 0): a sessão entrou ao pausar.
    final recorded = await _recordSession(
      RecordTimerSessionParams(session: active, now: params.now),
    );
    // Conclui mesmo se o registro falhar: o cronômetro já foi limpo e o
    // pedido do usuário é concluir. A primeira falha é a devolvida.
    final completed = switch (active.targetType) {
      TimerTargetTypeEnum.task => await _completeTask(
        CompleteTaskParams(taskId: active.targetId, done: true),
      ),
      TimerTargetTypeEnum.appointment => await _setAppointmentDone(
        SetAppointmentDoneParams(appointmentId: active.targetId, done: true),
      ),
    };
    return recorded.flatMap((_) => completed);
  }
}
