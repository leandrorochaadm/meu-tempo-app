---
paths:
  - "lib/features/*/data/repositories/**"
---

# Repository Template

## Contrato (domain/repositories/)

```dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';

abstract interface class TaskRepository {
  Future<Either<Failure, List<TaskEntity>>> getTasks();
  Future<Either<Failure, String>> createTask(TaskEntity task);
  Future<Either<Failure, void>> deleteTask(String taskId);
}
```

## Implementação (data/repositories/)

```dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _dataSource;
  final AuthRepository _auth; // fornece o uid do usuário logado
  TaskRepositoryImpl(this._dataSource, this._auth);

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasks() async {
    try {
      final uid = _auth.currentUid;
      final models = await _dataSource.getTasks(uid);
      return Right(models.map((m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, String>> createTask(TaskEntity task) async {
    try {
      final uid = _auth.currentUid;
      final id = await _dataSource.createTask(uid, TaskModel.fromEntity(task));
      return Right(id);
    } on AppException catch (e) {
      return Left(e.toFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String taskId) async {
    try {
      await _dataSource.deleteTask(_auth.currentUid, taskId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(e.toFailure());
    }
  }
}
```

## Rules
- Retorna `Either<Failure, Entity>` — NUNCA `Either<Failure, Model>`.
- Converte Model → Entity (`toEntity()`) antes de retornar.
- try/catch → `Left(Failure)`; logar `error`+`stackTrace` antes (ver `logging.md`).
- Fornece o `uid` ao DataSource (via `AuthRepository`).
