import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

/// Fluxo das tarefas do usuário. Por padrão traz **todas** (relatório, migração);
/// a tela principal passa `includeDone: false` para ocultar as concluídas já na
/// consulta ao backend.
@lazySingleton
class WatchTasksUseCase
    implements StreamUseCase<Either<Failure, List<TaskEntity>>, WatchTasksParams> {
  const WatchTasksUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Stream<Either<Failure, List<TaskEntity>>> call(WatchTasksParams params) =>
      _repository.watchTasks(includeDone: params.includeDone);
}

class WatchTasksParams extends Equatable {
  const WatchTasksParams({this.includeDone = true});

  /// `false` = só as pendentes (filtro no backend). Padrão `true` = todas.
  final bool includeDone;

  @override
  List<Object?> get props => [includeDone];
}
