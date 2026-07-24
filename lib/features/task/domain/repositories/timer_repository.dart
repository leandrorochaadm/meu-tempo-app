import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/active_timer_entity.dart';

/// Contrato do cronômetro ativo (no máximo 1 por usuário).
abstract class TimerRepository {
  /// Fluxo do cronômetro ativo (`null` = nenhum rodando).
  Stream<Either<Failure, ActiveTimerEntity?>> watchActive();

  /// Leitura pontual do cronômetro ativo.
  Future<Either<Failure, ActiveTimerEntity?>> getActive();

  /// Define/atualiza o cronômetro ativo.
  Future<Either<Failure, Unit>> setActive(ActiveTimerEntity timer);

  /// Reivindica (lê **e** limpa, de forma atômica) o cronômetro ativo, retornando
  /// o que estava rodando — ou `null` se já não havia nenhum. Garante que, entre
  /// chamadas concorrentes (ex.: vários toques no "Parar"), apenas **uma** vença:
  /// as demais recebem `null`. É a base da **idempotência** ao parar — só quem
  /// vence o claim registra o tempo, evitando durações repetidas.
  Future<Either<Failure, ActiveTimerEntity?>> claimActive();

  /// Limpa o cronômetro ativo.
  Future<Either<Failure, Unit>> clear();
}
