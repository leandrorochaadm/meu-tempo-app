import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/task_repository.dart';
import '../task_failures.dart';

class RegisterManualTimeParams extends Equatable {
  const RegisterManualTimeParams({
    required this.targetId,
    required this.targetIsLeaf,
    required this.minutes,
  });

  final String targetId;
  final bool targetIsLeaf;
  final int minutes;

  @override
  List<Object?> get props => [targetId, targetIsLeaf, minutes];
}

/// Registra tempo manualmente numa folha (ex.: atalhos +15/+30 min).
@lazySingleton
class RegisterManualTimeUseCase
    implements UseCase<Unit, RegisterManualTimeParams> {
  const RegisterManualTimeUseCase(this._taskRepository);

  final TaskRepository _taskRepository;

  @override
  Future<Either<Failure, Unit>> call(RegisterManualTimeParams params) async {
    if (!params.targetIsLeaf) return const Left(TimerOnNonLeafFailure());
    if (params.minutes <= 0) return const Left(InvalidDurationFailure());
    return _taskRepository.addSpentMinutes(params.targetId, params.minutes);
  }
}
