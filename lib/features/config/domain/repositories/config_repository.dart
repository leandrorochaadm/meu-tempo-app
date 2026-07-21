import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/day_config_entity.dart';

abstract class ConfigRepository {
  Stream<Either<Failure, DayConfigEntity>> watchConfig();

  /// Leitura pontual da configuração (usada no primeiro acesso).
  Future<Either<Failure, DayConfigEntity>> getConfig();

  Future<Either<Failure, Unit>> setAvailableMinutes(int minutes);

  /// Marca o primeiro acesso como concluído.
  Future<Either<Failure, Unit>> markOnboarded();
}
