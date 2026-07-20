import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/day_config_entity.dart';

abstract class ConfigRepository {
  Stream<Either<Failure, DayConfigEntity>> watchConfig();
  Future<Either<Failure, Unit>> setAvailableMinutes(int minutes);
}
