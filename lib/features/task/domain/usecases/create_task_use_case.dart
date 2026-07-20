import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_defaults.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/importance_enum.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';
import '../task_failures.dart';

/// Parâmetros de criação. Na criação rápida, só `title`/`listId` são informados
/// e o resto recebe os defaults.
class CreateTaskParams extends Equatable {
  const CreateTaskParams({
    required this.title,
    required this.listId,
    required this.today,
    this.parentId,
    this.estimatedMinutes,
    this.dueDate,
    this.importance,
  });

  final String title;
  final String listId;

  /// "Hoje" injetado (mantém o UseCase testável, sem `DateTime.now()` interno).
  final DateTime today;

  final String? parentId;
  final int? estimatedMinutes;
  final DateTime? dueDate;
  final ImportanceEnum? importance;

  @override
  List<Object?> get props =>
      [title, listId, today, parentId, estimatedMinutes, dueDate, importance];
}

/// Cria uma tarefa aplicando os defaults da criação rápida quando não informados.
@lazySingleton
class CreateTaskUseCase implements UseCase<TaskEntity, CreateTaskParams> {
  const CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, TaskEntity>> call(CreateTaskParams params) async {
    final title = params.title.trim();
    if (title.isEmpty) return const Left(EmptyTitleFailure());

    final task = TaskEntity(
      id: '',
      title: title,
      listId: params.listId,
      createdAt: params.today,
      parentId: params.parentId,
      estimatedMinutes:
          params.estimatedMinutes ?? AppDefaults.defaultEstimatedMinutes,
      dueDate: params.dueDate ?? params.today,
      importance: params.importance ?? ImportanceEnum.min,
    );

    return _repository.create(task);
  }
}
