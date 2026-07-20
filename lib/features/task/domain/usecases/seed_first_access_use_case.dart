import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../config/domain/repositories/config_repository.dart';
import '../entities/importance_enum.dart';
import 'create_task_use_case.dart';

class SeedFirstAccessParams extends Equatable {
  const SeedFirstAccessParams({required this.today, required this.inboxListId});

  final DateTime today;
  final String inboxListId;

  @override
  List<Object?> get props => [today, inboxListId];
}

/// No primeiro acesso do usuário (config ainda não `onboarded`), cria uma
/// tarefa-exemplo na "Entrada" e marca o onboarding como concluído. Idempotente:
/// se já `onboarded`, não faz nada.
@lazySingleton
class SeedFirstAccessUseCase implements UseCase<Unit, SeedFirstAccessParams> {
  const SeedFirstAccessUseCase(this._configRepository, this._createTask);

  final ConfigRepository _configRepository;
  final CreateTaskUseCase _createTask;

  @override
  Future<Either<Failure, Unit>> call(SeedFirstAccessParams params) async {
    final configResult = await _configRepository.getConfig();
    final failure = configResult.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final config = configResult.getRight().toNullable();
    if (config == null || config.onboarded) return const Right(unit);

    final created = await _createTask(CreateTaskParams(
      title: 'Bem-vindo! Toque no ▶ para cronometrar esta tarefa',
      listId: params.inboxListId,
      today: params.today,
      estimatedMinutes: 30,
      dueDate: params.today,
      importance: ImportanceEnum.low,
    ));
    final createFailure = created.getLeft().toNullable();
    if (createFailure != null) return Left(createFailure);

    return _configRepository.markOnboarded();
  }
}
