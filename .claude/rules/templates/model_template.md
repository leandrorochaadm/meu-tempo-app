---
paths:
  - "lib/features/*/data/models/**"
---

# Model Template (Firestore — conversão manual, sem json_serializable)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task_entity.dart';

class TaskModel {
  final String id;
  final String title;
  final DateTime? dueDate;

  TaskModel({required this.id, required this.title, this.dueDate});

  // Firestore -> Model (id vem do doc, não do corpo)
  factory TaskModel.fromMap(String id, Map<String, dynamic> data) => TaskModel(
        id: id,
        title: data['title'] as String,
        dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      );

  // Model -> Firestore (não gravar o id no corpo; omitir nulos)
  Map<String, dynamic> toMap() => {
        'title': title,
        if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      };

  // Model <-> Entity (ponte entre camadas)
  TaskEntity toEntity() => TaskEntity(id: id, title: title, dueDate: dueDate);

  factory TaskModel.fromEntity(TaskEntity e) =>
      TaskModel(id: e.id, title: e.title, dueDate: e.dueDate);
}
```

## Rules
- NUNCA `extends {Feature}Entity` — classes separadas.
- SEM `copyWith()`.
- `fromMap(id, data)` + `toMap()` (Timestamp ↔ DateTime; omitir campos nulos com `if`).
- `toEntity()` sempre; `fromEntity()` quando precisar gravar.
- O `id` do documento fica fora do corpo do doc.
