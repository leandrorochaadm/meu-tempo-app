---
paths:
  - "lib/features/*/data/models/**"
---

# Model Template (Firestore — json_serializable + TimestampConverter)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/task_entity.dart';

part 'task_model.g.dart';

@JsonSerializable(includeIfNull: false)
class TaskModel {
  @JsonKey(includeToJson: false)   // id vem do doc.id, não é gravado no corpo
  final String id;
  final String title;
  @TimestampConverter()
  final DateTime? dueDate;

  TaskModel({required this.id, required this.title, this.dueDate});

  // Firestore doc -> Model (injeta o doc.id; o mapa já traz objetos Timestamp)
  factory TaskModel.fromDoc(String id, Map<String, dynamic> data) =>
      TaskModel.fromJson({...data, 'id': id});

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);   // grava direto no Firestore

  // Model <-> Entity (ponte entre camadas)
  TaskEntity toEntity() => TaskEntity(id: id, title: title, dueDate: dueDate);

  factory TaskModel.fromEntity(TaskEntity e) =>
      TaskModel(id: e.id, title: e.title, dueDate: e.dueDate);
}
```

## Rules
- NUNCA `extends {Feature}Entity` — classes separadas.
- SEM `copyWith()`.
- `@JsonSerializable(includeIfNull: false)` + `part '{model}.g.dart'`; `fromJson`/`toJson` gerados.
- `fromDoc(id, data)` injeta o `doc.id` no mapa antes do `fromJson`.
- Campo `id` com `@JsonKey(includeToJson: false)` — lido do doc, nunca gravado no corpo.
- Datas: `@TimestampConverter()` no campo `DateTime?` (`lib/core/utils/timestamp_converter.dart`).
- `toEntity()` sempre; `fromEntity()` quando precisar gravar.
- Rodar `dart run build_runner build --delete-conflicting-outputs` após criar/alterar o Model.
```
