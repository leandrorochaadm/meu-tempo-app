import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/day_config_entity.dart';
import '../repositories/config_repository.dart';

@lazySingleton
class WatchConfigUseCase
    implements StreamUseCase<Either<Failure, DayConfigEntity>, NoParams> {
  const WatchConfigUseCase(this._repository);

  final ConfigRepository _repository;

  @override
  Stream<Either<Failure, DayConfigEntity>> call(NoParams params) =>
      _repository.watchConfig();
}
