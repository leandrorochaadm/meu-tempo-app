---
paths:
  - "lib/features/*/data/**"
---

# Data Layer Rules (Firebase / Cloud Firestore)

## DataSources

- Classe abstrata + implementação (`{Feature}RemoteDataSource` / `Impl`).
- **MUST** retornar Models (fortemente tipados), NUNCA `Map<String, dynamic>`.
- **MUST** envolver chamadas ao Firestore em try/catch e **relançar** exceptions
  de `lib/core/error/exceptions.dart` (ver mapeamento abaixo).
- Recebe o `FirebaseFirestore` (e o `uid` do usuário) por injeção — nunca usa
  `FirebaseFirestore.instance` direto (testabilidade).
- **Isolamento por usuário:** toda coleção é raiz `users/{uid}/...` (ver `firebase.md`).

```dart
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final FirebaseFirestore _firestore;
  TaskRemoteDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      _firestore.collection('users').doc(uid).collection('tasks');

  @override
  Future<List<TaskModel>> getTasks(String uid) async {
    try {
      final snap = await _tasks(uid).get();
      return snap.docs.map((d) => TaskModel.fromDoc(d.id, d.data())).toList();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);   // → AppException (ServerException, PermissionException, ...)
    }
  }
}
```

## Models

- **MUST NOT** extends Entity — são classes **separadas**.
- **MUST** ter `toEntity()` e `fromEntity()` (quando precisar gravar).
- **MUST** usar `json_serializable`: anotar com `@JsonSerializable(includeIfNull: false)`,
  `part '{model}.g.dart'`, e expor `fromJson`/`toJson` gerados (`_$...FromJson`/`_$...ToJson`).
- **MUST** ter o factory `fromDoc(String id, Map<String, dynamic> data)` que injeta o
  `doc.id` no mapa antes do `fromJson` (o id vem do doc, não do corpo do documento).
- **MUST** anotar o campo `id` com `@JsonKey(includeToJson: false)` — lido do doc, nunca gravado.
- **MUST NOT** ter `copyWith()`.
- Datas: usar o `TimestampConverter` central (`lib/core/utils/timestamp_converter.dart`)
  via `@TimestampConverter()` no campo `DateTime?` — converte `Timestamp` ↔ `DateTime`.
  Como o mapa vem cru do Firestore (com objetos `Timestamp`), o converter recebe/gera
  `Timestamp` e o `toJson` pode ser gravado direto no Firestore.

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
  final int importance;
  final int estimatedMinutes;
  @TimestampConverter()
  final DateTime? dueDate;
  final String? parentId;

  TaskModel({
    required this.id,
    required this.title,
    required this.importance,
    required this.estimatedMinutes,
    this.dueDate,
    this.parentId,
  });

  // Firestore doc -> Model (injeta o doc.id no mapa que já traz objetos Timestamp)
  factory TaskModel.fromDoc(String id, Map<String, dynamic> data) =>
      TaskModel.fromJson({...data, 'id': id});

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);   // grava direto no Firestore

  TaskEntity toEntity() => TaskEntity(
        id: id, title: title, importance: importance,
        estimatedMinutes: estimatedMinutes, dueDate: dueDate,
      );

  factory TaskModel.fromEntity(TaskEntity e) => TaskModel(
        id: e.id, title: e.title, importance: e.importance,
        estimatedMinutes: e.estimatedMinutes, dueDate: e.dueDate,
      );
}
```

**Converter central** (`lib/core/utils/timestamp_converter.dart`):
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

class TimestampConverter implements JsonConverter<DateTime?, Timestamp?> {
  const TimestampConverter();
  @override
  DateTime? fromJson(Timestamp? ts) => ts?.toDate();
  @override
  Timestamp? toJson(DateTime? date) => date == null ? null : Timestamp.fromDate(date);
}
```

## Repositories (impl)

- Assinatura: `class TaskRepositoryImpl implements TaskRepository`.
- Retornar `Either<Failure, T>` (**fpdart**) — nunca `Either<Failure, Model>`.
- **MUST** converter Model → Entity (`model.toEntity()`) antes de retornar.
- try/catch → mapeia Exception (do DataSource) para Failure e retorna `Left`.

```dart
@override
Future<Either<Failure, List<TaskEntity>>> getTasks(String uid) async {
  try {
    final models = await _dataSource.getTasks(uid);
    return Right(models.map((m) => m.toEntity()).toList());
  } on AppException catch (e) {
    return Left(e.toFailure());
  }
}
```

### Return types permitidos
`Either<Failure, Entity>` / `List<Entity>` / `void` / `bool` / `String` / `int`.
**NEVER** `Either<Failure, Model>` ou `Either<Failure, Map>`.

## Exception → Failure mapping

Exceptions vivem em `lib/core/error/exceptions.dart`; o mapeamento (via helper ou
`toFailure()`) converte para Failures de `lib/core/error/failures.dart`:

| Origem (FirebaseException.code / exception) | Failure |
|---|---|
| `permission-denied` | `PermissionDeniedFailure` |
| `unavailable` / rede | `NetworkFailure` |
| `not-found` | `NotFoundFailure` |
| `unauthenticated` | `UnauthenticatedFailure` |
| qualquer outra | `ServerFailure` (fallback) |

## Coleções e caminhos

- **NUNCA** hardcodar strings de coleção espalhadas. Centralizar em
  `lib/core/constants/firestore_paths.dart` (ex.: `FirestorePaths.tasks(uid)`).

## Templates
- Model: `@.claude/rules/templates/model_template.md`
- DataSource: `@.claude/rules/templates/datasource_template.md`
- Repository: `@.claude/rules/templates/repository_template.md`
