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

  /// Limpa o cronômetro ativo.
  Future<Either<Failure, Unit>> clear();
}
