---
paths:
  - "lib/features/*/data/models/**"
---

# Model Template (PocketBase — json_serializable + conversores de data)

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/utils/calendar_date_codec.dart';
import '../../../../core/utils/instant_codec.dart';
import '../../domain/entities/task_entity.dart';

part 'task_model.g.dart';

@JsonSerializable(includeIfNull: true, fieldRename: FieldRename.snake)
class TaskModel {
  TaskModel({required this.id, required this.title, this.createdAt, this.dueDate});

  @JsonKey(includeToJson: false)   // id vem do record.id, não é gravado no corpo
  final String id;
  final String title;
  @InstantConverter()
  final DateTime? createdAt;
  @CalendarDateConverter()
  final DateTime? dueDate;

  // RecordModel -> Model (injeta o record.id no mapa)
  factory TaskModel.fromRecord(RecordModel record) =>
      TaskModel.fromJson({...record.data, PbFields.id: record.id});

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);   // sem id e sem user

  // Model <-> Entity (ponte entre camadas)
  TaskEntity toEntity() => TaskEntity(
        id: id, title: title,
        createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0), dueDate: dueDate,
      );

  factory TaskModel.fromEntity(TaskEntity e) => TaskModel(
        id: e.id, title: e.title, createdAt: e.createdAt, dueDate: e.dueDate,
      );
}
```

## Rules
- NUNCA `extends {Feature}Entity` — classes separadas.
- SEM `copyWith()`.
- `@JsonSerializable(includeIfNull: true, fieldRename: FieldRename.snake)` + `part '{model}.g.dart'`;
  `fromJson`/`toJson` gerados (`null` limpa o campo no `update`).
- `fromRecord(RecordModel record)` injeta o `record.id` no mapa antes do `fromJson`.
- Campo `id` com `@JsonKey(includeToJson: false)` — lido do registro, nunca gravado no corpo.
- `toJson()` sem `id` e sem `user` (o DataSource acrescenta `PbFields.user` no `create`).
- Datas: `@InstantConverter()` (instante) ou `@CalendarDateConverter()` (dia) no campo `DateTime?`
  (`lib/core/utils/`).
- Enum externo fica cru (`String?`) e vira enum no `toEntity()` por `fromApi`.
- `toEntity()` sempre; `fromEntity()` quando precisar gravar.
- Rodar `dart run build_runner build --delete-conflicting-outputs` após criar/alterar o Model.
