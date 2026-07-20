import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../models/task_list_model.dart';
import '../task_list_fields.dart';

abstract class TaskListRemoteDataSource {
  Stream<List<TaskListModel>> watchLists();
  Future<List<TaskListModel>> getLists();
  Future<TaskListModel> create(TaskListModel list);
  Future<void> rename(String listId, String name);
  Future<void> delete(String listId);
}

@LazySingleton(as: TaskListRemoteDataSource)
class TaskListRemoteDataSourceImpl implements TaskListRemoteDataSource {
  TaskListRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const UnauthenticatedException();
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.lists(_uid));

  @override
  Stream<List<TaskListModel>> watchLists() {
    try {
      return _collection.orderBy(TaskListFields.name).snapshots().map(
            (snap) => snap.docs
                .map((d) => TaskListModel.fromDoc(d.id, d.data()))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<List<TaskListModel>> getLists() async {
    try {
      final snap = await _collection.get();
      return snap.docs
          .map((d) => TaskListModel.fromDoc(d.id, d.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<TaskListModel> create(TaskListModel list) async {
    try {
      final ref = await _collection.add(list.toJson());
      final doc = await ref.get();
      return TaskListModel.fromDoc(doc.id, doc.data()!);
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> rename(String listId, String name) async {
    try {
      await _collection.doc(listId).update({TaskListFields.name: name});
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> delete(String listId) async {
    try {
      await _collection.doc(listId).delete();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }
}
