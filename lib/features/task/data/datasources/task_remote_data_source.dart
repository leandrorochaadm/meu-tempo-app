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
  Future<void> setHasChildren(String taskId, bool value);
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
  Future<void> setHasChildren(String taskId, bool value) async {
    try {
      await _collection.doc(taskId).update({TaskFields.hasChildren: value});
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
