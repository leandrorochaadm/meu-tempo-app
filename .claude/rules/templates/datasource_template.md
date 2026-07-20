---
paths:
  - "lib/features/*/data/datasources/**"
---

# DataSource Template (Cloud Firestore)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../models/task_model.dart';

abstract interface class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks(String uid);
  Future<String> createTask(String uid, TaskModel task);
  Future<void> deleteTask(String uid, String taskId);
}

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
      throw mapFirebaseException(e); // -> AppException (core/error/exceptions.dart)
    }
  }

  @override
  Future<String> createTask(String uid, TaskModel task) async {
    try {
      final ref = await _tasks(uid).add(task.toJson());
      return ref.id;
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<void> deleteTask(String uid, String taskId) async {
    try {
      await _tasks(uid).doc(taskId).delete();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }
}
```

## Rules
- Retorna Model (nunca `Map`).
- Recebe `FirebaseFirestore` por injeção (nunca `.instance` direto).
- Todo acesso sob `users/{uid}/...` (isolamento por usuário — ver `firebase.md`).
- try/catch em toda chamada; relançar `AppException` (o RepositoryImpl vira Failure).
- Centralizar caminhos de coleção (evitar strings soltas).
