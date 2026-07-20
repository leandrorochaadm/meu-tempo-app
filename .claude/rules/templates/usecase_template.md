---
paths:
  - "lib/features/*/domain/usecases/**"
---

# UseCase Template

Nome: **verbo + substantivo + sufixo `UseCase`** (ex.: `StartTimerUseCase`).

## Com parâmetros

```dart
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTaskByIdUseCase implements UseCase<TaskEntity, GetTaskByIdParams> {
  final TaskRepository _repository;
  GetTaskByIdUseCase(this._repository);

  @override
  Future<Either<Failure, TaskEntity>> call(GetTaskByIdParams params) {
    return _repository.getTaskById(params.id);
  }
}

class GetTaskByIdParams extends Equatable {
  final String id;
  const GetTaskByIdParams({required this.id});

  @override
  List<Object> get props => [id];
}
```

## Sem parâmetros

```dart
class GetTasksUseCase implements UseCase<List<TaskEntity>, NoParams> {
  final TaskRepository _repository;
  GetTasksUseCase(this._repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call(NoParams params) {
    return _repository.getTasks();
  }
}
```

## Com orquestração + regra de negócio (fold do Either)

```dart
class StartTimerUseCase implements UseCase<void, StartTimerParams> {
  final TimerRepository _repository;
  StartTimerUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(StartTimerParams params) async {
    // regra de negócio: pausar o cronômetro ativo antes de iniciar outro
    final active = await _repository.getActiveTimer();
    return active.fold(
      (failure) => Left(failure),
      (current) async {
        if (current != null) await _repository.pauseTimer(current.id);
        return _repository.startTimer(params.taskId);
      },
    );
  }
}
```

## Contrato base `lib/core/usecase/usecase.dart`

```dart
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';

abstract interface class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
```

## Rules
- implementa `UseCase<T, Params>` e `call()` (NÃO `execute()`).
- retorna `Either<Failure, T>` (fpdart); `NoParams` quando não há parâmetro.
- `Params` extends `Equatable`.
- NUNCA mensagem de texto — retorna `Failure` com dados.
