---
paths:
  - "lib/features/*/data/**"
---

# Data Layer Rules (PocketBase)

## DataSources

- Classe abstrata + implementação (`{Feature}RemoteDataSource` / `Impl`).
- **MUST** retornar Models (fortemente tipados), NUNCA `Map<String, dynamic>`.
- **MUST** envolver chamadas ao PocketBase em try/catch (`on ClientException`) e **relançar**
  exceptions de `lib/core/error/exceptions.dart` via `mapPocketBaseError` (ver mapeamento abaixo).
- Recebe `PocketBaseSession` (e `RecordWatcher` quando tem `watch*`) por injeção — nunca cria
  o cliente nem lê o armazenamento (testabilidade).
- **Isolamento por usuário:** coleções planas com campo `user`, garantido pelas API Rules
  (ver `pocketbase.md`).

```dart
@LazySingleton(as: TaskRemoteDataSource)
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl(this._session, this._watcher);

  final PocketBaseSession _session;
  final RecordWatcher _watcher;

  RecordService get _records => _session.client.collection(PbCollections.tasks);

  @override
  Future<List<TaskModel>> getTasks() async {
    _session.userId;
    try {
      final records = await _records.getFullList(sort: '-${PbFields.createdAt}');
      return records.map(TaskModel.fromRecord).toList();
    } on ClientException catch (e) {
      throw mapPocketBaseError(e);   // → AppException (ServerException, PermissionException, ...)
    }
  }
}
```

## Models

- **MUST NOT** extends Entity — são classes **separadas**.
- **MUST** ter `toEntity()` e `fromEntity()` (quando precisar gravar).
- **MUST** usar `json_serializable`: `@JsonSerializable(includeIfNull: true, fieldRename: FieldRename.snake)`
  (`null` limpa o campo no `update`), `part '{model}.g.dart'`, e expor `fromJson`/`toJson` gerados.
- **MUST** ter o factory `fromRecord(RecordModel record)` que injeta o `record.id` no mapa
  antes do `fromJson` (o id vem do registro, não do corpo).
- **MUST** anotar o campo `id` com `@JsonKey(includeToJson: false)`; o `toJson()` sai sem `id`
  e sem `user` (o DataSource acrescenta `PbFields.user` no `create`).
- **MUST NOT** ter `copyWith()`.
- Enum externo fica **cru** (`String?`) no Model e é convertido no `toEntity()` por
  `Enum.fromApi(raw)`; valor desconhecido é decisão do model (`FormatException` ou padrão).
  Para isso, construtor `raw` usado pelo `json_serializable` (`constructor: 'raw'`).
- Datas: `@InstantConverter()` (instante) e `@CalendarDateConverter()` (dia) no campo
  `DateTime?` (`lib/core/utils/`).

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
  TaskModel({required this.id, required this.title, required this.createdAt, this.dueDate});

  @JsonKey(includeToJson: false)   // id vem do record.id, não é gravado no corpo
  final String id;
  final String title;
  @InstantConverter()
  final DateTime? createdAt;
  @CalendarDateConverter()
  final DateTime? dueDate;

  factory TaskModel.fromRecord(RecordModel record) =>
      TaskModel.fromJson({...record.data, PbFields.id: record.id});

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  TaskEntity toEntity() => TaskEntity(
        id: id, title: title,
        createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0), dueDate: dueDate,
      );

  factory TaskModel.fromEntity(TaskEntity e) => TaskModel(
        id: e.id, title: e.title, createdAt: e.createdAt, dueDate: e.dueDate,
      );
}
```

**Conversores centrais** (`lib/core/utils/instant_codec.dart`, `calendar_date_codec.dart`):
ambos implementam `JsonConverter<DateTime?, String?>`; `null` e `''` viram `null`, texto fora
do formato lança `FormatException`.

## Repositories (impl)

- Assinatura: `class TaskRepositoryImpl implements TaskRepository`.
- Retornar `Either<Failure, T>` (**fpdart**) — nunca `Either<Failure, Model>`.
- **MUST** converter Model → Entity (`model.toEntity()`) antes de retornar.
- try/catch → mapeia Exception (do DataSource) para Failure e retorna `Left`.

```dart
@override
Future<Either<Failure, List<TaskEntity>>> getTasks() async {
  try {
    final models = await _dataSource.getTasks();
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

Exceptions vivem em `lib/core/error/exceptions.dart`; `mapPocketBaseError`
(`lib/core/error/pocketbase_error_mapper.dart`) converte o `ClientException` e o `toFailure()`
da exception entrega a Failure de `lib/core/error/failures.dart`:

| Origem (`ClientException.statusCode`) | Exception | Failure |
|---|---|---|
| 0 (sem conexão) | `NetworkException` | `NetworkFailure` |
| 401 / 403 | `PermissionException` | `PermissionDeniedFailure` |
| 404 | `NotFoundException` | `NotFoundFailure` |
| 400 `validation_not_unique` | `ConflictException` | `ServerFailure` (quem trata a disputa captura antes) |
| 429 / 5xx / outro 400 | `ServerException` | `ServerFailure` |
| sem sessão (`session.userId`) | `UnauthenticatedException` | `UnauthenticatedFailure` |

Erro de lote vem embrulhado: o mapper desembrulha `data.requests.<i>.response` e traduz o
status do pedido que falhou.

## Coleções e campos

- **NUNCA** hardcodar strings de coleção ou campo. Usar `PbCollections`/`PbFields` em
  `lib/core/constants/pb_schema.dart`.

## Templates
- Model: `@.claude/rules/templates/model_template.md`
- DataSource: `@.claude/rules/templates/datasource_template.md`
- Repository: `@.claude/rules/templates/repository_template.md`
