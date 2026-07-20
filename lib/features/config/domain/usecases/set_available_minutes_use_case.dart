import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/config_repository.dart';

class SetAvailableMinutesParams extends Equatable {
  const SetAvailableMinutesParams(this.minutes);
  final int minutes;

  @override
  List<Object?> get props => [minutes];
}

@lazySingleton
class SetAvailableMinutesUseCase
    implements UseCase<Unit, SetAvailableMinutesParams> {
  const SetAvailableMinutesUseCase(this._repository);

  final ConfigRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SetAvailableMinutesParams params) {
    final minutes = params.minutes <= 0 ? 1 : params.minutes;
    return _repository.setAvailableMinutes(minutes);
  }
}
