import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../models/task_model.dart';
import '../task_fields.dart';

abstract class TaskRemoteDataSource {
  /// Fluxo das tarefas. `includeDone == false` filtra as concluídas já na query
  /// (menos leitura/banda no caso comum) — usa o índice composto
  /// `isDone + createdAt` (ver `firestore.indexes.json`).
  Stream<List<TaskModel>> watchTasks({required bool includeDone});
  Future<TaskModel> create(TaskModel task);

  /// Cria a filha **e** marca o pai como não-folha num único `WriteBatch` —
  /// nunca deixa o pai com `hasChildren` desatualizado (ver `firebase.md`).
  Future<TaskModel> createChild(TaskModel child, {required String parentId});

  /// Grava a **subárvore movida** (a tarefa e seus descendentes, que herdam a
  /// lista do novo pai) e ajusta o `hasChildren` dos pais envolvidos no mesmo
  /// `WriteBatch`. [newParentId] recebe `true`; [emptiedParentId] (pai antigo
  /// que ficou sem filhas) recebe `false`.
  Future<void> moveTask(
    List<TaskModel> subtree, {
    String? newParentId,
    String? emptiedParentId,
  });

  /// Grava várias tarefas num único `WriteBatch` — usado quando editar uma
  /// tarefa mãe precisa propagar a lista para as filhas/netas.
  Future<void> updateAll(List<TaskModel> tasks);

  /// Remove a subárvore inteira e, no mesmo `WriteBatch`, marca
  /// [emptiedParentId] como folha quando o pai ficou sem filhas.
  Future<void> deleteSubtree(
    List<String> taskIds, {
    String? emptiedParentId,
  });

  /// Recria a subárvore (ids originais) e remarca [parentId] como não-folha no
  /// mesmo `WriteBatch` — desfazer de uma exclusão em cascata.
  Future<void> restoreSubtree(List<TaskModel> tasks, {String? parentId});
  Future<void> addSpentMinutes(String taskId, int delta);
  Future<List<TaskModel>> getTasks();
  Future<void> setDone(String taskId, bool value);
  Future<void> update(TaskModel task);
  Future<void> delete(String taskId);
}

@LazySingleton(as: TaskRemoteDataSource)
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const UnauthenticatedException();
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.tasks(_uid));

  @override
  Stream<List<TaskModel>> watchTasks({required bool includeDone}) {
    try {
      Query<Map<String, dynamic>> query = _collection;
      if (!includeDone) {
        query = query.where(TaskFields.isDone, isEqualTo: false);
      }
      return query
          .orderBy(TaskFields.createdAt, descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => TaskModel.fromDoc(d.id, d.data()))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<TaskModel> create(TaskModel task) async {
    try {
      final ref = await _collection.add(task.toJson());
      final doc = await ref.get();
      return TaskModel.fromDoc(doc.id, doc.data()!);
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<TaskModel> createChild(
    TaskModel child, {
    required String parentId,
  }) async {
    try {
      final ref = _collection.doc(); // id gerado localmente, sem ida ao servidor
      final batch = _firestore.batch()
        ..set(ref, child.toJson())
        ..update(_collection.doc(parentId), {TaskFields.hasChildren: true});
      await batch.commit();
      final doc = await ref.get();
      return TaskModel.fromDoc(doc.id, doc.data()!);
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> updateAll(List<TaskModel> tasks) async {
    try {
      final batch = _firestore.batch();
      for (final task in tasks) {
        batch.set(_collection.doc(task.id), task.toJson());
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> moveTask(
    List<TaskModel> subtree, {
    String? newParentId,
    String? emptiedParentId,
  }) async {
    try {
      final batch = _firestore.batch();
      for (final task in subtree) {
        batch.set(_collection.doc(task.id), task.toJson());
      }
      if (newParentId != null) {
        batch.update(
          _collection.doc(newParentId),
          {TaskFields.hasChildren: true},
        );
      }
      if (emptiedParentId != null) {
        batch.update(
          _collection.doc(emptiedParentId),
          {TaskFields.hasChildren: false},
        );
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> deleteSubtree(
    List<String> taskIds, {
    String? emptiedParentId,
  }) async {
    try {
      final batch = _firestore.batch();
      for (final id in taskIds) {
        batch.delete(_collection.doc(id));
      }
      if (emptiedParentId != null) {
        batch.update(
          _collection.doc(emptiedParentId),
          {TaskFields.hasChildren: false},
        );
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> restoreSubtree(
    List<TaskModel> tasks, {
    String? parentId,
  }) async {
    try {
      final batch = _firestore.batch();
      for (final task in tasks) {
        batch.set(_collection.doc(task.id), task.toJson());
      }
      if (parentId != null) {
        batch.update(
          _collection.doc(parentId),
          {TaskFields.hasChildren: true},
        );
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> addSpentMinutes(String taskId, int delta) async {
    try {
      await _collection.doc(taskId).update({
        TaskFields.spentMinutes: FieldValue.increment(delta),
      });
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<List<TaskModel>> getTasks() async {
    try {
      final snap = await _collection.get();
      return snap.docs.map((d) => TaskModel.fromDoc(d.id, d.data())).toList();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> setDone(String taskId, bool value) async {
    try {
      await _collection.doc(taskId).update({TaskFields.isDone: value});
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> update(TaskModel task) async {
    try {
      await _collection.doc(task.id).set(task.toJson());
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> delete(String taskId) async {
    try {
      await _collection.doc(taskId).delete();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }
}
