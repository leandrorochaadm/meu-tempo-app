---
paths:
  - "lib/features/*/presentation/bloc/**"
---

# Event Template (sealed)

Arquivo: `{feature}_event.dart`. Um event por intenção do usuário (verbo no passado).

```dart
import 'package:equatable/equatable.dart';

sealed class TaskListEvent extends Equatable {
  const TaskListEvent();
  @override
  List<Object?> get props => [];
}

// Sem campos — herda props da base
class TaskListStarted extends TaskListEvent {
  const TaskListStarted();
}

// Com campos — sobrescreve props
class TaskCreated extends TaskListEvent {
  final String title;
  const TaskCreated(this.title);
  @override
  List<Object?> get props => [title];
}

class TaskDeleted extends TaskListEvent {
  final String taskId;
  const TaskDeleted(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

// Evento interno (ex.: atualização vinda de stream do Firestore) — prefixo _
class _TasksUpdated extends TaskListEvent {
  final List<TaskEntity> tasks;
  const _TasksUpdated(this.tasks);
  @override
  List<Object?> get props => [tasks];
}
```

## Rules
- base `sealed` + `Equatable`; sem campos herda `props`, com campos sobrescreve.
- eventos internos (originados de stream/timer) com prefixo `_`.
