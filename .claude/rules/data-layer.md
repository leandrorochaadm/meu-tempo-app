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
      return snap.docs.map((d) => TaskModel.fromMap(d.id, d.data())).toList();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);   // → AppException (ServerException, PermissionException, ...)
    }
  }
}
```

## Models

- **MUST NOT** extends Entity — são classes **separadas**.
- **MUST** ter `toEntity()` e `fromEntity()` (quando precisar gravar).
- **MUST** ter `fromMap(String id, Map<String, dynamic> data)` e `Map<String, dynamic> toMap()`
  para o Firestore. **Sem `json_serializable`** — a conversão é manual e explícita
  (o mapa do Firestore já é `Map<String, dynamic>`).
- **MUST NOT** ter `copyWith()`.
- Datas: gravar como `Timestamp` no Firestore e converter para `DateTime` no `fromMap`.
- Não gravar o `id` dentro do documento — o id é o id do doc (`doc.id`).

```dart
class TaskModel {
  final String id;
  final String title;
  final int importance;
  final int estimatedMinutes;
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

  factory TaskModel.fromMap(String id, Map<String, dynamic> data) => TaskModel(
        id: id,
        title: data['title'] as String,
        importance: data['importance'] as int,
        estimatedMinutes: data['estimatedMinutes'] as int,
        dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
        parentId: data['parentId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'importance': importance,
        'estimatedMinutes': estimatedMinutes,
        if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
        if (parentId != null) 'parentId': parentId,
      };

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
